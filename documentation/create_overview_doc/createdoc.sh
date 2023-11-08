#!/bin/bash

# Log file for storing the token usage information
log_file="bito_usage_log.txt" 

# Directory containing prompt files for NLP tasks
prompt_folder="AI_Prompts"  

# Detect languages available in the directory 
# This function detects the programming languages available in the directory to be documented and returns a space-separated string of the languages found.
# These are the languages for which flow maps will be generated using code2flow
detect_languages_compatible_with_code2flow() {
    local folder_to_scan=$1
    local detected_languages=()

    # Add to detected_languages if files with the extension are found
    [[ $(find "$folder_to_scan" -type f -name '*.py' | wc -l) -ne 0 ]] && detected_languages+=("py")
    [[ $(find "$folder_to_scan" -type f -name '*.js' | wc -l) -ne 0 ]] && detected_languages+=("js")
    [[ $(find "$folder_to_scan" -type f -name '*.rb' | wc -l) -ne 0 ]] && detected_languages+=("ruby")
    [[ $(find "$folder_to_scan" -type f -name '*.php' | wc -l) -ne 0 ]] && detected_languages+=("php")

    echo "${detected_languages[@]}"
}

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
    local required_files=("high_level_doc_prompt.txt" "mermaid_doc_prompt.txt" "system_introduction_prompt.txt")
    for file in "${required_files[@]}"; do
        if [ ! -f "$prompt_folder/$file" ]; then
            echo "Error: Missing required file: $prompt_folder/$file"
            exit 1
        fi
    done

    # Exit if any of the required tools are missing
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "Error: The following tools are required but the path was not found:"
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
  local skip_dirs_files=("logs" "node_modules" "dist" "target" "bin" "package-lock.json" "data.json" "build" ".gradle" ".idea" "gradle" "extension.js" "vendor.js" "ngsw.json" "polyfills.js" "init" ".gv")
  
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

# Function to call bito with retry logic
call_bito_with_retry() {
    local input_text=$1
    local prompt_file_path=$2
    local attempt=1
    local output
    local MAX_RETRIES=5
    local RETRY_DELAY=10 # Define this with the appropriate delay in seconds

    while [ $attempt -le $MAX_RETRIES ]; do
        # Log status message to stderr to avoid mixing with actual output
        echo "Attempt $attempt: Running bito..." >&2

        # Call bito and capture output
        output=$(echo -e "$input_text" | bito -p "$prompt_file_path")
        
        # Check if the output has more than one word
        if [[ $(echo "$output" | wc -w) -le 1 ]]; then
            # Log error message to stderr
            echo "Attempt $attempt: bito command failed or did not return enough content. Retrying in $RETRY_DELAY seconds..." >&2
            sleep $RETRY_DELAY
            ((attempt++))
        else
            # Log success message to stderr and output the actual content to stdout
            echo "Attempt $attempt: bito command succeeded with sufficient content." >&2
            echo "$output"
            return 0
        fi
    done

    # Log final error message to stderr
    echo "Failed to call bito after $MAX_RETRIES attempts with adequate content." >&2
    return 1
}

# Generate documentation for an individual module
function create_module_documentation() {
    local path_to_module="$1"
    local documentation_directory="$2"
    
    # Skip predefined patterns
    if is_skippable "$path_to_module"; then
        echo "Skipped $path_to_module as it's on the exclusion list."
        return
    fi
    
    local name_of_module=$(basename "$path_to_module")
    local content_of_module=$(<"$path_to_module")

    # Create high-level documentation using bito with retry logic
    local high_level_documentation=$(call_bito_with_retry "Module: $name_of_module\n---\n$content_of_module" "$prompt_folder/high_level_doc_prompt.txt")
    if [ $? -ne 0 ]; then
        echo "High-level documentation creation failed for module: $name_of_module"
        return 1
    fi

    # Record the number of tokens used for the documentation
    log_token_usage "$name_of_module" "$content_of_module" "$high_level_documentation"

    # Create a Mermaid diagram for the module
    local mermaid_diagram=$(create_mermaid_diagram "$name_of_module" "$content_of_module")
    if [ $? -ne 0 ]; then
        echo "Mermaid diagram creation failed for module: $name_of_module"
        return 1
    fi
    
    # Record the number of tokens used for the Mermaid diagram
    log_token_usage "$name_of_module" "$content_of_module" "$mermaid_diagram"

    # Write both pieces of documentation to a Markdown file
    local markdown_documentation_file="$documentation_directory/${name_of_module}_Documentation.md"
    echo -e "## Module: $name_of_module\n$high_level_documentation" >> "$markdown_documentation_file"
    
    # Ensure that the Mermaid diagram is not empty or just whitespace
    if [[ -n "$mermaid_diagram" && "$mermaid_diagram" =~ [^[:space:]] ]]; then 
        # Add the Mermaid diagram to the Markdown file
        echo -e "## Mermaid Diagram\n\`\`\`mermaid\n$mermaid_diagram\n\`\`\`" >> "$markdown_documentation_file"
    fi 
    
    echo "Documentation saved to $markdown_documentation_file"
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
    code2flow --output "$flow_map_file" --language "$lang_option" "${files_to_process[@]}" --quiet --hide-legend
}

