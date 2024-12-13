#!/bin/bash

# Set variables

LOG_FILE="/home/vhserver/log/console/vhserver-console.log" # default for linuxgsm valheim install
USER_FILE="/home/vhserver/user_data.txt" # move this if desired
HOME_ASSISTANT_URL="http://homeassistant:8123/api/services/notify/mobile_app_DEVICE_NAME" # default url for homeassistant. find device name in homeassistant under Settings>Devices>Mobile App
HOME_ASSISTANT_TOKEN="API KEY" # found under homeassistant Username>Security>Long-Lived access tokens. Create token if needed

# Send notification to homeassistant routine
send_notification() {
    local message="$1"
    echo "valheim-linuxgsm-homeassistant: Sending notification: $message"
    payload=$(jq -n --arg msg "$message" '{"message": $msg, "title": "Valheim Console Log"}')
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $HOME_ASSISTANT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$HOME_ASSISTANT_URL")
    echo "valheim-linuxgsm-homeassistant: Notification response code: $response"
}

# Get username from file routine
get_username_from_file() {
    local steam_id="$1"
    grep "^$steam_id=" "$USER_FILE" | cut -d'=' -f2
}

# Add username to file if doesn't exist routine
add_steam_id_with_username() {
    local steam_id="$1"
    local username="$2"
    if ! grep -q "^$steam_id=" "$USER_FILE"; then
        echo "$steam_id=$username" >> "$USER_FILE"
        echo "valheim-linuxgsm-homeassistant: Added new Steam ID: $steam_id with username: $username"
    fi
}

# Monitor linuxgsm console.log for new entries
tail -F "$LOG_FILE" | while read -r line; do
    echo "$line"

    # Check for handshake event
    if [[ "$line" == *"Got handshake from client"* ]]; then
        steam_id=$(echo "$line" | grep -oP '(?<=Got handshake from client )\d{17}')
        echo "valheim-linuxgsm-homeassistant: Handshake detected for Steam ID: $steam_id"
    fi

    # Check for username in log
    if [[ "$line" == *"Got character ZDOID from"* ]]; then
        username=$(echo "$line" | awk -F' from ' '{print $2}' | cut -d':' -f1)
        echo "valheim-linuxgsm-homeassistant: Character ZDOID detected for username: $username"
        if [[ -n "$steam_id" && -n "$username" ]]; then
            add_steam_id_with_username "$steam_id" "$username"
        fi
    fi

    # Check for connection or disconnection
    if [[ "$line" == *"Got connection SteamID"* ]] || [[ "$line" == *"Closing socket"* ]]; then
        if [[ "$line" == *"Got connection SteamID"* ]]; then
            event="Connection"
            steam_id=$(echo "$line" | grep -oP '(?<=Got connection SteamID )\d{17}')
        elif [[ "$line" == *"Closing socket"* ]]; then
            event="Disconnect"
            steam_id=$(echo "$line" | grep -oP '(?<=Closing socket )\d{17}')
        fi
        echo "valheim-linuxgsm-homeassistant: $event detected for Steam ID: $steam_id"

        # Associate username Steam ID
        username=$(get_username_from_file "$steam_id")
        echo "valheim-linuxgsm-homeassistant: Username retrieved: $username"

        #if [[ -n "$username" ]]; then
        #    echo "valheim-linuxgsm-homeassistant: Sending $event notification for: $username"
        #    send_notification "User $event: $username"
        #else
        #    echo "valheim-linuxgsm-homeassistant: Sending $event notification for: $steam_id"
        #    send_notification "User $event: $steam_id"
        #fi
    fi
done


