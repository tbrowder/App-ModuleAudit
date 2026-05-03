[![Actions Status](https://github.com/tbrowder/App-ModuleAudit/actions/workflows/linux.yml/badge.svg)](https://github.com/tbrowder/App-ModuleAudit/actions) [![Actions Status](https://github.com/tbrowder/App-ModuleAudit/actions/workflows/macos.yml/badge.svg)](https://github.com/tbrowder/App-ModuleAudit/actions) [![Actions Status](https://github.com/tbrowder/App-ModuleAudit/actions/workflows/windows.yml/badge.svg)](https://github.com/tbrowder/App-ModuleAudit/actions)

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

UPGRADE CHECK NOTES
===================

`check-upgrades` and `report` write progress messages to STDERR while they query `zef info`. The default parallelism is 2 and each `zef info` command uses a 30-second timeout. Use `--parallel=1` for debugging, `--timeout=N` for slower systems, and `--quiet` to suppress progress messages.

DETAILED USAGE
==============

See `USAGE.md`.

AUTHOR
======

Tom Browder <tbrowder@acm.org>

COPYRIGHT and LICENSE
=====================

© 2026 Tom Browder

This library is free software; you may redistribute or modify it under the Artistic License 2.0.

