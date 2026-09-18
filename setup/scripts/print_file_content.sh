#!/bin/bash

# Check if two arguments are provided
if [ $# -ne 2 ]; then
  echo "Please provide two arguments: a directory path and a file name."
  exit 1
fi

# Get the input values
dir=$1
filename=$2

# Set shell option to include filenames beginning with a dot in pathname expansion
shopt -s dotglob

# Initialize a flag to indicate if a matching file is found
found=0

# Iterate over all files in the directory
for file in "$dir"/*; do
  # Check if the filename contains the input string
  if [[ $(basename "$file") == *"$filename"* ]]; then
    # Print the contents of the file
    cat "$file"
    found=1
  fi
done

# If no matching file was found, display a warning
if [ $found -eq 0 ]; then
  echo "Warning: No file in $dir contains $filename in its name."
fi

