#!/bin/bash

log_file="bito_usage_log.txt"
prompt_folder="AI_Prompts"  # Specify the prompt folder here

function log_word_char_count() {
    local module_name="$1"
    local count_type="$2"
    local word_count="$3"
    local char_count="$4"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp - Module '$module_name' Count $count_type BitO CLI: Words: $word_count, Chars: $char_count" | tee -a "$log_file"
}

function check_tools_and_files() {
    local required_tools=("bito" "code2flow" "dot")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    local required_files=("high_level_docstrings_prompt.txt" "system_summary_prompt.txt" "system_understanding_sequence.txt" "enhance_system_context_prompt.txt" "refined_organized_markdown_prompt.txt" )
    for file in "${required_files[@]}"; do
        if [ ! -f "$prompt_folder/$file" ]; then
            echo "Error: Missing required file: $prompt_folder/$file"
            exit 1
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Error: The following tools are required but not installed:"
        for missing_tool in "${missing_tools[@]}"; do
            echo " - $missing_tool"
        done
        echo "Exiting."
        exit 1
    fi
}

is_skippable() {
  local path=$1
  
  local skip_dirs_files=("logs" "node_modules" "dist" "target" "bin" "package-lock.json" "data.json" "build" ".gradle" ".idea" "gradle" "extension.js" "vendor.js" "ngsw.json" "polyfills.js")

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

function aggregate_module_high_level_docstrings() {
    local module_path="$1"
    local module_name=$(basename "$module_path")
    local module_contents

    # Read module contents into a variable (more efficient than using 'cat')
    module_contents=$(<"$module_path")

    local high_level_docstrings=$(echo -e "Module: $module_name\n---\n$module_contents" | bito -p "$prompt_folder/high_level_docstrings_prompt.txt")

    if [ $? -eq 0 ]; then
        echo "$high_level_docstrings"
    else
        echo "Bito operation failed for module: $module_name"
        return 1
    fi
}

function generate_system_overview() {
    local aggregated_docstrings_file="$1"
    local aggregated_docstrings=$(cat "$aggregated_docstrings_file")
    local system_overview=$(echo -e "Aggregated Docstrings:\n---\n$aggregated_docstrings" | bito -p "$prompt_folder/system_summary_prompt.txt")

    if [ $? -eq 0 ]; then
        echo "$system_overview"
    else
        echo "Bito operation failed while generating system overview"
        return 1
    fi
}

function create_combined_context() {
    local aggregated_module_docstrings_file="$1"
    local system_overview_file="$2"
    local combined_context_file="$docs_folder/combined_context.txt"
    
    # Use 'cat' to concatenate files efficiently
    cat "$aggregated_module_docstrings_file" "$system_overview_file" > "$combined_context_file"

    echo "Combined context generated and saved in combined_context.txt"
}

function generate_refined_design_doc() {
    local input_file="$docs_folder/combined_context.txt"
    local output_file="$docs_folder/High_Level_Design.md"

    # Read the content of combined_context.txt
    local combined_content=$(<"$input_file")

    # Read prompt
    local prompt=$(<"$prompt_folder/refined_organized_markdown_prompt.txt")

    # Prepend the content of combined_context.txt to the prompt
    local combined_prompt="${combined_content}\n${prompt}"

    # Call BitO with combined prompt
    local refined_doc=$(echo -e "$combined_prompt" | bito)

    # Check if bito succeeded or failed
    if [ $? -ne 0 ]; then
        echo "Bito operation failed while generating refined design doc"
        return 1
    fi

    # Write refined doc to output file
    echo "$refined_doc" > "$output_file"
}

function main() {
    check_tools_and_files

    if [ $# -eq 0 ]; then
        echo "Please provide a folder name as a command line argument"
        exit 1
    fi

    folder_to_document="$1"
    docs_folder="$folder_to_document/doc_$folder_to_document"

    if [ ! -d "$folder_to_document" ]; then
        echo "Folder $folder_to_document does not exist"
        exit 1
    fi

    if [ ! -d "$docs_folder" ]; then
        mkdir "$docs_folder"
    fi

    aggregated_module_docstrings_file="$docs_folder/aggregated_module_docstrings.txt"
    touch "$aggregated_module_docstrings_file"
    
    # For Python, C, C++, Java, JavaScript, Go, Rust    
    module_files=$(find "$folder_to_document" -type f \( -name '*.py' -o -name '*.c' -o -name '*.cpp' -o -name '*.java' -o -name '*.js' -o -name '*.go' -o -name '*.rs' \))

    # Using an array to store the filtered files
    declare -a filtered_module_files=()
    
    for module_file in $module_files; do
        if ! is_skippable "$module_file"; then
            filtered_module_files+=("$module_file")
        fi
    done

    total_modules=${#filtered_module_files[@]}
    aggregated_module_count=0
    running_word_count=0
    running_char_count=0
    divider="=========================================================="

    for module_file in "${filtered_module_files[@]}"; do
        module_summary=$(aggregate_module_high_level_docstrings "$module_file")

        if [ $? -ne 0 ]; then
            echo "Exiting due to Bito operation failure."
            exit 1
        fi

        ((aggregated_module_count++))

        word_count=$(echo -e "$module_summary" | wc -w)
        char_count=$(echo -n "$module_summary" | wc -c)

        module_filename=$(basename "$module_file")

        running_word_count=$((running_word_count + word_count))
        running_char_count=$((running_char_count + char_count))

        echo "$divider"
        echo "Aggregated '$module_filename' (Words: $word_count, Chars: $char_count)"
        echo "$aggregated_module_count out of $total_modules modules"
        echo "Total Word Count: $running_word_count, Total Char Count: $running_char_count"
        echo "$divider"

        echo -e "$module_summary\n" >> "$aggregated_module_docstrings_file"
    done

    echo "Final word count of aggregated modules: $running_word_count"
    echo "Final char count of aggregated modules: $running_char_count"

    system_overview_file="$docs_folder/system_overview.txt"
    system_overview=$(generate_system_overview "$aggregated_module_docstrings_file")
    echo "$system_overview" > "$system_overview_file"

    create_combined_context "$aggregated_module_docstrings_file" "$system_overview_file"

    # Call function to generate refined doc
    generate_refined_design_doc "$docs_folder/combined_context.txt"
}

main "$@"
