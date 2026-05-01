use v6;
use Test;

plan 10;

my Str:D $module-name = 'Dummy::Module';
my Str:D $auth = 'zef:test';
my Str:D $api = '1';
my Str:D $tmp-root = 't/tmp-prune-behavior';
my Str:D $db-path = 't/tmp-prune-behavior.db';

sub command-ok(
    *@cmd,
    Str:D :$message
    --> Bool:D
) {
    my $proc = run |@cmd, :out, :err;
    my Str:D $out = $proc.out.slurp-rest;
    my Str:D $err = $proc.err.slurp-rest;

    diag $out if $out.chars > 0;
    diag $err if $err.chars > 0;

    ok $proc.exitcode == 0, $message;

    return $proc.exitcode == 0;
}

sub zef-installed-output(--> Str:D) {
    my $proc = run 'zef', 'list', '--installed', :out, :err;
    my Str:D $out = $proc.out.slurp-rest;
    my Str:D $err = $proc.err.slurp-rest;

    diag $err if $err.chars > 0 and $proc.exitcode != 0;

    return $out;
}

sub installed-version-present(Str:D $version --> Bool:D) {
    my Str:D $installed = zef-installed-output();

    for $installed.lines -> $line {
        next unless $line.starts-with($module-name);

        return True if $line.contains(":ver<$version>");
        return True if $line.contains("($version)");
        return True if $line.contains($version);
    }

    return False;
}

sub make-test-module(Str:D $version --> Str:D) {
    my Str:D $dir = "$tmp-root/Dummy-Module-$version";
    my Str:D $lib-dir = "$dir/lib/Dummy";

    $lib-dir.IO.mkdir(:parents);

    my Str:D $meta = q:to/META/;
{
    "name": "__MODULE_NAME__",
    "version": "__VERSION__",
    "auth": "__AUTH__",
    "api": "__API__",
    "description": "Temporary module for App::ModuleAudit prune testing",
    "license": "Artistic-2.0",
    "provides": {
        "__MODULE_NAME__": "lib/Dummy/Module.rakumod"
    }
}
META

    $meta .= subst('__MODULE_NAME__', $module-name, :g);
    $meta .= subst('__VERSION__', $version, :g);
    $meta .= subst('__AUTH__', $auth, :g);
    $meta .= subst('__API__', $api, :g);

    spurt "$dir/META6.json", $meta;

    my Str:D $module-source = q:to/MOD/;
use v6;

unit module Dummy::Module;

sub dummy-version(--> Str:D) is export {
    return '__VERSION__';
}
MOD

    $module-source .= subst('__VERSION__', $version, :g);

    spurt "$dir/lib/Dummy/Module.rakumod", $module-source;

    return $dir.IO.absolute;
}

sub uninstall-dummy(--> Nil) {
    my Str:D $spec = "{$module-name}:auth<{$auth}>";
    my $proc = run 'zef', 'uninstall', $spec, :out, :err;
    $proc.out.slurp-rest;
    $proc.err.slurp-rest;
}

sub cleanup-test-files(--> Nil) {
    if $tmp-root.IO.e {
        run 'rm', '-rf', $tmp-root;
    }

    if $db-path.IO.e {
        $db-path.IO.unlink;
    }
}

END {
    uninstall-dummy();
    cleanup-test-files();
}

uninstall-dummy();
cleanup-test-files();

my Str:D $old-dir = make-test-module('0.0.1');
my Str:D $new-dir = make-test-module('0.0.2');

diag "old dummy dir: $old-dir";
diag "new dummy dir: $new-dir";

ok $old-dir.IO.e, 'created old dummy module tree';
ok "$old-dir/META6.json".IO.e, 'created old dummy META6 file';
ok $new-dir.IO.e, 'created new dummy module tree';

command-ok 'zef', 'install', $old-dir, :message('installed old dummy module');
command-ok 'zef', 'install', $new-dir, :message('installed new dummy module');

ok installed-version-present('0.0.1'), 'old version appears installed before prune';
ok installed-version-present('0.0.2'), 'new version appears installed before prune';

my $scan-proc = run 'raku', '-Ilib', 'bin/module-audit',
    "--db-path=$db-path",
    'scan',
    :out,
    :err;

diag $scan-proc.out.slurp-rest;
diag $scan-proc.err.slurp-rest if $scan-proc.exitcode != 0;

ok $scan-proc.exitcode == 0, 'scan completed before prune';

my $prune-proc = run 'raku', '-Ilib', 'bin/module-audit',
    "--db-path=$db-path",
    '--name=Dummy::Module',
    '--/dry-run',
    '--force',
    'prune-versions',
    :out,
    :err;

my Str:D $prune-out = $prune-proc.out.slurp-rest;
my Str:D $prune-err = $prune-proc.err.slurp-rest;

diag $prune-out if $prune-out.chars > 0;
diag $prune-err if $prune-err.chars > 0;

ok $prune-proc.exitcode == 0, 'prune command completed';

todo 'desired final behavior depends on local zef uninstall/version semantics', 1;
ok installed-version-present('0.0.2') && not installed-version-present('0.0.1'),
    'only latest dummy module version remains after prune';
