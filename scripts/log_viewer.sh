#!/bin/bash

# Specify the log file paths and names
LOG_FILE="$HOME/startup_script/logfile.log"
ERROR_LOG_FILE="$HOME/startup_script/errorlog.log"

# Function to view logs in a new terminal window
view_logs() {
    echo "Log File:"
    cat "$LOG_FILE"
    echo
    echo "Error Log File:"
    cat "$ERROR_LOG_FILE"
}

# Open a new terminal window and execute the view_logs function
gnome-terminal --title="Startup Logs" -- /bin/bash -c "clear; view_logs; exec /bin/bash"
