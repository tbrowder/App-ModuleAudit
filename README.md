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
