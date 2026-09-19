#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Please provide the required argument: filename to edit."
  exit 1
fi

file_pattern=$1

shopt -s dotglob

export DOC_PARENT="$HOME/Documents"
export NOTE_DIR="$DOC_PARENT/Notes"
export SEC_DIR="$NOTE_DIR/Secrets"
export TODO_DIR="$NOTE_DIR/To-Do"
export DOC_DIR="$NOTE_DIR/Docs"

if [[ "$file_pattern" == *"pass"* ]]; then
    vi $SEC_DIR/pass.txt
elif [[ "$file_pattern" == *"token"* ]]; then
	vi $SEC_DIR/access_tokens.txt    
elif [[ "$file_pattern" == *"todo"* ]]; then
    vi $TODO_DIR/todo.txt
elif [[ "$file_pattern" == *"urgent"* ]]; then
    vi $TODO_DIR/urgent.txt
elif [[ "$file_pattern" == *"read"* ]]; then
    vi $TODO_DIR/to-read.txt
elif [[ "$file_pattern" == *"url"* ]]; then
    vi $DOC_DIR/urls
elif [[ "$file_pattern" == *"golang"* ]]; then
    vi $DOC_DIR/golang
elif [[ "$file_pattern" == *"rust"* ]]; then
    vi $DOC_DIR/rust-substrate
elif [[ "$file_pattern" == *"algo"* ]]; then
    vi $DOC_DIR/algorithms
else
    echo "Error: This file does not exist or editing this file is not allowed."
fi
