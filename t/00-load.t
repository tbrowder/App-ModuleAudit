use v6;
use Test;

my @modules = <
   App::ModuleAudit
   App::ModuleAudit::DB
   App::ModuleAudit::Upgrade-Checker
   App::ModuleAudit::Module-Record
   App::ModuleAudit::Module-Store
   App::ModuleAudit::Scanner
>;


plan @modules.elems;

for @modules -> $m {
    use-ok $m, "Module '$m' used okay";
}