# Generates Mermaid diagrams from a markdown file, replacing Mermaid code blocks with the generated diagrams.
generate_mermaid_diagram() {
    local md_file="$1"
    # Strip the .md extension if present and then append it back to ensure correctness
    local md_file_base="${md_file%.md}"

    if command -v mmdc >/dev/null 2>&1; then
        echo "Generating Mermaid diagrams in markdown file..."
        # Overwrite the markdown file with the generated diagram references
        mmdc -i "${md_file_base}.md" -o "${md_file_base}.md" && echo "Mermaid diagrams updated in ${md_file_base}.md" || echo "Failed to update diagrams."
    else
        echo "Mermaid CLI not found; skipping diagram generation."
    fi
}

create_mermaid_diagram() {
    local module_name="$1"
    local module_contents="$2"
    local mermaid_definition="flowchart\n$module_contents"
    local mermaid_flow_map
    local attempt=1
    local MAX_RETRIES=10
    local RETRY_DELAY=5 # seconds
    local error_message=""

    while [ $attempt -le $MAX_RETRIES ]; do
        local full_output=$(echo -e "Module: $module_name\n---\n$mermaid_definition" | bito -p "$prompt_folder/mermaid_doc_prompt.txt")

        mermaid_flow_map=$(echo "$full_output" | awk '/^```mermaid$/,/^```$/{if (!/^```mermaid$/ && !/^```$/) print}')

        if [[ $(echo "$mermaid_flow_map" | wc -w) -gt 1 ]]; then
            # We have a valid mermaid diagram
            echo "$mermaid_flow_map"
            return 0
        else
            error_message+="Attempt $attempt: bito call for Mermaid diagram failed or returned insufficient content. Retrying in $RETRY_DELAY seconds...\n"
            sleep $RETRY_DELAY
            ((attempt++))
        fi
    done

    echo -e "$error_message"
    echo "Failed to create Mermaid diagram after $MAX_RETRIES attempts."
    return 1
}

