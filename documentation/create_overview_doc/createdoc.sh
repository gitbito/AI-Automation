#!/bin/bash

# Log file for storing the token usage information
log_file="bito_usage_log.txt" 

# Directory containing prompt files for NLP tasks
prompt_folder="AI_Prompts"  

# Log token usage function
function log_token_usage() {
    local module_name="$1"
    local input_content="$2"
    local output_content="$3"

    # Calculate word and char counts for input and output
    local input_word_count=$(echo "$input_content" | wc -w | tr -d ' ')
    local output_word_count=$(echo "$output_content" | wc -w | tr -d ' ')
    local total_word_count=$(( input_word_count + output_word_count ))

    local input_char_count=$(echo "$input_content" | wc -c | tr -d ' ')
    local output_char_count=$(echo "$output_content" | wc -c | tr -d ' ')
    local total_char_count=$(( input_char_count + output_char_count ))

    # Log the token usage details to the log file
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "-----------------------------------------" | tee -a "$log_file"
    echo "$timestamp - Token Usage for Module: '$module_name'" | tee -a "$log_file"
    echo "Input: Words = $input_word_count, Chars = $input_char_count" | tee -a "$log_file"
    echo "Output: Words = $output_word_count, Chars = $output_char_count" | tee -a "$log_file"
    echo "Total: Words = $total_word_count, Chars = $total_char_count" | tee -a "$log_file"
    echo "-----------------------------------------" | tee -a "$log_file"
}

# Ensure necessary tools and files are present
function check_tools_and_files() {
    # Tools required for this script
    local required_tools=("bito" "code2flow" "dot")
    local missing_tools=()

    # Check if each tool is installed
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    # Prompt files necessary for documentation generation
    local required_files=("high_level_doc_prompt.txt" "system_summary_prompt.txt")
    for file in "${required_files[@]}"; do
        if [ ! -f "$prompt_folder/$file" ]; then
            echo "Error: Missing required file: $prompt_folder/$file"
            exit 1
        fi
    done

    # Exit if any of the required tools are missing
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Error: The following tools are required but not installed:"
        for missing_tool in "${missing_tools[@]}"; do
            echo " - $missing_tool"
        done
        echo "Exiting."
        exit 1
    fi
}

# Function to check if a path should be skipped based on predefined patterns
is_skippable() {
  local path=$1

  # List of directories/files to skip
  local skip_dirs_files=("logs" "node_modules" "dist" "target" "bin" "package-lock.json" "data.json" "build" ".gradle" ".idea" "gradle" "extension.js" "vendor.js" "ngsw.json" "polyfills.js" "init")
  
  for skip_item in "${skip_dirs_files[@]}"; do
    if [[ "$path" == *"$skip_item"* ]]; then
      return 0
    fi
  done

  # Skip hidden files (files starting with a dot)
  if [[ $(basename "$path") == .* ]]; then
    return 0
  fi

  return 1
}

# Generate documentation for an individual module
function generate_individual_module_md() {
    local module_path="$1"
    local docs_folder="$2"
    
    # Skip predefined patterns
    if is_skippable "$module_path"; then
        echo "Skipped $module_path as it's in the skippable list."
        return
    fi
    
    local module_name=$(basename "$module_path")
    local module_contents=$(<"$module_path")

    # Generate high-level documentation using bito
    local high_level_doc=$(echo -e "Module: $module_name\n---\n$module_contents" | bito -p "$prompt_folder/high_level_doc_prompt.txt")

    # Log token usage for both input and output
    log_token_usage "$module_name" "$module_contents" "$high_level_doc"

    # Save the high-level documentation to a markdown file
    if [ $? -eq 0 ]; then
        local module_md_file="$docs_folder/${module_name}_High_Level_Doc.md"
        echo -e "## Module: $module_name\n$high_level_doc" > "$module_md_file"
        echo "Saved module doc to $module_md_file"
    else
        echo "Bito operation failed for module: $module_name"
        return 1
    fi
}

