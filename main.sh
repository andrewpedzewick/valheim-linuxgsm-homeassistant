#!/bin/bash

source .env
source ./functions.sh

echo "Valheim LinuxGSM Home Assistant Monitor is starting..."
echo "Monitoring log file: ${LOG_FILE}"

# Valheim console log monitor loop
tail -n 0 -f "${LOG_FILE}" | while IFS= read -r line; do
    
    echo "$line"
    
    # Check ZDOID for username association
    if [[ "$line" == *"Got character ZDOID from "* ]]; then
        handle_username_detection_event "$line"
        continue
    fi

    # Check for connection or disconnection
    if [[ "$line" == *"Got connection SteamID"* || "$line" == *"Closing socket"* ]]; then
        handle_connection_or_disconnection_event "$line"
        continue
    fi
    
done
