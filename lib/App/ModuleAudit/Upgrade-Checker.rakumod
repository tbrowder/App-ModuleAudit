use v6;

unit class App::ModuleAudit::Upgrade-Checker;

use App::ModuleAudit::Module-Record;

has Callable $.runner;
has Bool:D $.apply = False;
has Bool:D $.dry-run = False;

method run-command(*@cmd --> Hash:D) {
    if $.runner.defined {
        return $!runner.(|@cmd);
    }

    my $proc = run |@cmd, :out, :err;

    return {
        exitcode => $proc.exitcode,
        out      => $proc.out.slurp-rest,
        err      => $proc.err.slurp-rest,
    };
}

method lookup-latest-version(
    App::ModuleAudit::Module-Record:D $module
    --> Str
) {
    my %result = self.run-command('zef', 'info', $module.name);

    return Nil if %result<exitcode> != 0;

    for %result<out>.Str.lines -> $line {
        my Str:D $trimmed = $line.trim;

        if $trimmed ~~ /^ 'Version:' \s* (.+) $/ {
            return ~$0;
        }
        elsif $trimmed ~~ / 'ver<' (<-[>]>+) '>' / {
            return ~$0;
        }
    }

    return Nil;
}

method check-one(
    App::ModuleAudit::Module-Record:D $module
    --> App::ModuleAudit::Module-Record:D
) {
    my Str $latest = self.lookup-latest-version($module);

    if $latest.defined and $latest.chars > 0 {
        $module.mark-latest($latest);
    }

    if $.apply and $module.has-upgrade {
        $module.install-latest(:runner($!runner), :dry-run($.dry-run));
    }

    return $module;
}

method check(
    @modules,
    Int:D :$parallel = 4 --> Array) {
    my App::ModuleAudit::Module-Record:D @checked;
    my @batch;

    for @modules -> $module {
        @batch.push(
            start {
                self.check-one($module);
            }
        );

        if @batch.elems >= $parallel {
            for await @batch -> $checked-module {
                @checked.push($checked-module);
            }
            @batch = ();
        }
    }

    if @batch.elems > 0 {
        for await @batch -> $checked-module {
            @checked.push($checked-module);
        }
    }

    return @checked.Array;
}
