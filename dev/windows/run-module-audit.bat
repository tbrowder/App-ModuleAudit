@echo off

module-audit check-upgrades --apply ^
    >> "%USERPROFILE%\module-audit-update.log" 2>&1
