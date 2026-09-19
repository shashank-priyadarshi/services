#!/bin/bash

max_lines=1000  # Maximum number of lines allowed in each log file
extensions=("log" "txt")  # List of file extensions to check
folder="$HOME/startup_script"

files=("$folder"/*)

for file in "${files[@]}"; do
    for extension in "${extensions[@]}"; do
        if [[ "$file" == *".$extension" ]]; then
            # Count the lines in the file
            num_lines=$(wc -l < "$file")
            echo $file has .$extension extension, contains $num_lines lines

            if [ "$num_lines" -gt "$max_lines" ]; then
                # Remove excess lines
                num_lines_to_remove=$((num_lines - max_lines))
                sed -i "1,${num_lines_to_remove}d" "$file"
            fi

            # Append new log entry
            new_log_entry="New log entry $(date)"
            echo "$new_log_entry" >> "$file"
            break  # Exit loop if extension is found
        fi
    done
done
