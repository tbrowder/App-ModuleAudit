use v6;
use Test;

use App::ModuleAudit::Scanner;

my $m1 = parse-zef-line('JSON::Fast:ver<0.19>:auth<zef:UGEXE>:api<1>');
is $m1.name, 'JSON::Fast', 'parsed structured line name';
is $m1.ver, '0.19', 'parsed structured line ver';
is $m1.auth, 'zef:UGEXE', 'parsed structured line auth';
is $m1.api, '1', 'parsed structured line api';

my $m2 = parse-zef-line('JSON::Fast (0.19)');
is $m2.name, 'JSON::Fast', 'parsed parenthesized line name';
is $m2.ver, '0.19', 'parsed parenthesized line ver';

done-testing;
