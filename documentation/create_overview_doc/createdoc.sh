#!/bin/bash

# Log file for storing the token usage information
log_file="bito_usage_log.txt" 

# Directory containing prompt files for NLP tasks
prompt_folder="AI_Prompts"  

# Global variables for session token counts
total_input_token_count=0
total_output_token_count=0

# Update token usage function
function update_token_usage() {
    local input_content="$1"
    local output_content="$2"

    # Calculate word counts for input and output
    local input_word_count=$(echo "$input_content" | wc -w | tr -d ' ')
    local output_word_count=$(echo "$output_content" | wc -w | tr -d ' ')

    # Convert word counts to token counts using the approximation (1 word ≈ 1.3 tokens)
    local input_token_count=$(echo "$input_word_count * 1.34" | bc)
    local output_token_count=$(echo "$output_word_count * 1.34" | bc)

    # Update session token counts
    total_input_token_count=$(echo "$total_input_token_count + $input_token_count" | bc)
    total_output_token_count=$(echo "$total_output_token_count + $output_token_count" | bc)
}

# Function to log total token usage at the end of the session
function log_total_token_usage() {
    local log_file="$1" # Pass the log file path as an argument

    # Log the total token usage details to the log file
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "-----------------------------------------" | tee -a "$log_file"
    echo "$timestamp - Total Token Usage for Session" | tee -a "$log_file"
    echo "Total Input: Tokens = $total_input_token_count" | tee -a "$log_file"
    echo "Total Output: Tokens = $total_output_token_count" | tee -a "$log_file"
    echo "-----------------------------------------" | tee -a "$log_file"
}

# Ensure necessary tools and files are present
function check_tools_and_files() {
    echo "Checking required tools and files for documentation generation..." >&2
    local required_tools=("bito" "mmdc")
    local missing_tools=()

    # Check if each tool is installed
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done

    # Prompt files necessary for documentation generation
    local required_files=("high_level_doc_prompt.txt" "mermaid_doc_prompt.txt" "system_introduction_prompt.txt" "system_overview_mermaid_update_prompt.txt")
    for file in "${required_files[@]}"; do
        if [ ! -f "$prompt_folder/$file" ]; then
            echo -e "\nError: Missing required file: $prompt_folder/$file"
            exit 1
        fi
    done

    # Exit if any of the required tools are missing
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "\nError: The following tools are required but the path was not found:"
        for missing_tool in "${missing_tools[@]}"; do
            echo " - $missing_tool"
            # Provide specific installation instructions for installing missing tools
            if [ "$missing_tool" == "bito" ]; then
                echo "   Install Bito CLI on MAC and Linux with:"
                echo "   sudo curl https://alpha.bito.ai/downloads/cli/install.sh -fsSL | bash"
                echo "   On Archlinux, install with AUR helpers like yay or paru:"
                echo "   yay -S bito-cli or paru -S bito-cli"
                echo "   For Windows, download and install the MSI from Bito's website."
                echo "   Follow the instructions provided by the installer."
            elif [ "$missing_tool" == "mmdc" ]; then
                echo "   Install Mermaid CLI with npm:"
                echo "   npm install -g @mermaid-js/mermaid-cli"
            fi
        done
        echo "Exiting."
        exit 1
    fi
    echo -e "All required tools and files are present. Proceeding...\n" >&2
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

    # Extracting filename from the prompt file path for logging
    local filename=$(basename "$prompt_file_path")

    while [ $attempt -le $MAX_RETRIES ]; do
        # Informing about the start of a new attempt and the file being processed
        echo "Calling bito with retry logic. Attempt $attempt of $MAX_RETRIES with prompt file '$filename'..." >&2
        # Call bito and capture output
        output=$(echo -e "$input_text" | bito -p "$prompt_file_path")

        # Checking the output length
        if [[ $(echo "$output" | wc -w) -le 1 ]]; then
            # Output is insufficient, preparing for retry
            echo "Attempt $attempt: bito call for file '$filename' completed but returned insufficient content. Retrying in $RETRY_DELAY seconds..." >&2
            sleep $RETRY_DELAY
            ((attempt++))
        else
            # Successful execution with sufficient output
            echo "Attempt $attempt: Success! bito call for file '$filename' returned sufficient content." >&2
            echo "$output"
            # Optional: Update token usage or any other necessary housekeeping
            update_token_usage "$input_text" "$output"
            return 0
        fi
    done

    # All attempts failed, final error message
    echo "All $MAX_RETRIES attempts to call bito with prompt file '$filename' have failed to return adequate content. Exiting with error." >&2
    return 1
}

