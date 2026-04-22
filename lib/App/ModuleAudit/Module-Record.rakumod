use v6;

unit class App::ModuleAudit::Module-Record;

has Str:D $.name is required;
has Str $.auth is rw;
has Str $.api is rw;
has Str $.ver is rw;
has Str $.dist is rw;
has Str $.source is rw;
has Str $.install-path is rw;
has Bool:D $.installed is rw = True;

has Str $.latest-known-ver is rw;
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
