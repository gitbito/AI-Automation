#!/bin/bash

######### SCRIPT PURPOSE: 

# This script automates the generation of documentation for a codebase, including module overviews and a codebase overview.
# It extracts docstrings, file summaries, and code flow diagrams from Python and JavaScript files within the codebase.
# The documentation is generated using tools like Bito, Code2Flow, Graphviz, and jq.
# You can specify whether you want documentation for the entire codebase or individual modules using the codebase flag.

######### CONSTANTS: File type constants for Python and JS.
PYTHON_FILES="*.py"
JS_FILES="*.js"

######### UTILITY FUNCTIONS: Check for tools, copy directory structure, check for hidden directories, etc. 

# Checks if required CLI tools are installed and exits if not
check_tools() {
  local tools=("bito" "code2flow" "dot" "jq")  # Added 'dot' for Graphviz and 'jq' for parsing JSON
  local missing_tools=()

  for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
      missing_tools+=("$tool")
    fi
  done

  if [ ${#missing_tools[@]} -ne 0 ]; then
    echo "Error: The following tools are required but not installed:"
    for tool in "${missing_tools[@]}"; do
      echo " - $tool"
    done
    echo "Exiting."
    exit 1
  fi
}

# Function to recursively copy a directory structure excluding hidden directories
# $1 is source folder, $2 is destination folder
copy_dir_structure() {
  local src=$1
  # local dest="doc_$2" 

  local filename=${2##*/}
  local dest="doc_$filename"

  # Create destination folder if it doesn't exist
  mkdir -p "$dest"
  echo -e "\n---- Copying directory structure from $src to $dest ----"

  # Get the relative paths of all directories in the source, excluding hidden directories
  find "$src" -mindepth 1 -type d -not -path '*/\.*' | sed "s|^$src/||" | while read -r dir; do
    # Only create the corresponding directory in the destination if it exists in the source
    if [ -d "$src/$dir" ]; then
      mkdir -p "$dest/$dir"
    fi
  done
}

# Function to check if a directory is hidden
is_hidden_dir() {
  local dir_name=$(basename "$1")
  if [[ $dir_name == .* ]]; then
    return 0
  else
    return 1
  fi
}

# This function generates the JSON output using the code2flow tool.
# It is used for generating the code flow from the source code.
# The generated JSON output provides an abstract representation of the code flow.
# Depending on the input, it either scans files within a directory or a single file.
generate_json_output() {
  local module=$1
  local json_output_file=$2
  local lang_option=$3

  echo -e "\n---- Generating code flow JSON output for files in $module using language: $lang_option ----"

  # Check if $module is a directory or a file and then generate the code2flow JSON output.
  if [[ -d "$module" ]]; then
    code2flow --output "$json_output_file" --language "$lang_option" "$module"/*.py "$module"/*.js
  elif [[ -f "$module" ]]; then
    code2flow --output "$json_output_file" --language "$lang_option" "$module"
  fi
}

# Function: generate_code_flow_diagrams
# Generates code flow diagrams for the provided module using code2flow.
generate_flow_map() {
  local module=$1
  local flow_map_file=$2
  local lang_option=$3

  echo -e "\n---- Generating code flow map for files in $module using language: $lang_option ----"

  # Check if $module is a directory or a file and then generate the code2flow flow map.
  if [[ -d "$module" ]]; then
    code2flow --output "$flow_map_file" --language "$lang_option" "$module"/*.py "$module"/*.js
  elif [[ -f "$module" ]]; then
    code2flow --output "$flow_map_file" --language "$lang_option" "$module"
  fi
}

######### DOCUMENTATION EXTRACTION: Extracts Python and JS docstrings.

# Function to extract Python docstrings
extract_python_docstrings() {
  awk '/^\s*\"\"\"/ {if (in_doc) {print "```"; in_doc=0} else {print "```python"; in_doc=1}} in_doc' "$1"
}

# Function to extract JavaScript docstrings   
extract_js_docstrings() {
  awk '/^\s*(\/\*\*|\/\/\*\*)/ {if (in_doc) {print "```"; in_doc=0} else {print "```js"; in_doc=1}} in_doc' "$1"
}

# Function to Extract docstrings from a file or directory based on the file extension. Calls extract_python_docstrings() or extract_js_docstrings() based on the extension.
extract_docstrings() {
  if [[ "$1" == $PYTHON_FILES ]]; then
    extract_python_docstrings "$1" 
  elif [[ "$1" == $JS_FILES ]]; then 
    extract_js_docstrings "$1"
  fi
}

######### AGGREGATION: Aggregates documentation, directory structures, file summaries, and docstrings.

# Generates a file summary for each file in a module using the bito CLI.
# Aggregates the summaries into a single string.
aggregate_file_summaries() {
  local module=$1
  local prompt_file=$2
  local summaries=""
  find "$module" -type f \( -name $PYTHON_FILES -o -name $JS_FILES \) -not -path '*/\.*' | while read file; do
    # Use bito CLI to generate file summary for each file
    file_summary=$(cat "$file" | bito -p "$prompt_file")
    echo "File: $file"
    echo "Bito Output: $file_summary"
    summaries+="### $(basename "${file%.*}")\n\n$file_summary\n\n---\n"
  done
  echo "$summaries"
}

# Function: generate_module_overview
# Aggregates documentation, directory structures, file summaries, and docstrings
# into a markdown file for the module overview.
generate_module_overview() {
  local module=$1
  local doc_folder=$2
  local is_codebase=$3  # Add an additional parameter for codebase overview generation

  # Skip hidden directories as they are typically not part of the main code.
  if is_hidden_dir "$module"; then
    echo "Skipping hidden directory: $module"
    return
  fi

  # Extract and store the docstrings from the code.
  local docstrings=$(extract_docstrings "$module")
  local module_name=$(basename "$module")

  # Create an overview markdown file and write the module overview and docstrings to it.
  local overview_file="$doc_folder/overview.md"
  echo "## $module_name Overview" > "$overview_file"
  echo -e "$docstrings" >> "$overview_file"

  # Aggregate summaries from each file within the module.
  local summaries=$(aggregate_file_summaries "$module" "docprmt.txt")
  echo -e "$summaries" >> "$overview_file"

  if [ "$is_codebase" != "true" ]; then
    # Identify the programming language of the module for code2flow.
    local has_python_files=$(find "$module" -type f -name "*.py" 2>/dev/null | wc -l)
    local has_js_files=$(find "$module" -type f -name "*.js" 2>/dev/null | wc -l)
    local lang_option=""

    # Set the language option based on the type of files present in the module.
    if [ $has_python_files -gt 0 ] && [ $has_js_files -eq 0 ]; then
      lang_option="py"
    elif [ $has_js_files -gt 0 ] && [ $has_python_files -eq 0 ]; then
      lang_option="js"
    elif [ $has_python_files -gt 0 ] && [ $has_js_files -gt 0 ]; then
      echo "Warning: Both Python and JavaScript files detected in $module. Defaulting to Python for code2flow."
      lang_option="py"
    else
      echo "No Python or JavaScript files found in $module. Skipping flow map generation."
      return
    fi

    # Generate JSON output using code2flow for the specified module.
    local json_output_file="$doc_folder/code2flow_output.json"
    generate_json_output "$module" "$json_output_file" "$lang_option"

    # Check if the generated JSON has valid code flow.
    local has_nodes=$(jq '.graph.nodes | length' "$json_output_file")
    local has_edges=$(jq '.graph.edges | length' "$json_output_file")

    if [ "$has_nodes" -eq 0 ] && [ "$has_edges" -eq 0 ]; then
      echo "No code flow detected for $module. Skipping code flow documentation."
      rm "$json_output_file"
      return
    fi

    # Use the generated JSON output to produce documentation using bito.
    local documentation=$(bito --file "$json_output_file" -p overviewprmt.txt)
    echo -e "\n## Code Flow Documentation\n\n$documentation\n" >> "$overview_file"

    # Produce and store the flow map, then append its reference to the overview markdown file.
    local flow_map_file="$doc_folder/flow_map.png"
    generate_flow_map "$module" "$flow_map_file" "$lang_option"
    echo -e "\n## Flow Map\n\n![Flow Map](flow_map.png)\n" >> "$overview_file"
  fi
}

# This function generates an overview for the entire codebase, combining the overview of 
# individual modules and adding a flow map for the entire codebase.
generate_codebase_overview() {
    # Start the codebase overview markdown content.
    local codebase_overview="## Codebase Overview\n\n"

    # Loop through each module in the codebase.
    for module in $modules; do
        # Check and skip hidden directories as they're typically not part of the main code.
        if is_hidden_dir "$module"; then
            continue
        fi
        echo "Processing module: $module"

        # Extract the module's name.
        local module_name=$(basename "$module")

        # Append the overview of the current module to the codebase overview.
        local module_overview_file="doc_$module/overview.md"
        if [ -f "$module_overview_file" ]; then
            codebase_overview+="### $module_name\n\n$(cat "$module_overview_file")\n\n---\n"
        else
            echo "No overview file found for $module_name"
        fi
    done

    # Generate a flow map for the entire codebase and save it to the specified file.
    local codebase_flow_map_file="doc_$folder/codebase_flow_map.png"
    if [[ -d "$folder" ]]; then
        code2flow --output "$codebase_flow_map_file" "$folder"
    fi

    # Append the generated flow map reference to the overview content.
    codebase_overview+="## Codebase Flow Map\n\n![Codebase Flow Map](codebase_flow_map.png)\n\n"

    # Use bito to generate a high-level summary of the entire system. The goal is to describe the 
    # overall system workflow, excluding minor details.
    local high_level_summary=$(echo -e "$codebase_overview" | bito -p high_level_prompt.txt)

    # Prepend the generated summary to the entire codebase overview content.
    local final_content="Summary: $high_level_summary\n\n$codebase_overview"

    # Write the combined content to a markdown file, which serves as the overview for the entire codebase.
    
    # local overview_file="doc_$folder/codebase_overview.md"
    local filename=${folder##*/} 
    local overview_file="doc_$filename/codebase_overview.md"

    echo -e "---- Writing codebase overview to $overview_file ----"
    echo -e "$final_content" > "$overview_file"
}


######### Main script

# Check if the required tools are installed
check_tools

# Get folder to document
if [ $# -eq 0 ]; then
  echo "Please provide a folder name as a command line argument"
  exit 1
fi

folder=$1

# Check if the folder exists
if [ ! -d "$folder" ]; then
  echo "Folder $folder does not exist"
  exit 1
fi

# Populate the modules variable with subdirectories and files directly under the main directory
modules=$(find "$folder" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*')
for file in "$folder/"*.{py,js}; do
  if [[ -f $file ]]; then
    modules="$modules $file"
  fi
done

# Create the doc directory structure before processing the modules
copy_dir_structure "$folder" "$folder"

# Process subdirectories first
subdirs=$(find "$folder" -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*')
for subdir in $subdirs; do
  # Only proceed if there are .py or .js files in the directory
  if [[ $(find "$subdir" -type f \( -name "*.py" -o -name "*.js" \) | wc -l) -gt 0 ]]; then
    doc_folder="doc_$subdir"
    generate_module_overview "$subdir" "$doc_folder"
  fi
done

# Process files directly under the main directory
for file in "$folder/"*.{py,js}; do
  if [[ -f $file ]]; then
    # Extract just the filename without the extension for the doc folder
    file_name=$(basename "$file" .${file##*.})
    doc_folder="doc_$folder/$file_name"
    
    # Create directory for the individual file's documentation
    mkdir -p "$doc_folder"
    
    # Generate overview for the file
    generate_module_overview "$file" "$doc_folder"
  fi
done

# Generate codebase overview
generate_codebase_overview