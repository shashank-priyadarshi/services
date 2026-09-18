#!/bin/bash

# Get the input values
dir="$1"

# Set shell option to include filenames beginning with a dot in pathname expansion
shopt -s dotglob

# Update the variable based on the input
if [ "$1" == "" ]; then
    dir=$HOME/go/src
elif [ "$1" == "gh" ]; then
    dir=$HOME/go/src/github.com/shashank-priyadarshi
elif [ "$1" == "vanity" ]; then
    dir=$HOME/go/src/go.ssnk.in
fi

# Try to change to the specified directory
if ! cd $dir > /tmp/cd_error_log 2>&1; then
    error_message=$(cat /tmp/cd_error_log)
    clean_message=$(echo "$error_message" | sed 's/^.*: //')
    echo "Please enter a valid directory: error: $clean_message"
    rm /tmp/cd_error_log  # Clean up the error log
    return 1
fi

tree -d -L 3
