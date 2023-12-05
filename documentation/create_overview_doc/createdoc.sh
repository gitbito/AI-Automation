#!/bin/bash
#set -x

log_file="bito_usage_log.txt"
prompt_folder="AI_Prompts"
total_input_token_count=0
total_output_token_count=0
lang_csv="programming_languages.csv"
skip_list_csv="skip_list.csv"

function bito_response_ok() {
    echo "Validating response from Bito command..." >&2
    [[ $1 -ne 0 || $2 == Whoops* || -z $2 ]] && return 1 || return 0
}

function update_token_usage() {
    echo "Updating session token counts..." >&2
    local tokens=$(echo "$1 $2" | wc -w | awk '{print int($1 * 1.34)}')
    total_input_token_count=$((total_input_token_count + tokens))
    total_output_token_count=$((total_output_token_count + tokens))
}

function log_token_usage_and_session_duration() {
    echo "Finalizing session log with token usage and duration..." >&2
    local duration=$(( $(date +%s) - start_time ))
    echo "-----------------------------------------" | tee -a "$log_file"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Total Token Usage for Session" | tee -a "$log_file"
    echo "Total Input Tokens = $total_input_token_count" | tee -a "$log_file"
    echo "Total Output Tokens = $total_output_token_count" | tee -a "$log_file"
    echo "Session Duration: $((duration / 3600))h $(((duration % 3600) / 60))m $((duration % 60))s" | tee -a "$log_file"
    echo "-----------------------------------------" | tee -a "$log_file"
}

function check_tools_and_files() {
    echo "Ensuring all necessary tools and files are available..." >&2
    local required_tools=("bito")
    local required_files=("high_level_doc_prompt.txt" "system_introduction_prompt.txt")

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "\nError: Tool $tool is required but not found."
            case "$tool" in
                "bito")
                    echo "   Install Bito CLI on MAC and Linux with:"
                    echo "   sudo curl https://alpha.bito.ai/downloads/cli/install.sh -fsSL | bash"
                    echo "   On Archlinux, install with yay or paru: yay -S bito-cli or paru -S bito-cli"
                    echo "   For Windows, download and install the MSI from Bito's website."
                    echo "   Follow the instructions provided by the installer."
                    ;;
            esac
            exit 1
        fi
    done

    for file in "${required_files[@]}"; do
        if [ ! -f "$prompt_folder/$file" ]; then
            echo -e "\nError: Missing required file: $prompt_folder/$file"
            exit 1
        fi
    done
    echo -e "All required tools and files are present. Proceeding...\n" >&2
}

function read_skip_list() {
    echo "Loading exclusion patterns from skip list..." >&2
    if [ -f "$skip_list_csv" ]; then
        skip_list=()
        while IFS=, read -r skip_item; do
            skip_list+=("$skip_item")
        done < "$skip_list_csv"
    else
        echo "Skip list file $skip_list_csv not found."
        exit 1
    fi
}

function is_skippable() {
    echo "Evaluating if the path $1 should be excluded..." >&2
    local path=$1
    local skip_dirs_files=("logs" "node_modules" "dist" "target" "bin" "package-lock.json" "data.json" "build" ".gradle" ".idea" "gradle" "extension.js" "vendor.js" "ngsw.json" "polyfills.js" "init" ".gv")
  
    for skip_item in "${skip_dirs_files[@]}"; do
        if [[ "$path" == *"$skip_item"* ]]; then
            return 0
        fi
    done

    if [[ $(basename "$path") == .* ]]; then
        return 0
    fi

    return 1
}

function call_bito_with_retry() {
    echo "Initiating Bito command with retry for prompt file $2..." >&2
    local input_text=$1 prompt_file_path=$2 error_message=$3
    local attempt=1 MAX_RETRIES=5 RETRY_DELAY=10 output

    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt: Calling Bito for prompt '$prompt_file_path'..." >&2
        output=$(echo -e "$input_text" | bito -p "$prompt_file_path")
        local ret_code=$?

        if ! bito_response_ok "$ret_code" "$output"; then
            echo "Attempt $attempt: $error_message Retrying in $RETRY_DELAY seconds..." >&2
            sleep $RETRY_DELAY
            ((attempt++))
        else
            echo "Bito call successful on attempt $attempt." >&2
            echo "$output"
            update_token_usage "$input_text" "$output"
            return 0
        fi
    done

    echo "Failed to call Bito after $MAX_RETRIES attempts. $error_message" >&2
    return 1
}

