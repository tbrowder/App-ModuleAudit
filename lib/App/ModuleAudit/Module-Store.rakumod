use v6;

unit class App::ModuleAudit::Module-Store;

use App::ModuleAudit::DB;
use App::ModuleAudit::Module-Record;
use App::ModuleAudit::Scanner;

has Str:D $.db-path is required;

#method dbh(--> DBIish::Database:D) {
method dbh(--> Str:D) {
    state %cache;

    if %cache{$.db-path}:exists {
        return %cache{$.db-path};
    }

    my $dbh = connect-db($.db-path);
    init-schema($dbh);
    %cache{$.db-path} = $dbh;

    return $dbh;
}

method scan-installed(--> Array[App::ModuleAudit::Module-Record:D]) {
    return scan-installed-modules();
}

method save-scan(@modules --> Int:D) {
    my $dbh = self.dbh;
    my Str:D $timestamp = DateTime.now.Str;
    my Int:D $count = 0;

    for @modules -> $module {
        my Int:D $module-id = find-or-create-module-id(
            $dbh,
            $module.name,
            $module.auth,
            $module.api,
        );

        insert-installation(
            $dbh,
            $module-id,
            $module.ver,
            $module.dist,
            $module.source,
            $module.install-path,
            $timestamp,
            :installed($module.installed),
            :latest-known-ver($module.latest-known-ver),
            :upgrade-available($module.upgrade-available),
        );

        $count++;
    }

    return $count;
}

method scan-and-save(--> Int:D) {
    my @modules = self.scan-installed();
    return self.save-scan(@modules);
}

method load-installed(--> Array[App::ModuleAudit::Module-Record:D]) {
    my $dbh = self.dbh;
    my @rows = load-current-installations($dbh);
    my Array[App::ModuleAudit::Module-Record:D] @modules;

    for @rows -> %row {
        @modules.push(
            App::ModuleAudit::Module-Record.new(
                name              => %row<name>,
                auth              => %row<auth>,
                api               => %row<api>,
                ver               => %row<ver>,
                dist              => %row<dist>,
                source            => %row<source>,
                install-path      => %row<install-path>,
                installed         => %row<installed>,
                latest-known-ver  => %row<latest-known-ver>,
                upgrade-available => %row<upgrade-available>,
            )
        );
    }

    return @modules;
}

method check-upgrades(
    Int:D :$parallel = 4
    --> Array[App::ModuleAudit::Module-Record:D]
) {
    my @modules = self.load-installed();
    my @batch;

    for @modules -> $module {
        @batch.push(
            start {
                my Str $latest = self.lookup-latest-version($module);

                if $latest.defined and $latest.chars > 0 {
                    $module.mark-latest($latest);
                }

                return $module;
            }
        );

        if @batch.elems >= $parallel {
            await @batch;
            @batch = ();
        }
    }

    if @batch {
        await @batch;
    }

    return @modules;
}

method lookup-latest-version(
    App::ModuleAudit::Module-Record:D $module
    --> Str
) {
    my @cmd = <zef info>;
    @cmd.push($module.name);

    my $proc = run |@cmd, :out, :err;

    my Str:D $stdout = $proc.out.slurp-rest;
    my Str:D $stderr = $proc.err.slurp-rest;

    if $proc.exitcode != 0 {
        return Nil;
    }

    for $stdout.lines -> $line {
        my Str:D $t = $line.trim;

        if $t ~~ /^ 'Version:' \s* (.+) $/ {
            return ~$0;
        }
        elsif $t ~~ /^ 'ver<' (.+) '>' $/ {
            return ~$0;
        }
    }

    return Nil;
}

method remove-module(
    App::ModuleAudit::Module-Record:D $module,
    Bool:D :$dry-run = False
    --> Bool:D
) {
    my @cmd = <zef uninstall>;
    @cmd.push($module.name);

    if $dry-run {
        say @cmd.join(' ');
        return True;
    }

    my $proc = run |@cmd;
    return $proc.exitcode == 0;
}

method downgrade-module(
    App::ModuleAudit::Module-Record:D $module,
    Str:D :$target-ver!,
    Bool:D :$dry-run = False
    --> Bool:D
) {
    my @remove-cmd = <zef uninstall>;
    @remove-cmd.push($module.name);

    my @install-cmd = <zef install>;
    @install-cmd.push("{$module.name}:ver<{$target-ver}>");

    if $dry-run {
        say @remove-cmd.join(' ');
        say @install-cmd.join(' ');
        return True;
    }

    my $remove-proc = run |@remove-cmd;
    return False if $remove-proc.exitcode != 0;

    my $install-proc = run |@install-cmd;
    return $install-proc.exitcode == 0;
}
