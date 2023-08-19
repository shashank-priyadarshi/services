.#!/bin/bash

# Specify the log file paths and names
LOG_FILE="$HOME/startup_script/logfile.log"
ERROR_LOG_FILE="$HOME/startup_script/errorlog.log"

# Function to log messages to the log file
log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $*" >> "$LOG_FILE"
}

# Function to log error messages to the error log file
log_error() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - ERROR: $*" >> "$ERROR_LOG_FILE"
}

# Redirect stdout to the log file
exec >> "$LOG_FILE"

# Redirect stderr to the error log file
exec 2>> "$ERROR_LOG_FILE"

# $HOME/startup_script/log_viewer.sh

echo "Connecting to an available Wi-Fi network..."
nmcli radio wifi on
"$HOME"/startup_script/conn_try.sh &

# Start other applications
echo "Starting JetBrains GoLand..."
# goland &
# echo "Starting Google Chrome..."
# google-chrome &
# echo "Starting Microsoft Edge..."
# microsoft-edge https://teams.microsoft.com https://outlook.office.com/mail &

# Example log message
log_message "Startup script completed successfully."

exit 0