function create_module_documentation() {
    local path_to_module="$1"
    local documentation_directory="$2"
    echo "Generating documentation for the module at $path_to_module..." >&2

    if is_skippable "$path_to_module"; then
        echo "Skipped $path_to_module as it's on the exclusion list."
        return
    fi

    local name_of_module=$(basename "$path_to_module")
    local content_of_module=$(<"$path_to_module")

    local high_level_documentation
    high_level_documentation=$(call_bito_with_retry "Module: $name_of_module\n---\n$content_of_module" "$prompt_folder/high_level_doc_prompt.txt" "High-level documentation creation failed for module: $name_of_module")
    local ret_code=$?
    if ! bito_response_ok "$ret_code" "$high_level_documentation"; then
        echo "High-level documentation creation failed for module: $name_of_module"
        return 1
    fi

    update_token_usage "$content_of_module" "$high_level_documentation"

    local markdown_documentation_file="$documentation_directory/${name_of_module}_Doc.md"
    echo -e "## Module: $name_of_module\n$high_level_documentation" >> "$markdown_documentation_file"

    # Generate the flow chart for the module
    generate_flow_chart "$path_to_module" "$documentation_directory/flowmaps"

    # Add link to the flow chart in the documentation
    local flow_chart_name=$(basename "$path_to_module" | cut -f 1 -d '.')
    echo -e "\n![Flow Chart of $flow_chart_name](./flowmaps/${flow_chart_name}_FlowChart.png)\n" >> "$markdown_documentation_file"

    echo -e "Documentation saved to $markdown_documentation_file\n\n" >&2
}

