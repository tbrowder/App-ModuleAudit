#!/bin/bash

CRON_LINE='15 2 * * * $HOME/module-audit-no-jq-full/linux/run-module-audit.sh'

(
    crontab -l 2>/dev/null
    echo "$CRON_LINE"
) | crontab -

echo "Cron job installed."