# Generate a flow map for codebase using code2flow
generate_flow_map() {
    local folder_to_document=$1
    local flow_map_file=$2
    local lang_option=$3

    # Determine the file extension based on the language option
    local file_extension
    case $lang_option in
        "py") file_extension="*.py" ;;      
        "js") file_extension="*.js" ;;      
        "ruby") file_extension="*.rb" ;;    
        "php") file_extension="*.php" ;;    
        *) file_extension="*.*" ;;  
    esac

    # Find all the files with the specified extension
    local files_to_process=($(find "$folder_to_document" -type f -name "$file_extension"))

    # Generate the flow map
    code2flow --output "$flow_map_file" --language "$lang_option" "${files_to_process[@]}" --quiet
}

function main() {
    # Check if required tools and files are present
    check_tools_and_files

    # Check if a folder name is provided as an argument
    if [ $# -eq 0 ]; then
        echo "Please provide a folder name as a command line argument"
        exit 1
    fi

    folder_to_document="$1"
    docs_folder="doc_"$(basename "$folder_to_document")

    # Check if the folder to document exists
    if [ ! -d "$folder_to_document" ]; then
        echo "Folder $folder_to_document does not exist"
        exit 1
    fi

    # Create a directory for the generated documentation if it doesn't exist
    if [ ! -d "$docs_folder" ]; then
        mkdir "$docs_folder"
    fi

    # Define the path to the aggregated markdown file
    aggregated_md_file="$docs_folder/Aggregated_High_Level_Doc.md"

    # Clear existing aggregated markdown file if it exists
    if [ -f "$aggregated_md_file" ]; then
        > "$aggregated_md_file"
    fi

    # Find all module files with the specified extensions in the provided folder
    module_files=$(find "$folder_to_document" -type f \( -name '*.py' -o -name '*.c' -o -name '*.cpp' -o -name '*.java' -o -name '*.js' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.php' \))

    # Generate high-level documentation for each found module file
    for module_file in $module_files; do
        generate_individual_module_md "$module_file" "$docs_folder"
    done
    
    # Aggregate individual markdown files into a main document
    echo "# Full System Overview" > "$aggregated_md_file" 
    for md_file in "$docs_folder"/*_High_Level_Doc.md; do
        if [ "$md_file" != "$aggregated_md_file" ]; then
            cat "$md_file" >> "$aggregated_md_file"
        fi
    done

    # Define the programming languages for which flow maps are to be generated
    local languages="py js ruby php"
    for lang in $languages; do
        # Define paths to the flow map image and dot graph files
        local flow_map_file="$docs_folder/flow_map_${lang}.png"
        local flow_map_gv_file="$docs_folder/flow_map_${lang}.gv"

        # Generate flow map dot graph file for the given language
        generate_flow_map "$folder_to_document" "$flow_map_gv_file" "$lang"
        
        if [ -f "$flow_map_gv_file" ]; then
            # Convert the dot graph file to an image using the dot tool
            dot -Tpng "$flow_map_gv_file" -o "$flow_map_file"

            # Append the generated flow map image to the aggregated markdown file
            echo -e "\n\n## Flow Map ($lang)\n" >> "$aggregated_md_file"
            echo -e "![Flow Map ($lang)](flow_map_${lang}.png)\n" >> "$aggregated_md_file"
            
            # Generate a system summary using Bito and append to the markdown file
            system_summary_prompt="$prompt_folder/system_summary_prompt.txt"
            bito_output=$(cat "$system_summary_prompt" "$flow_map_gv_file" | bito -p "$system_summary_prompt")

            # Append the Bito output to the aggregated high-level documentation file
            echo -e "\n\n## System Summary\n" >> "$aggregated_md_file"
            echo -e "$bito_output" >> "$aggregated_md_file"
        fi
    done

    # Notify the user that the documentation has been generated
    echo "Documentation generated in $docs_folder"
}

main "$@"
