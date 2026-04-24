use v6;
use Test;

use App::ModuleAudit::Upgrade-Checker;
use App::ModuleAudit::Module-Record;

my $checker = App::ModuleAudit::Upgrade-Checker.new(
    runner => sub (*@cmd --> Hash:D) {
        return {
            exitcode => 0,
            out      => "name: JSON::Fast\nVersion: 0.20\n",
            err      => '',
        };
    }
);

my $current = App::ModuleAudit::Module-Record.new(
    name => 'JSON::Fast',
    ver  => '0.19',
);

my $same = App::ModuleAudit::Module-Record.new(
    name => 'Already::Current',
    ver  => '0.20',
);

ok $checker.defined, 'upgrade checker object created';

my @checked = $checker.check([$current, $same], :parallel(1));

is @checked.elems, 2, 'checked two modules';
ok @checked[0].has-upgrade, 'older module marked as upgrade available';
is @checked[0].latest-known-ver, '0.20', 'latest version recorded';
ok not @checked[1].has-upgrade, 'current module not marked as upgrade available';

my $apply-called = False;
my $apply-checker = App::ModuleAudit::Upgrade-Checker.new(
    :apply,
    runner => sub (*@cmd --> Hash:D) {
        if @cmd.elems >= 2 and @cmd[0] eq 'zef' and @cmd[1] eq 'install' {
            $apply-called = True;
        }

        return {
            exitcode => 0,
            out      => "Version: 0.30\n",
            err      => '',
        };
    }
);

my $apply-module = App::ModuleAudit::Module-Record.new(
    name => 'Needs::Apply',
    ver  => '0.10',
);

$apply-checker.check([$apply-module], :parallel(1));
ok $apply-called, 'optional apply mode invokes zef install';

done-testing;
