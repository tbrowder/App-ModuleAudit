[![Actions Status](https://github.com/tbrowder/App-ModuleAudit/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/App-ModuleAudit/actions) [![Actions Status](https://github.com/tbrowder/App-ModuleAudit/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/App-ModuleAudit/actions) [![Actions Status](https://github.com/tbrowder/App-ModuleAudit/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/App-ModuleAudit/actions)

TITLE
=====

App::ModuleAudit

NAME
====

App::ModuleAudit - audit locally installed Raku modules

SYNOPSIS
========

```bash
module-audit scan
module-audit list
module-audit check-upgrades
```

DESCRIPTION
===========

`App::ModuleAudit` records and inspects the set of Raku modules installed on a local computer.

The default database location is:

    ~/.module-audit/module-audit.db

Use `--db-path` to override the database file.

COMMON COMMANDS
===============

  * `module-audit scan`

Scan installed modules and save the current module set.

  * `module-audit list`

List installed modules and print a summary status line.

  * `module-audit check-upgrades`

Check installed modules for available upgrades.

  * `module-audit report`

Print an upgrade report.

  * `module-audit prune-versions --all`

Preview removal of older installed versions.

  * `module-audit apply-file --file=modules.txt`

Preview install/update actions from a module list file.

DETAILED USAGE
==============

See `docs/USAGE.rakudoc`.

AUTHOR
======

Thomas Browder

LICENSE
=======

Artistic License 2.0

