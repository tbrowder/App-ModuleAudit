use v6;

unit class App::ModuleAudit::Upgrade-Checker;

use App::ModuleAudit::Module-Record;

has Callable $.runner;
has Bool:D $.apply = False;
has Bool:D $.dry-run = False;
has Bool:D $.quiet = False;
has Int:D $.timeout = 30;

method progress(Str:D $message --> Nil) {
    return if $.quiet;

    note $message;
    $*ERR.flush;
}

method run-command(*@cmd --> Hash:D) {
    if $.runner.defined {
        return $!runner.(|@cmd);
    }

    self.progress("Running: {@cmd.join(' ')}");

    my $proc = Proc::Async.new(|@cmd);
    my Str:D $out = '';
    my Str:D $err = '';

    $proc.stdout.tap(-> $data { $out ~= $data.Str });
    $proc.stderr.tap(-> $data { $err ~= $data.Str });

    my $proc-promise = $proc.start;
    my $timeout-promise = Promise.in($.timeout);

    await Promise.anyof($proc-promise, $timeout-promise);

    if $timeout-promise.status ~~ Kept and $proc-promise.status !~~ Kept {
        $proc.kill;

        return {
            exitcode => -1,
            out      => $out,
            err      => "Timed out after {$.timeout} seconds: {@cmd.join(' ')}",
            timeout  => True,
        };
    }

    my $result = await $proc-promise;

    return {
        exitcode => $result.exitcode,
        out      => $out,
        err      => $err,
        timeout  => False,
    };
}

method lookup-latest-version(
    App::ModuleAudit::Module-Record:D $module
    --> Str
) {
    my %result = self.run-command('zef', 'info', $module.name);

    if %result<exitcode> != 0 {
        my Str:D $err = %result<err>.Str.trim;

        if $err.chars > 0 {
            self.progress("  {$module.name}: {$err}");
        }

        return Nil;
    }

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
    self.progress("Checking {$module.name}...");

    try {
        my Str $latest = self.lookup-latest-version($module);

        if $latest.defined and $latest.chars > 0 {
            $module.mark-latest($latest);

            if $module.has-upgrade {
                self.progress("  {$module.name}: installed={$module.ver // '*'} latest={$latest} upgrade=yes");
            }
            else {
                self.progress("  {$module.name}: installed={$module.ver // '*'} latest={$latest} upgrade=no");
            }
        }
        else {
            self.progress("  {$module.name}: no latest version found");
        }

        if $.apply and $module.has-upgrade {
            self.progress("  {$module.name}: applying upgrade");
            $module.install-latest(:runner($!runner), :dry-run($.dry-run));
        }

        CATCH {
            default {
                self.progress("  {$module.name}: check failed: {.message}");
            }
        }
    }

    return $module;
}

method check(
    @modules,
    Int:D :$parallel = 2
    --> Array
) {
    my Int:D $effective-parallel = $parallel < 1 ?? 1 !! $parallel;
    my App::ModuleAudit::Module-Record:D @checked;
    my @batch;

    self.progress("Starting upgrade check for {@modules.elems} module(s); parallel={$effective-parallel}; timeout={$.timeout}s");

    for @modules -> $module {
        @batch.push(
            start {
                self.check-one($module);
            }
        );

        if @batch.elems >= $effective-parallel {
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

    self.progress("Finished upgrade check for {@checked.elems} module(s)");

    return @checked.Array;
}
