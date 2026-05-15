use v6.d;
unit module App::ModuleAudit::UpgradeChecker;

use JSON::Fast;

sub check-upgrades(
    Bool :$apply = False
    --> Int:D
) is export {

    my $proc = run(
        'zef',
        'outdated',
        '--json',
        :out,
        :err
    );

    my Str:D $json = $proc.out.slurp-rest;
    my @mods = from-json($json);

    say "Outdated modules found: " ~ @mods.elems;

    if $apply and @mods.elems > 0 {
        run(
            'zef',
            'update',
            '--yes',
            '--/test'
        );
    }

    return @mods.elems;
}
