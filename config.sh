#!/bin/bash

# User prompt for .env
read_input_with_default() {
    local prompt="$1"
    local variable="$2"
    local default_value="$3"

    read -p "$prompt [$default_value]: " user_input

    if [ -z "$user_input" ]; then
        echo "$variable=\"$default_value\""
    else
        # For HOME_ASSISTANT_TOKEN, retain the input as is
        if [ "$variable" == "HOME_ASSISTANT_TOKEN" ]; then
            echo "$variable=\"$user_input\""
        else
            # Replace spaces with underscores and convert to uppercase
            processed_input=$(echo "${user_input// /_}" | tr '[:lower:]' '[:upper:]')
            echo "$variable=\"$processed_input\""
        fi
    fi
}

# Redirect output to .env
{
    read_input_with_default "Enter your Home Assistant Long-Lived Access Token: " HOME_ASSISTANT_TOKEN ""
    read_input_with_default "Enter path to console log: " LOG_FILE "/home/vhserver/log/console/vhserver-console.log"
    read_input_with_default "Enter your Home Assistant device name: " DEVICE_NAME "DEVICE_NAME"
} > .env

# Construct HOME_ASSISTANT_URL
source .env
HOME_ASSISTANT_URL="http://homeassistant:8123/api/services/notify/mobile_app_${DEVICE_NAME// /_}"
echo "HOME_ASSISTANT_URL=\"$HOME_ASSISTANT_URL\"" >> .env

# Set permissions for .env
chmod 600 .env

echo "Configuration complete! Your settings have been saved in .env."
echo "Please ensure that this file is stored securely and not exposed publicly."

# Start monitor prompt
read -p "Do you want to start monitoring now? [y/n] (y): " run_main

if [[ "$run_main" =~ ^[Yy]$ || -z "$run_main" ]]; then
    echo "Starting the monitor..."
    ./main.sh
else
    echo "Monitor setup completed. You can start it by running './main.sh' when ready."
fi
