# App::ModuleAudit

`App::ModuleAudit` is a small Raku command-line tool for auditing locally installed Raku modules.

It can:

- scan installed modules into a local SQLite database
- list the current installed module set
- check for available upgrades
- remove or downgrade modules
- prune older installed versions
- apply installs or updates from a file

## Install

From the project directory:

```bash
zef install .
```

For testing during development:

```bash
zef test .
```

## Default database

By default, the tool stores its database at:

```text
~/.module-audit/module-audit.db
```

Use `--db-path=/path/to/file.db` to override that location.

## Quick start

```bash
module-audit scan
module-audit list
module-audit list --repeat-headings
module-audit check-upgrades
module-audit report
```

## Maintenance commands

```bash
module-audit prune-versions --name=JSON::Fast
module-audit prune-versions --all
module-audit prune-versions --all --dry-run=False --force
module-audit apply-file --file=modules.txt
module-audit apply-file --file=modules.txt --dry-run=False --force
```

## More documentation

Detailed usage notes are in:

```text
docs/USAGE.rakudoc
```

The source document for this README is:

```text
docs/README.rakudoc
```

## License

This project is distributed under the Artistic License 2.0.
