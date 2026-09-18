#!/bin/bash
SSID=$1
ORG_WIFI=""
CURR_SSID=$(nmcli -t -f active,ssid dev wifi | grep -i '^yes' | cut -d: -f2)
NETWORK_DEVICE_NAME="" # find using command 'nmcli device status', and select the appropriate network device

trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

nmcli radio wifi on

if nmcli connection show --active | grep -q "\<$NETWORK_DEVICE_NAME\>"; then
    if [ "$(trim "$CURR_SSID")" = "$(trim "$SSID")" ]; then
        echo Device already connected to $CURR_SSID.
        exit 0
    fi
    echo Device is connected. Disconnecting...
    nmcli device disconnect $NETWORK_DEVICE_NAME
    echo Disconnected
    sleep 5
fi

# Set/unset custom network settings for your organisation device/WiFi here 
if [ "$SSID" = "$ORG_WIFI" ]; then
    # gsettings set org.gnome.system.proxy mode manual
else
    # gsettings set org.gnome.system.proxy mode none && unset no_proxy https_proxy HTTPS_PROXY HTTP_PROXY http_proxy
fi

echo Connecting to $SSID...
sleep 5
BSSIDS=($(nmcli device wifi list | grep "$SSID" | awk '{print $1}'))

if [ ${#BSSIDS[@]} -eq 0 ]; then
    echo "No Wi-Fi network with SSID '$SSID' found."
    exit 1
fi

for BSSID_ADDRESS in "${BSSIDS[@]}"; do
    echo "Attempting to connect to Wi-Fi network with BSSID: $BSSID_ADDRESS"
    nmcli device wifi connect "$BSSID_ADDRESS"

    # Check if the connection was successful (exit code 0) or not (exit code 2).
    if [ $? -eq 0 ]; then
        echo "Connected to Wi-Fi network with SSID: $SSID"
        exit 0
    else
        echo "Connection to Wi-Fi network with BSSID $BSSID_ADDRESS failed. Retrying..."
        # Retry connecting to the same BSSID after a short delay.
        sleep 2
        nmcli device wifi connect "$BSSID_ADDRESS"

        # Check if the connection was successful after the retry.
        if [ $? -eq 0 ]; then
            echo "Connected to Wi-Fi network with SSID: $SSID"
            exit 0
        fi
    fi
done

echo "Unable to connect to any Wi-Fi network with SSID: $SSID"
exit 1
