use v6;

unit module App::ModuleAudit;

use App::ModuleAudit::Module-Record;
use App::ModuleAudit::Module-Store;

our sub scan-and-save(Str:D :$db-path! --> Int:D) is export {
    my $store = App::ModuleAudit::Module-Store.new(db-path => $db-path);
    return $store.scan-and-save();
}

our sub load-installed(
    Str:D :$db-path!
    --> Array
) is export {
    my $store = App::ModuleAudit::Module-Store.new(db-path => $db-path);
    return $store.load-installed();
}

our sub check-for-upgrades(
    Str:D :$db-path!,
    Int:D :$parallel = 4,
    Bool:D :$apply = False,
    Bool:D :$dry-run = False
    --> Array
) is export {
    my $store = App::ModuleAudit::Module-Store.new(db-path => $db-path);
    return $store.check-upgrades(
        parallel => $parallel,
        :$apply,
        :$dry-run,
    );
}

our sub remove-modules(
    Str:D :$db-path!,
    *@names,
    Bool:D :$dry-run = False
    --> Int:D
) is export {
    my $store = App::ModuleAudit::Module-Store.new(db-path => $db-path);
    my @installed = $store.load-installed();
    my Int:D $count = 0;

    for @installed -> $module {
        ##next if $module.name not eq any(@names);
        next if $module.name ne any(@names);

        if $store.remove-module($module, :$dry-run) {
            $count++;
        }
    }

    return $count;
}

our sub downgrade-modules(
    Str:D :$db-path!,
    *%targets,
    Bool:D :$dry-run = False
    --> Int:D
) is export {
    my $store = App::ModuleAudit::Module-Store.new(db-path => $db-path);
    my @installed = $store.load-installed();
    my Int:D $count = 0;

    for @installed -> $module {
        next if not %targets{$module.name}:exists;

        my Str:D $target-ver = %targets{$module.name}.Str;

        if $store.downgrade-module(
            $module,
            :$target-ver,
            :$dry-run,
        ) {
            $count++;
        }
    }

    return $count;
}
