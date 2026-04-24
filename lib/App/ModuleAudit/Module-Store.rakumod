use v6;

unit class App::ModuleAudit::Module-Store;

use App::ModuleAudit::DB;
use App::ModuleAudit::Module-Record;
use App::ModuleAudit::Scanner;
use App::ModuleAudit::Upgrade-Checker;

has Str:D $.db-path is required;

#method dbh(--> DBIish::Database:D) {
method dbh() {
    state %cache;

    if %cache{$.db-path}:exists {
        return %cache{$.db-path};
    }

    my $dbh = connect-db($.db-path);
    init-schema($dbh);
    %cache{$.db-path} = $dbh;

    return $dbh;
}

method scan-installed(--> Array) {
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
            ($module.auth // ''),
            ($module.api // ''),
        );

        insert-installation(
            $dbh,
            $module-id,
            ($module.ver // ''),
            ($module.dist // ''),
            ($module.source // ''),
            ($module.install-path // ''),
            $timestamp,
            :installed($module.installed),
            :latest-known-ver(($module.latest-known-ver // '')),
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

method load-installed(--> Array) {
    my $dbh = self.dbh;
    my @rows = load-current-installations($dbh);
    my App::ModuleAudit::Module-Record:D @modules;
    my %seen-module-records;

    for @rows -> %row {
        my Str:D $identity-key = (%row<name> // '') ~ "\t"
            ~ (%row<auth> // '') ~ "\t"
            ~ (%row<api> // '');

        next if %seen-module-records{$identity-key}:exists;
        %seen-module-records{$identity-key} = True;

        @modules.push(
            App::ModuleAudit::Module-Record.new(
                name              => %row<name>,
                auth              => %row<auth> // '',
                api               => %row<api> // '',
                ver               => %row<ver> // '',
                dist              => %row<dist> // '',
                source            => %row<source> // '',
                install-path      => %row<install-path> // '',
                installed         => so %row<installed>,
                latest-known-ver  => %row<latest-known-ver> // '',
                upgrade-available => so %row<upgrade-available>,
            )
        );
    }

    return @modules.Array;
}

method check-upgrades(
    Int:D :$parallel = 4,
    Bool:D :$apply = False,
    Bool:D :$dry-run = False
    --> Array
) {
    my @modules = self.load-installed();
    my $checker = App::ModuleAudit::Upgrade-Checker.new(
        :$apply,
        :$dry-run,
    );

    return $checker.check(@modules, :$parallel);
}

method remove-module(
    App::ModuleAudit::Module-Record:D $module,
    Bool:D :$dry-run = False
    --> Bool:D
) {
    return $module.remove(:$dry-run);
}

method downgrade-module(
    App::ModuleAudit::Module-Record:D $module,
    Str:D :$target-ver!,
    Bool:D :$dry-run = False
    --> Bool:D
) {
    return $module.downgrade($target-ver, :$dry-run);
}
