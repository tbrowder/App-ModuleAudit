use v6;
use Test;

use App::ModuleAudit::Module-Record;

my $module = App::ModuleAudit::Module-Record.new(
    name => 'JSON::Fast',
    auth => 'zef:UGEXE',
    api  => '1',
    ver  => '0.19',
);

is $module.name, 'JSON::Fast', 'name is correct';
is $module.auth, 'zef:UGEXE', 'auth is correct';
is $module.api, '1', 'api is correct';
is $module.ver, '0.19', 'ver is correct';

ok not $module.has-upgrade, 'no upgrade initially';

$module.mark-latest('0.20');
ok $module.has-upgrade, 'upgrade detected';
is $module.latest-known-ver, '0.20', 'latest version stored';

done-testing;