# Generate documentation for an individual module
function create_module_documentation() {
    local path_to_module="$1"
    local documentation_directory="$2"
    echo "Creating documentation for module: $path_to_module" >&2

    if is_skippable "$path_to_module"; then
        echo "Skipped $path_to_module as it's on the exclusion list."
        return
    fi
    
    local name_of_module=$(basename "$path_to_module")
    local content_of_module=$(<"$path_to_module")

    local high_level_documentation=$(call_bito_with_retry "Module: $name_of_module\n---\n$content_of_module" "$prompt_folder/high_level_doc_prompt.txt")
    if [ $? -ne 0 ]; then
        echo "High-level documentation creation failed for module: $name_of_module"
        return 1
    fi
    update_token_usage "$content_of_module" "$high_level_documentation"

    local mermaid_diagram=$(create_mermaid_diagram "$name_of_module" "$content_of_module")
    if [ $? -ne 0 ]; then
        echo "Mermaid diagram creation failed for module: $name_of_module"
        return 1
    fi

    local mdd_file="$documentation_directory/$name_of_module.mdd"
    if [ ! -s "$mdd_file" ]; then
        echo -e "$mermaid_diagram" > "$mdd_file"
    fi
    update_token_usage "$content_of_module" "$mermaid_diagram"

    local markdown_documentation_file="$documentation_directory/${name_of_module}_Doc.md"
    echo -e "## Module: $name_of_module\n$high_level_documentation" >> "$markdown_documentation_file"
    if [[ -n "$mermaid_diagram" && "$mermaid_diagram" =~ [^[:space:]] ]]; then 
        echo -e "## Mermaid Diagram\n\`\`\`mermaid\n$mermaid_diagram\n\`\`\`" >> "$markdown_documentation_file"
    fi 

    echo -e "Documentation saved to $markdown_documentation_file\n\n"
}

