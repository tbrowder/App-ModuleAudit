use v6;

unit module App::ModuleAudit::Scanner;

use App::ModuleAudit::Module-Record;

sub scan-installed-modules(
    --> Array
) is export {
    my App::ModuleAudit::Module-Record:D @modules;
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

    return @modules.Array;
}

sub first-meta-index(Str:D $line --> Int) {
    my Int $best = $line.chars;

    for ':auth<', ':api<', ':ver<' -> $marker {
        my Int $index = $line.index($marker) // -1;

        if $index >= 0 and $index < $best {
            $best = $index;
        }
    }

    return $best;
}

sub parse-zef-line(
    Str:D $line
    --> App::ModuleAudit::Module-Record
) is export {
    my Str:D $name = '';
    my Str $auth;
    my Str $api;
    my Str $ver;

    my Int:D $meta-index = first-meta-index($line);

    if $meta-index < $line.chars {
        $name = $line.substr(0, $meta-index);
        my Str:D $rest = $line.substr($meta-index);

        for $rest.match(/ ':' (auth|api|ver) '<' (<-[>]>*) '>' /, :g) -> $match {
            my Str:D $key = ~$match[0];
            my Str:D $value = ~$match[1];

            if $key eq 'auth' {
                $auth = $value;
            }
            elsif $key eq 'api' {
                $api = $value;
            }
            elsif $key eq 'ver' {
                $ver = $value;
            }
        }
    }
    elsif $line ~~ /^ (\S+) \s+ '(' (<-[)]>+) ')' $/ {
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
