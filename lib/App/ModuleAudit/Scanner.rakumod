use v6;

unit module App::ModuleAudit::Scanner;

use App::ModuleAudit::Module-Record;

sub scan-installed-modules(
    --> Array[App::ModuleAudit::Module-Record:D]
) is export {
    my Array[App::ModuleAudit::Module-Record:D] @modules;
    my %seen;

    my $proc = run 'zef', 'list', '--installed', :out, :err;

    my Str:D $stdout = $proc.out.slurp-rest;
    my Str:D $stderr = $proc.err.slurp-rest;

    if $proc.exitcode != 0 {
        die "Failed to scan installed modules with zef: {$stderr}";
    }

    for $stdout.lines -> $line {
        my Str:D $trimmed = $line.trim;
        next if $trimmed eq '';
        next if $trimmed.lc.starts-with('searching ');
        next if $trimmed.lc.starts-with('updating ');
        next if $trimmed.lc.starts-with('installed ');
        next if $trimmed ~~ /^ '===' /;

        my $module = parse-zef-line($trimmed);
        next if not $module.defined;

        my Str:D $key = $module.full-identity-key;
        next if %seen{$key}:exists;

        %seen{$key} = True;
        @modules.push($module);
    }

    return @modules;
}

sub parse-zef-line(
    Str:D $line
    --> App::ModuleAudit::Module-Record
) is export {
    my Str:D $name = '';
    my Str $auth;
    my Str $api;
    my Str $ver;

    if $line ~~ /^
        (<[A..Za..z0..9_.-]>+ [ '::' <[A..Za..z0..9_.-]>+ ]*)
        [
            ':' (.*)
        ]?
        $
    / {
        $name = ~$0;
        my Str:D $rest = $1.defined ?? ~$1 !! '';

        if $rest.chars > 0 {
            for $rest.split(':') -> $chunk {
                if $chunk ~~ /^ 'auth<' (.+) '>' $/ {
                    $auth = ~$0;
                }
                elsif $chunk ~~ /^ 'api<' (.+) '>' $/ {
                    $api = ~$0;
                }
                elsif $chunk ~~ /^ 'ver<' (.+) '>' $/ {
                    $ver = ~$0;
                }
            }
        }
    }
    elsif $line ~~ /^
        (<[A..Za..z0..9_.-]>+ [ '::' <[A..Za..z0..9_.-]>+ ]*)
        \s+ '(' (.+) ')'
        $
    / {
        $name = ~$0;
        $ver = ~$1;
    }
    else {
        my @parts = $line.words;
        return Nil if not @parts;

        $name = @parts[0];
        for @parts.skip(1) -> $part {
            if $part ~~ /^ 'auth=' (.+) $/ {
                $auth = ~$0;
            }
            elsif $part ~~ /^ 'api=' (.+) $/ {
                $api = ~$0;
            }
            elsif $part ~~ /^ 'ver=' (.+) $/ {
                $ver = ~$0;
            }
        }
    }

    return Nil if $name eq '';

    return App::ModuleAudit::Module-Record.new(
        name => $name,
        auth => $auth,
        api  => $api,
        ver  => $ver,
    );
}
