# App::ModuleAudit

Manage local Raku modules by scanning installed modules into a SQLite database, reporting available upgrades, and providing remove/downgrade helpers.

## Common commands

```bash
module-audit scan --db-path=modules.db
module-audit list --db-path=modules.db
module-audit check-upgrades --db-path=modules.db
module-audit check-upgrades --db-path=modules.db --upgrades-only --quiet --log=upgrade.log
module-audit check-upgrades --db-path=modules.db --apply --dry-run
module-audit remove Some::Module --db-path=modules.db --dry-run
module-audit downgrade --name=Some::Module --to=1.2.3 --db-path=modules.db --dry-run
```

The canonical documentation source is `docs/README.rakudoc`.


## List output

The `list` command uses the default database at:

```text
~/.module-audit/module-audit.db
```

Use `--db-path` to override that location.

```bash
module-audit list
module-audit list --repeat-headings
```

The `list` output includes an `UPGRADE AVAILABLE` column and a final summary line with total unique installed modules, modules with available upgrades, up-to-date modules, and records missing a version.


## Prune older installed versions

Remove all but the latest installed version of one module.

The command is safe by default and runs as a dry run unless `--dry-run=False --force` is supplied.

```bash
module-audit prune-versions --name=JSON::Fast
module-audit prune-versions --name=JSON::Fast --dry-run=False --force
```


## Prune all older installed versions

Preview older installed versions for every module:

```bash
module-audit prune-versions --all
```

Actually remove older versions for every module:

```bash
module-audit prune-versions --all --dry-run=False --force
```

Prompt before each removal:

```bash
module-audit prune-versions --all --interactive --dry-run=False --force
```

The command groups modules by `name`, `auth`, and `api`, keeps the latest version in each group, and targets only older versions.


## Apply modules from a file

Install or update multiple modules from a text file.

The file may contain simple module names or full zef-style identities:

```text
JSON::Fast
Cro::HTTP
Some::Module:ver<1.2.3>:auth<zef:AUTHOR>
```

Blank lines and lines beginning with `#` are ignored.

Preview the actions:

```bash
module-audit apply-file --file=modules.txt
```

Actually install or update the listed modules:

```bash
module-audit apply-file --file=modules.txt --dry-run=False --force
```

Prompt before each action:

```bash
module-audit apply-file --file=modules.txt --interactive --dry-run=False --force
```