extract_module_names_and_associated_objectives_then_call_bito() {
  local filename=$1
  local lines=()
  local current_module=""
  local current_objectives=""
  local capture_objectives=false
  local output=""

  # Read the file line by line into the array
  while IFS= read -r line; do
    lines+=("$line")
  done < "$filename"

  # Loop through the lines to process them
  for line in "${lines[@]}"; do
    if [[ $line =~ ^##\ Module:\ (.*) ]]; then
      # If we hit a new Module, process the previous one if it exists
      if [[ -n $current_module && -n $current_objectives ]]; then
        # Combine the module name with its objectives
        output+="Module: $current_module\n---\nPrimary Objectives:\n$current_objectives\n\n"
      fi
      # Save the module name from the capture group
      current_module=${BASH_REMATCH[1]}
      # Reset the current objectives
      current_objectives=""
      capture_objectives=false
    elif [[ $line =~ ^-\ \*\*Primary\ Objectives\*\*: ]]; then
      capture_objectives=true
      # Extract objectives starting after the colon and space
      current_objectives+=$(echo $line | sed 's/.*\*\*Primary Objectives\*\*: //')$'\n'
    elif $capture_objectives && [[ $line =~ ^-\ .+ ]]; then
      # If we're capturing objectives, keep appending them until we hit another section
      current_objectives+=$(echo $line | sed 's/^-\ //')$'\n'
    elif [[ $line == "## "* || $line == "" ]]; then
      # Stop capturing objectives if we hit the next section or an empty line
      capture_objectives=false
    fi
  done

  # Don't forget to process the last module if it exists
  if [[ -n $current_module && -n $current_objectives ]]; then
    output+="Module: $current_module\n---\nPrimary Objectives:\n$current_objectives\n\n"
  fi

  # Call bito with the final output and the system introduction prompt
  echo -e "$output" | bito -p "$2"
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
    aggregated_md_file="$docs_folder/High_Level_Doc.md"

    # Clear existing aggregated markdown file if it exists
    if [ -f "$aggregated_md_file" ]; then
        > "$aggregated_md_file"
    fi

    # Find all module files with the specified extensions in the provided folder
    module_files=$(find "$folder_to_document" -type f \( -name '*.py' -o -name '*.c' -o -name '*.cpp' -o -name '*.java' -o -name '*.js' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.php' -o -name '*.sh' \))
    # Generate high-level documentation for each found module file
    for module_file in $module_files; do
        # generate_individual_module_md "$module_file" "$docs_folder"
        create_module_documentation "$module_file" "$docs_folder"
    done
    
    # Aggregate individual markdown files into a main document
    echo "# Full System Overview" > "$aggregated_md_file" 
    # for md_file in "$docs_folder"/*_High_Level_Doc.md; do
    for md_file in "$docs_folder"/*_Documentation.md; do
        if [ "$md_file" != "$aggregated_md_file" ]; then
            cat "$md_file" >> "$aggregated_md_file"
        fi
    done

    # Extract content and call Bito for a system introduction and summary
    local introduction_and_summary=$(extract_module_names_and_associated_objectives_then_call_bito "$aggregated_md_file" "$prompt_folder/system_introduction_prompt.txt")

    # Prepend the introduction and summary to the aggregated markdown file
    # Save the current content of the aggregated file temporarily
    local temp_file=$(mktemp)
    mv "$aggregated_md_file" "$temp_file"

    # Create a new aggregated file starting with the Markdown-formatted introduction title
    echo -e "# Introduction :\n" > "$aggregated_md_file"

    # Append the introduction and summary
    echo "$introduction_and_summary" >> "$aggregated_md_file"

    # Append the rest of the original aggregated content
    cat "$temp_file" >> "$aggregated_md_file"

    # Remove the temporary file
    rm "$temp_file"
    
    # Define the programming languages for which flow maps are to be generated
    local languages=$(detect_languages_compatible_with_code2flow "$folder_to_document")
    echo "Detected languages: $(detect_languages_compatible_with_code2flow "$folder_to_document")"

    for lang in $languages; do
        # Define paths to the flow map image and dot graph files
        local flow_map_file="$docs_folder/flow_map_${lang}.png"
        local flow_map_gv_file="$docs_folder/flow_map_${lang}.gv"

        # Generate flow map dot graph file for the given language
        generate_flow_map "$folder_to_document" "$flow_map_gv_file" "$lang"
        
        if [ -f "$flow_map_gv_file" ]; then
            # Convert the dot graph file to an image using the dot tool
            dot -Tpng "$flow_map_gv_file" -o "$flow_map_file"

            # Only append the markdown link if the image was successfully created
            if [ -f "$flow_map_file" ]; then
                # Append the generated flow map image to the aggregated markdown file
                echo -e "\n\n## Full System Flow Map ($lang)\n" >> "$aggregated_md_file"
                echo -e "![Flow Map ($lang)](flow_map_${lang}.png)\n" >> "$aggregated_md_file"
            fi
        else
            echo "Failed to generate flow map for $lang."
        fi
    done

    # Generate Mermaid diagrams for visual representations overwriting the markdown file with the diagrams
    generate_mermaid_diagram "$aggregated_md_file"

    # Notify the user that the documentation has been generated
    echo "Documentation generated in $docs_folder"
}

main "$@"