extract_module_names_and_associated_objectives_then_call_bito() {
    local filename=$1
    local prompt_file_path=$2
    local lines=()
    local current_module=""
    local current_objectives=""
    local capture_objectives=false
    local combined_output=""
    local attempt=1
    local MAX_RETRIES=5
    local RETRY_DELAY=10 # seconds
    local bito_output

    echo -e "Extracting module names and objectives from file: $filename\n" >&2

    # Read the file line by line into the array
    while IFS= read -r line; do
        lines+=("$line")
    done < "$filename"

    # Loop through the lines to process them
    for line in "${lines[@]}"; do
        if [[ $line =~ ^##\ Module:\ (.*) ]]; then
            if [[ -n $current_module ]]; then
                echo "Processing module: $current_module with objectives" >&2
                combined_output+="Module: $current_module\n---\nPrimary Objectives:\n$current_objectives\n\n"
            fi
            current_module=${BASH_REMATCH[1]}
            current_objectives=""
            capture_objectives=false
        elif [[ $line =~ ^-\ \*\*Primary\ Objectives\*\*: ]]; then
            capture_objectives=true
            current_objectives+=$(echo $line | sed 's/.*\*\*Primary Objectives\*\*: //')$'\n'
        elif $capture_objectives && [[ $line =~ ^-\ .+ ]]; then
            current_objectives+=$(echo $line | sed 's/^-\ //')$'\n'
        elif [[ $line == "## "* || $line == "" ]]; then
            capture_objectives=false
        fi
    done

    if [[ -n $current_module ]]; then
        echo "Processing module: $current_module with objectives" >&2
        combined_output+="Module: $current_module\n---\nPrimary Objectives:\n$current_objectives\n\n"
    fi

    # Retry logic for calling bito
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt: Running bito for module: $current_module" >&2
        bito_output=$(echo -e "$combined_output" | bito -p "$prompt_file_path")

        # Check if the output has more than one word
        if [[ $(echo "$bito_output" | wc -w) -le 1 ]]; then
            echo "Attempt $attempt: bito command for module: $current_module failed or did not return enough content. Retrying in $RETRY_DELAY seconds..." >&2
            sleep $RETRY_DELAY
            ((attempt++))
        else
            echo "Attempt $attempt: bito command for module: $current_module succeeded with sufficient content." >&2
            echo "$bito_output"
            # Update token usage
            update_token_usage "$combined_output" "$bito_output"
            return 0
        fi
    done

    echo "Failed to call bito for module: $current_module after $MAX_RETRIES attempts with adequate content." >&2
    return 1
}

# Function to fix Mermaid diagram syntax
fix_mermaid_syntax() {
    local mermaid_content="$1"
    local fixed_mermaid_content

    # Replace all occurrences of "()" with an empty string
    fixed_mermaid_content=$(echo "$mermaid_content" | sed 's/()//g')

    echo "$fixed_mermaid_content"
}

# Function to validate Mermaid diagram syntax
validate_mermaid_syntax() {
    local mermaid_content="$1"
    local temp_mmd_file=$(mktemp)

    # Write Mermaid content to a temporary file
    echo "$mermaid_content" > "$temp_mmd_file"

    # Attempt to parse the Mermaid diagram using mmdc
    local output=$(mmdc -i "$temp_mmd_file" -o /dev/null 2>&1)
    local status=$?

    # Clean up the temporary file
    rm "$temp_mmd_file"

    if [ $status -ne 0 ]; then
        echo "Mermaid syntax validation failed. Please check the diagram syntax." >&2
        echo "$output" >&2
        return 1
    fi
    return 0
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

        # Fix syntax in the Mermaid content
        mermaid_flow_map=$(fix_mermaid_syntax "$mermaid_flow_map")

        if [[ $(echo "$mermaid_flow_map" | wc -w) -gt 1 ]]; then
            # Validate Mermaid syntax
            if validate_mermaid_syntax "$mermaid_flow_map"; then
                # We have a valid mermaid diagram
                echo "$mermaid_flow_map"
                return 0
            else
                error_message+="Attempt $attempt: Mermaid syntax validation failed. Retrying in $RETRY_DELAY seconds...\n"
            fi
        else
            error_message+="Attempt $attempt: bito call for Mermaid diagram failed or returned insufficient content. Retrying in $RETRY_DELAY seconds...\n"
        fi
        sleep $RETRY_DELAY
        ((attempt++))
    done

    echo -e "$error_message"
    echo "Failed to create Mermaid diagram after $MAX_RETRIES attempts."
    return 1
}

generate_mdd_overview() {
    local dir="$1"
    local mermaid_doc_prompt_file="$prompt_folder/system_overview_mermaid_update_prompt.txt"
    local overview_mdd_file="$dir/overview.mdd"
    local temp_file
    local MAX_RETRIES=5
    local RETRY_DELAY=5 # seconds

    echo "Starting to generate overview.mdd..."

    # Read existing overview.mdd content
    local existing_overview_content=""
    if [ -f "$overview_mdd_file" ]; then
        existing_overview_content=$(cat "$overview_mdd_file")
    fi

    # Iterate over each .mdd file in the directory
    for mdd_file in "$dir"/*.mdd; do
        if [ -f "$mdd_file" ] && [ "$mdd_file" != "$overview_mdd_file" ]; then
            echo "Processing $mdd_file..."
            local mermaid_script=$(cat "$mdd_file")

            # Apply fix_mermaid_syntax to correct any syntax issues in the Mermaid script before processing
            mermaid_script=$(fix_mermaid_syntax "$mermaid_script")

            if [[ -n "$mermaid_script" ]]; then
                echo "Mermaid script found. Processing with bito..."

                local attempt=1
                while [ $attempt -le $MAX_RETRIES ]; do
                    echo "Attempt $attempt: Processing Mermaid script for $mdd_file" >&2
                    # Concatenate existing overview content with new Mermaid script
                    local combined_content="Previous content\n$existing_overview_content\nNew content to be added\n$mermaid_script"

                    # Use bito to process and update the overview
                    temp_file=$(mktemp)
                    echo -e "$combined_content" | bito -p "$mermaid_doc_prompt_file" > "$temp_file"

                    # Validate the Mermaid script
                    if validate_mermaid_syntax "$(cat "$temp_file")"; then
                        echo -e "Valid Mermaid diagram generated successfully for $mdd_file.\n" >&2
                        # Update the existing overview content with the processed content
                        existing_overview_content=$(cat "$temp_file")
                        rm "$temp_file"
                        # Delete the processed .mdd file
                        rm "$mdd_file"
                        # Update token usage
                        update_token_usage "$combined_content" "$existing_overview_content"
                        break
                    else
                        echo -e "Invalid Mermaid diagram syntax for attempt $attempt. Retrying...\n" >&2
                        rm "$temp_file"
                        sleep $RETRY_DELAY
                        ((attempt++))
                    fi
                done

                if [ $attempt -gt $MAX_RETRIES ]; then
                    echo "Failed to generate a valid Mermaid diagram for $mdd_file after $MAX_RETRIES attempts."
                    return 1
                fi
            else
                echo "No content found in $mdd_file"
            fi
        fi
    done

    # Save the updated content back to overview.mdd
    echo -e "$existing_overview_content" > "$overview_mdd_file"

    if [ ! -s "$overview_mdd_file" ]; then
        echo "Failed to create overview.mdd or the file is empty."
        return 1
    else
        echo "Mermaid overview generated successfully: $overview_mdd_file"
    fi
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
    echo "# Module Overview" > "$aggregated_md_file" 
    for md_file in "$docs_folder"/*_Doc.md; do
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

    # Call generate_mdd_overview function here, after all .mdd files are created
    generate_mdd_overview "$docs_folder" "$aggregated_md_file"
    
    # Append the content of overview.mdd to the aggregated file extracting only the Mermaid diagram block
    if [ -f "$docs_folder/overview.mdd" ]; then
        echo -e "\n# Full System Overview\n" >> "$aggregated_md_file"

        # Extract and append only the Mermaid diagram block
        awk '/^```mermaid$/,/^```$/' "$docs_folder/overview.mdd" >> "$aggregated_md_file"
    else
        echo "Overview file not found or empty."
    fi

    # Append the rest of the original aggregated content
    cat "$temp_file" >> "$aggregated_md_file"

    # Remove the temporary file
    rm "$temp_file"

    # Generate Mermaid diagrams for visual representations overwriting the markdown file with the diagrams
    generate_mermaid_diagram "$aggregated_md_file"

    # Finally, log the total token usage at the end of the script
    log_total_token_usage "$log_file"

    # Notify the user that the documentation has been generated
    echo "Documentation generated in $docs_folder"
}

main "$@"
