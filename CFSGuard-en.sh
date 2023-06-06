#!/bin/bash

echo "[Success] The domain and server are DDoS protected by CFSGuard!"
echo "[Note] Closing this script will remove the DDoS protection."

# CloudFlare Global API key and Zone ID to enable UAM
api_key="YOUR_API_KEY"
zone_id="YOUR_ZONE_ID"

# Check if the required commands are installed
for command in tcpdump jq curl
do
    if [[ ! $(type $command 2> /dev/null) ]]; then
        echo "Error: ${command} command not found. (Please run 'sudo apt install ${command}' to install it)"
        exit
    fi
done

if [[ -z $api_key || -z $zone_id ]]; then
    echo "You need to update the API_KEY and ZONE_ID in the script."
    exit
fi

api_url="https://api.cloudflare.com/client/v4/zones/$zone_id/settings/security_level"

# Get the current Security Level setting
current_security_level=$(curl -X GET "$api_url" \
    -H "Authorization: Bearer $api_key" \
    -H "Content-Type: application/json" \
    --silent \
    | jq -r '.result.value')

# Number of requests per second (default: 50)
threshold=50

# Duration threshold in seconds to trigger UAM (default: 10 seconds)
duration_threshold=10

# Security Level to set when disabling UAM (default: high)
default_security_level="high"

while true; do
    counter=0

    while true; do
        # Get the traffic volume per second
        traffic=$(tcpdump -i eth0 -c 100 -n 2>/dev/null | wc -l)

        if [ "$traffic" -gt "$threshold" ]; then
            # Increment the counter if traffic exceeds the threshold
            counter=$((counter + 1))
        else
            # Reset the counter if traffic falls below the threshold
            counter=0
        fi

        if [ "$counter" -ge "$duration_threshold" ]; then
            if [ "$current_security_level" != "under_attack" ]; then
                # Send API request to enable UAM mode
                result=$(curl -X PATCH "$api_url" \
                    -H "Authorization: Bearer $api_key" \
                    -H "Content-Type: application/json" \
                    --data '{"value": "under_attack"}' \
                    --silent \
                    | jq -r '.success')

                if [ "$result" = "true" ]; then
                    # Display message when UAM mode is enabled
                    start_time=$(date +"%Y-%m-%d %H:%M:%S")
                    echo "[+] UAM mode is enabled. ($start_time)"

                    # Update the current security level to under_attack
                    current_security_level="under_attack"
                fi
            fi

            break
        fi

        sleep 1
    done

    # Stop UAM mode after a specified duration (If the attack continues, UAM mode will be re-enabled immediately)
    sleep 600 # seconds

    if [ "$current_security_level" = "under_attack" ]; then
        # Send API request to disable UAM mode
        result=$(curl -X PATCH "$api_url" \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            --data "{\"value\": \"$default_security_level\"}" \
            --silent \
            | jq -r '.success')

        if [ "$result" = "true" ]; then
            # Display message when UAM mode is disabled
            end_time=$(date +"%Y-%m-%d %H:%M:%S")
            echo "[-] UAM mode is disabled. ($end_time)"

            # Update the current security level to the default value
            current_security_level="$default_security_level"
        fi
    fi
done
