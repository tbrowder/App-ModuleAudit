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


my $m3 = parse-zef-line('Foo::Bar::Baz:ver<1.2.3>:auth<zef:AUTHOR>:api<2>');
is $m3.name, 'Foo::Bar::Baz', 'parsed nested module name without splitting ::';
is $m3.ver, '1.2.3', 'parsed nested structured line ver';
is $m3.auth, 'zef:AUTHOR', 'parsed auth value containing colon';
is $m3.api, '2', 'parsed nested structured line api';

done-testing;
