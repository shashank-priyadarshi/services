print_directory() {
    local dir=${1:-.}
    local depth=${2:-0}
    local warning_dirs=()
    local printed_lines=0

    # Recursive function to print file names and subdirectories
    _print_directory() {
        local prefix=$1
        local indent=$2
        local files=()
        local dirs=()
        
        # Separate files and directories
        while IFS= read -r item; do
            if [[ -d "$prefix/$item" ]]; then
                dirs+=("$item")
            elif [[ "$item" =~ \.(pdf|docx|jpg|png|mp3|mp4)$ ]]; then
                continue
            else
                files+=("$item")
            fi
        done < <(ls -1 "$prefix")
        
        # Print directories
        for d in "${dirs[@]}"; do
            echo -e "${indent}├── \e[1m\e[34m$d\e[0m"
            if [[ $depth -gt 0 ]]; then
                _print_directory "$prefix/$d" "│   $indent" "$((depth - 1))"
            fi
        done

        # Print files
        for f in "${files[@]}"; do
            echo -e "${indent}├── \e[1m$f\e[0m"
            printed_lines=$((printed_lines + 1))
            if [[ $printed_lines -gt 50 ]]; then
                warning_dirs+=("$prefix")
            fi
        done
    }

    # Call recursive function to print directory
    echo -e "\e[1m$dir\e[0m"
    _print_directory "$dir" "" "$depth"

    # Print warning message if necessary
    if [[ ${#warning_dirs[@]} -gt 0 ]]; then
        echo -e "\e[1m\e[31mWARNING: The following directories have more than 50 files and may cause the terminal to freeze:\e[0m"
        printf "\e[1m\e[31m%s\e[0m\n" "${warning_dirs[@]}"
    fi
}