function extract_module_details_and_call_bito() {
    local filename=$1 prompt_file_path=$2 lines=() current_module="" current_objectives="" current_operational_sequence="" capture_objectives=false capture_operational_sequence=false combined_output=""

    echo "Compiling objectives and details for module in $filename..." >&2

    while IFS= read -r line; do lines+=("$line"); done < "$filename"

    for line in "${lines[@]}"; do
        if [[ $line =~ ^##\ Module:\ (.*) ]]; then
            if [[ -n $current_module ]]; then
                echo "Processing module: $current_module with objectives and operational sequence" >&2
                combined_output+="Module: $current_module\n---\nPrimary Objectives:\n$current_objectives\nOperational Sequence:\n$current_operational_sequence\n\n"
            fi
            current_module=${BASH_REMATCH[1]}
            current_objectives="" current_operational_sequence=""
            capture_objectives=false capture_operational_sequence=false
        elif [[ $line =~ ^-\ \*\*Primary\ Objectives\*\*: ]]; then
            capture_objectives=true
            capture_operational_sequence=false
            current_objectives+=$(echo $line | sed 's/.*\*\*Primary Objectives\*\*: //')$'\n'
        elif [[ $line =~ ^-\ \*\*Operational\ Sequence\*\*: ]]; then
            capture_operational_sequence=true
            capture_objectives=false
            current_operational_sequence+=$(echo $line | sed 's/.*\*\*Operational Sequence\*\*: //')$'\n'
        elif $capture_objectives && [[ $line =~ ^-\ .+ ]]; then
            current_objectives+=$(echo $line | sed 's/^-\ //')$'\n'
        elif $capture_operational_sequence && [[ $line =~ ^-\ .+ ]]; then
            current_operational_sequence+=$(echo $line | sed 's/^-\ //')$'\n'
        elif [[ $line == "## "* || $line == "" ]]; then
            capture_objectives=false capture_operational_sequence=false
        fi
    done

    if [[ -n $current_module ]]; then
        echo "Processing module: $current_module with objectives and operational sequence" >&2
        combined_output+="Module: $current_module\n---\nPrimary Objectives:\n$current_objectives\nOperational Sequence:\n$current_operational_sequence\n\n"
    fi

    if bito_output=$(call_bito_with_retry "$combined_output" "$prompt_file_path" "Failed for module: $current_module"); then
        echo "Bito call successful for module: $current_module" >&2
        echo "$bito_output"
        update_token_usage "$combined_output" "$bito_output"
    else
        echo "Failed to call bito for module: $current_module with adequate content." >&2
        return 1
    fi
}

function create_find_command() {
    local lang_file="$1"
    local folder_to_document="$2"
    echo "Assembling command to locate relevant files in $folder_to_document..." >&2
    local find_command="find \"$folder_to_document\" -type f"

    while IFS= read -r ext; do
        find_command="$find_command -o -name \"*.$ext\""
    done < "$lang_file"

    find_command="${find_command/-o /\\( } \)"
    echo "$find_command"
}

function generate_flow_chart() {
    local module_file="$1"
    local flowchart_folder="$2"

    # Check if the flowchart folder exists, if not, create it
    if [ ! -d "$flowchart_folder" ]; then
        echo "Creating flowchart directory: $flowchart_folder"
        mkdir -p "$flowchart_folder"
    fi

    # Define the name of the flow chart file based on the module name
    local module_name=$(basename "$module_file" | cut -f 1 -d '.')
    local flowchart_file="$flowchart_folder/${module_name}_FlowChart.png"

    # Call code2flow to generate the flow chart
    code2flow "$module_file" -o "$flowchart_file" --hide-legend --no-trimming --verbose --skip-parse-errors

    # Check if the flow chart was successfully generated
    if [ -f "$flowchart_file" ]; then
        echo "Flow chart created for module: $module_name"
    else
        echo "Failed to create flow chart for module: $module_name" >&2
    fi
}

function generate_flow_chart_for_system() {
    local source_folder="$1"
    local output_file="$2"

    # Check if the source folder exists
    if [ ! -d "$source_folder" ]; then
        echo "Source folder $source_folder does not exist" >&2
        return 1
    fi

    # Check if the output directory exists, if not, create it
    local output_dir=$(dirname "$output_file")
    if [ ! -d "$output_dir" ]; then
        echo "Creating directory for system flowchart: $output_dir"
        mkdir -p "$output_dir"
    fi

    # Generate a flowchart for the entire system
    echo "Generating system flowchart..."
    code2flow "$source_folder" -o "$output_file" --hide-legend --no-trimming --verbose --skip-parse-errors

    # Check if the flowchart was successfully generated
    if [ -f "$output_file" ]; then
        echo "System flowchart created successfully"
    else
        echo "Failed to create system flowchart" >&2
        return 1
    fi
}

# Capture Start Time
start_time=$(date +%s)

function main() {
    echo "Verifying prerequisites before documentation generation..." >&2

    # Check if required tools and files are present
    check_tools_and_files

    # Check if a folder name is provided as a command line argument
    if [ $# -eq 0 ]; then
        echo "Please provide a folder name as a command line argument" >&2
        exit 1
    fi

    folder_to_document="$1"
    docs_folder="doc_"$(basename "$folder_to_document")

    # Check if the folder to document exists
    if [ ! -d "$folder_to_document" ]; then
        echo "Folder $folder_to_document does not exist" >&2
        exit 1
    fi

    # Create a directory for the generated documentation if it doesn't exist
    if [ ! -d "$docs_folder" ]; then
        mkdir "$docs_folder"
    fi

    # Read the skip list from the CSV file
    read_skip_list
    
    # Define the path to the aggregated markdown file
    aggregated_md_file="$docs_folder/High_Level_Doc.md"

    # Clear existing aggregated markdown file if it exists
    [ -f "$aggregated_md_file" ] && > "$aggregated_md_file"

    # Use create_find_command to dynamically generate the find command with specified extensions
    module_files=$(eval $(create_find_command "$lang_csv" "$folder_to_document"))

    # Check if module_files is empty and display a warning if no files are found
    if [ -z "$module_files" ]; then
        echo "Warning: No files found for documentation generation." >&2
        return
    fi

    # Generate high-level documentation for each found module file
    for module_file in $module_files; do
        # Create documentation for the module, including flow chart
        create_module_documentation "$module_file" "$docs_folder"
    done
    
    # Aggregate individual markdown files into a main document
    echo "# Module Overview" > "$aggregated_md_file" 
    for md_file in "$docs_folder"/*_Doc.md; do
        if [ "$md_file" != "$aggregated_md_file" ]; then
            cat "$md_file" >> "$aggregated_md_file"
        fi
    done

    local introduction_and_summary=$(extract_module_details_and_call_bito "$aggregated_md_file" "$prompt_folder/system_introduction_prompt.txt")

    # Prepend the introduction and summary to the aggregated Markdown file
    local temp_file=$(mktemp)
    mv "$aggregated_md_file" "$temp_file"
    echo -e "# Introduction :\n" > "$aggregated_md_file"
    echo "$introduction_and_summary" >> "$aggregated_md_file"

    # Generate and append the system flow chart
    generate_flow_chart_for_system "$folder_to_document" "$docs_folder/flowmaps/system_flowchart.png"
    echo -e "\n# System Flowchart\n\n![System Flowchart](./flowmaps/system_flowchart.png)\n" >> "$aggregated_md_file"

    # Append the rest of the original aggregated content
    cat "$temp_file" >> "$aggregated_md_file"
    rm "$temp_file"

    # Log session duration and token usage
    log_token_usage_and_session_duration

    echo "Documentation generated in $docs_folder"
}

main "$@"
