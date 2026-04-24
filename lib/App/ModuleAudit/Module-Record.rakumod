use v6;

unit class App::ModuleAudit::Module-Record;


has Str:D $.name is required;
has Str $.auth is rw = '';
has Str $.api is rw = '';
has Str $.ver is rw = '';
has Str $.dist is rw = '';
has Str $.source is rw = '';
has Str $.install-path is rw = '';
has Bool:D $.installed is rw = True;

has Str $.latest-known-ver is rw = '';
has Bool:D $.upgrade-available is rw = False;

method identity-key(--> Str:D) {
    my Str:D $auth = $.auth // '';
    my Str:D $api = $.api // '';

    return "{$.name}\t{$auth}\t{$api}";
}

method full-identity-key(--> Str:D) {
    my Str:D $auth = $.auth // '';
    my Str:D $api = $.api // '';
    my Str:D $ver = $.ver // '';

    return "{$.name}\t{$auth}\t{$api}\t{$ver}";
}

method short-str(--> Str:D) {
    my Str:D $auth = $.auth // '*';
    my Str:D $api = $.api // '*';
    my Str:D $ver = $.ver // '*';

    return "{$.name} auth={$auth} api={$api} ver={$ver}";
}

method has-upgrade(--> Bool:D) {
    return $.upgrade-available;
}

method mark-latest(Str:D $latest-ver --> Nil) {
    $!latest-known-ver = $latest-ver;

    if $.ver.defined and $.ver.chars > 0 and $latest-ver ne $.ver {
        $!upgrade-available = True;
    }
    else {
        $!upgrade-available = False;
    }
}

method is-outdated(Str:D $latest-ver --> Bool:D) {
    return False if not $.ver.defined;
    return $.ver ne $latest-ver;
}

method command-result(*@cmd, :&runner --> Hash:D) {
    if &runner.defined {
        return runner(|@cmd);
    }

    my $proc = run |@cmd, :out, :err;

    return {
        exitcode => $proc.exitcode,
        out      => $proc.out.slurp-rest,
        err      => $proc.err.slurp-rest,
    };
}

method install-latest(:&runner, Bool:D :$dry-run = False --> Bool:D) {
    my @cmd = 'zef', 'install', $.name;

    if $dry-run {
        say @cmd.join(' ');
        return True;
    }

    my %result = self.command-result(|@cmd, :&runner);
    return %result<exitcode> == 0;
}

method remove(:&runner, Bool:D :$dry-run = False --> Bool:D) {
    my @cmd = 'zef', 'uninstall', $.name;

    if $dry-run {
        say @cmd.join(' ');
        return True;
    }

    my %result = self.command-result(|@cmd, :&runner);
    return %result<exitcode> == 0;
}

method downgrade(Str:D $target-ver, :&runner, Bool:D :$dry-run = False --> Bool:D) {
    my @remove-cmd = 'zef', 'uninstall', $.name;
    my @install-cmd = 'zef', 'install', "{$.name}:ver<{$target-ver}>";

    if $dry-run {
        say @remove-cmd.join(' ');
        say @install-cmd.join(' ');
        return True;
    }

    my %remove-result = self.command-result(|@remove-cmd, :&runner);
    return False if %remove-result<exitcode> != 0;

    my %install-result = self.command-result(|@install-cmd, :&runner);
    return %install-result<exitcode> == 0;
}

method as-hash(--> Hash:D) {
    return {
        name               => $.name,
        auth               => $.auth,
        api                => $.api,
        ver                => $.ver,
        dist               => $.dist,
        source             => $.source,
        install-path       => $.install-path,
        installed          => $.installed,
        latest-known-ver   => $.latest-known-ver,
        upgrade-available  => $.upgrade-available,
    };
}
