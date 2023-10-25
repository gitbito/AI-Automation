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

    local required_files=("high_level_docstrings_prompt.txt" "system_summary_prompt.txt" "refined_organized_markdown_prompt.txt" )
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
  
  local skip_dirs_files=("logs" "node_modules" "dist" "target" "bin" "package-lock.json" "data.json" "build" ".gradle" ".idea" "gradle" "extension.js" "vendor.js" "ngsw.json" "polyfills.js" "init")

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
    
    if is_skippable "$module_path"; then
        echo "Skipped $module_path as it's in the skippable list."
        return
    fi
    
    local module_name=$(basename "$module_path")
    local module_contents

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

generate_flow_map() {
    local module=$1
    local flow_map_file=$2
    local lang_option=$3

    echo -e "\n---- Generating code flow map for files in $module using language: $lang_option ----"

    local file_extension
    case $lang_option in
        "py") file_extension="*.py" ;;
        "js") file_extension="*.js" ;;
        # Add other cases as needed
        *) file_extension="*.*" ;;  # Default
    esac

    local files_to_process=($(find "$module" -type f -name "$file_extension"))

    # Debugging step to print the files you're about to process
    echo "Files to process with code2flow: ${files_to_process[@]}"

    if [[ ${#files_to_process[@]} -eq 0 ]]; then
        echo "Warning: No files found for the language: $lang_option in $module"
        return 1
    fi

    code2flow --output "$flow_map_file" --language "$lang_option" "${files_to_process[@]}" --quiet
}

function main() {
    check_tools_and_files

    if [ $# -eq 0 ]; then
        echo "Please provide a folder name as a command line argument"
        exit 1
    fi

    folder_to_document="$1"
    # docs_folder="$folder_to_document/doc_$folder_to_document"
    docs_folder="doc_"$(basename "$folder_to_document")
    
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

    total_modules=0
    for module_file in $module_files; do
        if ! is_skippable "$module_file"; then
            ((total_modules++))
        fi
    done

    aggregated_module_count=0
    running_word_count=0
    running_char_count=0
    divider="=========================================================="

    for module_file in $module_files; do
        if is_skippable "$module_file"; then
            continue  # Skip the current iteration and move to the next file
        fi

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

    # [The rest of your function remains unchanged.]

    system_overview_file="$docs_folder/system_overview.txt"
    system_overview=$(generate_system_overview "$aggregated_module_docstrings_file")
    echo "$system_overview" > "$system_overview_file"

    create_combined_context "$aggregated_module_docstrings_file" "$system_overview_file"

    generate_refined_design_doc "$docs_folder/combined_context.txt"

    local languages="py js"
    for lang in $languages; do
        local file_extension
        case $lang in
            "py") file_extension="*.py" ;;
            "js") file_extension="*.js" ;;
            *) file_extension="*.*" ;;  # Default
        esac

        capitalized_lang=$(echo "$lang" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
        if [[ $(find "$folder_to_document" -type f -name "$file_extension") ]]; then
            flow_map_file="$docs_folder/flow_map_${lang}.png"
            generate_flow_map "$folder_to_document" "$flow_map_file" "$lang"
            
            echo -e "\n\n## Flow Map ($capitalized_lang)\n" >> "$docs_folder/High_Level_Design.md"
            echo -e "![Flow Map ($capitalized_lang)](flow_map_${lang}.png)\n" >> "$docs_folder/High_Level_Design.md"
        fi
    done
}

main "$@"
