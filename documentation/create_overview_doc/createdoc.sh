#!/bin/bash

log_file="bito_usage_log.txt" 
prompt_folder="AI_Prompts"  

function log_token_usage() {
    local module_name="$1"
    local input_content="$2"
    local output_content="$3"

    local input_word_count=$(echo "$input_content" | wc -w | tr -d ' ')
    local output_word_count=$(echo "$output_content" | wc -w | tr -d ' ')
    local total_word_count=$(( input_word_count + output_word_count ))

    local input_char_count=$(echo "$input_content" | wc -c | tr -d ' ')
    local output_char_count=$(echo "$output_content" | wc -c | tr -d ' ')
    local total_char_count=$(( input_char_count + output_char_count ))

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "-----------------------------------------" | tee -a "$log_file"
    echo "$timestamp - Token Usage for Module: '$module_name'" | tee -a "$log_file"
    echo "Input: Words = $input_word_count, Chars = $input_char_count" | tee -a "$log_file"
    echo "Output: Words = $output_word_count, Chars = $output_char_count" | tee -a "$log_file"
    echo "Total: Words = $total_word_count, Chars = $total_char_count" | tee -a "$log_file"
    echo "-----------------------------------------" | tee -a "$log_file"
}

function check_tools_and_files() {
    local required_tools=("bito" "code2flow" "dot")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    local required_files=("high_level_doc_prompt.txt")
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

function generate_individual_module_md() {
    local module_path="$1"
    local docs_folder="$2"
    
    if is_skippable "$module_path"; then
        echo "Skipped $module_path as it's in the skippable list."
        return
    fi
    
    local module_name=$(basename "$module_path")
    local module_contents=$(<"$module_path")

    local high_level_doc=$(echo -e "Module: $module_name\n---\n$module_contents" | bito -p "$prompt_folder/high_level_doc_prompt.txt")

    # Log token usage for both input and output
    log_token_usage "$module_name" "$module_contents" "$high_level_doc"

    if [ $? -eq 0 ]; then
        local module_md_file="$docs_folder/${module_name}_High_Level_Doc.md"
        echo -e "## Module: $module_name\n$high_level_doc" > "$module_md_file"
        echo "Saved module doc to $module_md_file"
    else
        echo "Bito operation failed for module: $module_name"
        return 1
    fi
}

generate_flow_map() {
    local folder_to_document=$1
    local flow_map_file=$2
    local lang_option=$3

    local file_extension
    case $lang_option in
        "py") file_extension="*.py" ;;      
        "js") file_extension="*.js" ;;      
        "ruby") file_extension="*.rb" ;;    
        "php") file_extension="*.php" ;;    
        *) file_extension="*.*" ;;  
    esac

    local files_to_process=($(find "$folder_to_document" -type f -name "$file_extension"))

    if [[ ${#files_to_process[@]} -eq 0 ]]; then
        echo "Warning: No files found for the language: $lang_option in $folder_to_document"
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
    docs_folder="doc_"$(basename "$folder_to_document")

    if [ ! -d "$folder_to_document" ]; then
        echo "Folder $folder_to_document does not exist"
        exit 1
    fi

    if [ ! -d "$docs_folder" ]; then
        mkdir "$docs_folder"
    fi

    aggregated_md_file="$docs_folder/Aggregated_High_Level_Doc.md"
    if [ -f "$aggregated_md_file" ]; then
        > "$aggregated_md_file"
    fi

    module_files=$(find "$folder_to_document" -type f \( -name '*.py' -o -name '*.c' -o -name '*.cpp' -o -name '*.java' -o -name '*.js' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.php' \))

    for module_file in $module_files; do
        generate_individual_module_md "$module_file" "$docs_folder"
    done
    
    # Aggregate individual md files
    echo "# Full System Overview" > "$aggregated_md_file" 
    for md_file in "$docs_folder"/*_High_Level_Doc.md; do
        if [ "$md_file" != "$aggregated_md_file" ]; then
            cat "$md_file" >> "$aggregated_md_file"
        fi
    done

    local languages="py js ruby php"
    for lang in $languages; do
        local flow_map_file="$docs_folder/flow_map_${lang}.png"
        local flow_map_gv_file="$docs_folder/flow_map_${lang}.gv"
        generate_flow_map "$folder_to_document" "$flow_map_gv_file" "$lang"
        if [ -f "$flow_map_gv_file" ]; then
            # Generate flow map PNG file from .gv file
            dot -Tpng "$flow_map_gv_file" -o "$flow_map_file"

            echo -e "\n\n## Flow Map ($lang)\n" >> "$aggregated_md_file"
            echo -e "![Flow Map ($lang)](flow_map_${lang}.png)\n" >> "$aggregated_md_file"
            
            # Perform Bito operation for system summary and append to aggregated_md_file
            system_summary_prompt="$prompt_folder/system_summary_prompt.txt"
            bito_output=$(cat "$system_summary_prompt" "$flow_map_gv_file" | bito -p "$system_summary_prompt")

            # Append the Bito output to the aggregated high-level documentation file
            echo -e "\n\n## System Summary\n" >> "$aggregated_md_file"
            echo -e "$bito_output" >> "$aggregated_md_file"
        fi
    done

    echo "Documentation generated in $docs_folder"
}

main "$@"
