#!/bin/bash

module-audit check-upgrades --apply     >> "$HOME/.module-audit-update.log" 2>&1
