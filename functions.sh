#!/bin/bash

# Array for steamID and username
declare -A steam_id_to_username

# Home Assistant notification with Long-Lived Access key and DEVICE_NAME
send_notification() {
    local message="$1"
    echo "valheim-linuxgsm-homeassistant: Sending notification: $message"
    payload=$(jq -n --arg msg "$message" '{"message": $msg, "title": "Valheim Console Log"}')
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer ${HOME_ASSISTANT_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload" "${HOME_ASSISTANT_URL}")
    echo "valheim-linuxgsm-homeassistant: Notification response code: $response"
}

# Extract Steam ID from log
extract_steam_id() {
    local line="$1"
    steam_id=$(echo "$line" | grep -oP '(?<=SteamID )\d{17}')
    echo "Extracted Steam ID: $steam_id"  # Check if Steam ID is correctly extracted
    echo "$steam_id"
}

# Username detection
handle_username_detection_event() {
    local line="$1"
    username=$(echo "$line" | awk -F' from ' '{print $2}' | cut -d':' -f1)
    echo "valheim-linuxgsm-homeassistant: Character ZDOID detected for username: $username"

    # Add the association to the associative array
    steam_id=$(extract_steam_id "$line")
    steam_id_to_username["$steam_id"]="$username"
    echo "Added association: Steam ID -> Username: $steam_id -> $username"

    # Send connection notification if SteamID is already connected
    if [[ "$line" == *"Got character ZDOID from "* ]]; then
        if [[ -n "${steam_id_to_username[$steam_id]}" ]]; then
            send_notification "User Connection: $username"
        fi
    fi
}

# Handle connection or disconnection event
handle_connection_or_disconnection_event() {
    local line="$1"
    
    if [[ "$line" == *"Got connection SteamID"* ]]; then
        steam_id=$(extract_steam_id "$line")
        echo "valheim-linuxgsm-homeassistant: Connection detected for Steam ID: $steam_id"

        # Check the associative array for username association
        if [[ -n "${steam_id_to_username[$steam_id]}" ]]; then
            username="${steam_id_to_username[$steam_id]}"
            send_notification "User Connection: $username"
        else
            echo "valheim-linuxgsm-homeassistant: No username association found for Steam ID: $steam_id"
        fi

    elif [[ "$line" == *"Closing socket"* ]]; then
        steam_id=$(extract_steam_id "$line")
        echo "valheim-linuxgsm-homeassistant: Disconnect detected for Steam ID: $steam_id"

        # Get username from array
        if [[ -n "${steam_id_to_username[$steam_id]}" ]]; then
            username="${steam_id_to_username[$steam_id]}"
            send_notification "User Disconnection: $username"
        fi

        # Remove array after disconnection
        unset steam_id_to_username["$steam_id"]
    fi
}
