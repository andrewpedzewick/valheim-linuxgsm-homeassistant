#!/bin/bash

source .env
source ./functions.sh

echo "Valheim LinuxGSM Home Assistant Monitor is starting..."
echo "Monitoring log file: ${LOG_FILE}"

# Valheim console log monitor
tail -n 0 -f "${LOG_FILE}" | while IFS= read -r line; do
    
    echo "$line"
    
    # Check ZDOID for username association
    if [[ "$line" == *"Got character ZDOID from "* ]]; then
        username_detect "$line"
        continue
    fi

    # Check for connect or disconnect
    if [[ "$line" == *"Got connection SteamID"* || "$line" == *"Closing socket"* ]]; then
        connect_or_disconnect "$line"
        continue
    fi
    
done