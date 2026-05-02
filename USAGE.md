TITLE
=====

App::ModuleAudit Usage

DATABASE
========

By default, `module-audit` uses:

    ~/.module-audit/module-audit.db

Override the database path with `--db-path`.

SCANNING
========

```bash
module-audit scan
```

LISTING
=======

```bash
module-audit list
module-audit list --repeat-headings
```

The list command shows installed modules and prints a summary line.

UPGRADE CHECKING
================

```bash
module-audit check-upgrades
module-audit check-upgrades --parallel=1 --timeout=60
module-audit report
module-audit report --quiet
```

Upgrade checks call `zef info` for each installed module. Because that can be slow, progress messages are written to STDERR before and during the checks. Use `--quiet` to suppress those progress messages.

The default upgrade-check parallelism is 2. Use `--parallel=1` when debugging or when `zef` appears overloaded. Each `zef info` command has a default timeout of 30 seconds. Use `--timeout=N` to change that timeout. A timed-out module is reported as having no latest version rather than blocking the entire run.

PRUNING OLD VERSIONS
====================

```bash
module-audit prune-versions --name=JSON::Fast
module-audit prune-versions --all
module-audit prune-versions --all --dry-run=False --force
module-audit prune-versions --all --interactive --dry-run=False --force
```

APPLYING A MODULE FILE
======================

A module file may contain simple names or full `zef`-style identities:

    JSON::Fast
    Cro::HTTP
    Some::Module:ver<1.2.3>:auth<zef:AUTHOR>

Blank lines and lines beginning with `#` are ignored.

```bash
module-audit apply-file --file=modules.txt
module-audit apply-file --file=modules.txt --dry-run=False --force
module-audit apply-file --file=modules.txt --interactive --dry-run=False --force
```

SAFETY
======

Commands that modify installed modules are dry-run by default or require `--force` for actual changes.

Prune verification
------------------

After each uninstall attempt, `prune-versions` verifies the requested older version against fresh `zef list --installed` output. The summary separates successful removals from already-absent targets, failed `zef` commands, not-verified removals, and skipped targets.

INTEGRATION TESTING
===================

The file `t/04-prune-behavior.t` creates a temporary local module, installs multiple versions with `zef`, scans them, and exercises `prune-versions`. The final uninstall verification is marked TODO until the exact local `zef` version-removal behavior is settled.

