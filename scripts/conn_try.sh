#!/bin/bash
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
    echo Device already connected to $CURR_SSID.
    echo Try using "conn <WiFi SSID>" to switch network. 
    # exit 0
fi

file=$HOME/startup_script/connected_net.log # list of saved networks
while read line; do
    SSID="$(trim "$line")"
    if [ "$(trim "$CURR_SSID")" = $SSID ]; then
	    echo Device already connected to $line.
	    exit 0
    fi
    "$HOME"/wifi-parser.sh $SSID
    if [ $? -eq 0 ]; then
	    echo Connected to $line.
	    exit 0
    fi
done < $file
echo Unable to connect to any recently connected network.
exit 1
