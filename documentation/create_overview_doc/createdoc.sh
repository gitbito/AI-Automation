#!/bin/bash

PYTHON_FILES="*.py"
JS_FILES="*.js"

check_tools() {
  local tools=("bito" "code2flow" "dot" "jq")
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

copy_dir_structure() {
  local src=$1
  local dest="doc_$2" 

  echo -e "\n---- Copying directory structure from $src to $dest ----"
  find "$src" -mindepth 1 -type d | sed "s|^$src/||" | while read -r dir; do
    if [ -d "$src/$dir" ] && ! is_skippable "$src/$dir"; then
      mkdir -p "$dest/$dir"
    fi
  done
}

generate_flow_docs() {
  local module=$1
  local flow_doc_file=$2
  local lang_option=$3

  echo -e "\n---- Generating code flow docs for files in $module using language: $lang_option ----"

  if [[ -d "$module" ]]; then
    code2flow --output "$flow_doc_file" --language "$lang_option" "$module"/*.py "$module"/*.js --quiet
  elif [[ -f "$module" ]]; then
    code2flow --output "$flow_doc_file" --language "$lang_option" "$module" --quiet
  fi
}

generate_flow_map() {
  local module=$1
  local flow_map_file=$2
  local lang_option=$3

  echo -e "\n---- Generating code flow map for files in $module using language: $lang_option ----"

  if [[ -d "$module" ]]; then
    code2flow --output "$flow_map_file" --language "$lang_option" "$module"/*.py "$module"/*.js --quiet
  elif [[ -f "$module" ]]; then
    code2flow --output "$flow_map_file" --language "$lang_option" "$module" --quiet
  fi
}

extract_python_docstrings() {
  awk '/^\s*\"\"\"/ {if (in_doc) {print "```"; in_doc=0} else {print "```python"; in_doc=1}} in_doc' "$1"
}

extract_js_docstrings() {
  awk '/^\s*(\/\*\*|\/\/\*\*)/ {if (in_doc) {print "```"; in_doc=0} else {print "```js"; in_doc=1}} in_doc' "$1"
}

extract_docstrings() {
  if [[ "$1" == $PYTHON_FILES ]]; then
    extract_python_docstrings "$1" 
  elif [[ "$1" == $JS_FILES ]]; then 
    extract_js_docstrings "$1"
  fi
}

generate_file_summary() {
  local file=$1
  local prompt_file=$2
  local file_summary=$(cat "$file" | bito -p "$prompt_file")
  echo "File: $file"
  echo "Bito Output: $file_summary"
}

aggregate_file_summaries() {
  local module=$1
  local prompt_file=$2
  local summaries=""
  find "$module" -type f \( -name $PYTHON_FILES -o -name $JS_FILES \) | while read file; do
    if ! is_skippable "$file"; then
      file_summary=$(generate_file_summary "$file" "$prompt_file")
      summaries+="### $(basename "${file%.*}")\n\n$file_summary\n\n---\n"
    fi
  done
  echo "$summaries"
}

generate_module_overview() {
  local module=$1
  local doc_folder=$2

  if is_skippable "$module"; then
    return
  fi

  echo -e "\n---- Generating module overview for $module ----"

  local docstrings=$(extract_docstrings "$module")
  local module_name=$(basename "$module")

  local overview_file="$doc_folder/overview.md"
  echo "## $module_name Overview" > "$overview_file"
  echo -e "$docstrings" >> "$overview_file"

  local summaries=$(aggregate_file_summaries "$module" "docprmt.txt")
  echo -e "$summaries" >> "$overview_file"

  local has_python_files=$(find "$module" -type f -name "*.py" 2>/dev/null | wc -l)
  local has_js_files=$(find "$module" -type f -name "*.js" 2>/dev/null | wc -l)
  local lang_option=""

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

  local json_output_file="$doc_folder/code2flow_output.json"
  generate_json_output "$module" "$json_output_file" "$lang_option"

  local has_nodes=$(jq '.graph.nodes | length' "$json_output_file")
  local has_edges=$(jq '.graph.edges | length' "$json_output_file")

  if [ "$has_nodes" -eq 0 ] && [ "$has_edges" -eq 0 ]; then
    echo "No code flow detected for $module. Skipping code flow documentation."
    rm "$json_output_file"
    return
  fi

  local documentation=$(bito --file "$json_output_file" -p overviewprmt.txt)
  echo -e "\n## Code Flow Documentation\n\n$documentation\n" >> "$overview_file"

  local flow_map_file="$doc_folder/flow_map.png"
  generate_flow_map "$module" "$flow_map_file" "$lang_option"
  echo -e "\n## Flow Map\n\n![Flow Map](/$flow_map_file)\n" >> "$overview_file"
}

# Function to generate codebase overview
generate_codebase_overview() {
  # Start the codebase overview markdown content.
  local codebase_overview="## Codebase Overview\n\n"
  # Loop through each module in the codebase.
  for module in $modules; do
    # Check and skip hidden directories as they're typically not part of the main code.
    if is_skippable "$module"; then
      continue
    fi
    
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

  echo -e "\n---- Generating codebase flow map ----"

  local codebase_flow_map_file="doc_$folder/codebase_flow_map.png"
  if [[ -d "$folder" ]]; then
    code2flow --output "$codebase_flow_map_file" "$folder" --quiet
  fi
  codebase_overview+="## Codebase Flow Map\n\n![Codebase Flow Map](/$codebase_flow_map_file)\n\n"
  local high_level_summary=$(echo -e "$codebase_overview" | bito -p high_level_prompt.txt)
  local final_content="Summary: $high_level_summary\n\n$codebase_overview"
  local filename=${folder##*/} 
  local overview_file="doc_$filename/codebase_overview.md"
  echo -e "---- Writing codebase overview to $overview_file ----"
  echo -e "$final_content" | sed '/## Flow Map/d' > "$overview_file"
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

# Populate the modules variable with subdirectories and files within the main directory, excluding node_modules and hidden directories
modules=""
while IFS= read -r -d '' module; do
  if [[ -d $module || -f $module ]]; then
    modules+="$module "
  fi
done < <(find "$folder" -type d -not -path '*/\.*' -not -path '*/node_modules*' -print0)

echo -e "\n\n---- Modules to process: $modules ----\n\n"

# Create the doc directory structure before processing the modules
copy_dir_structure "$folder" "$folder"

# Process subdirectories and files under the main directory
IFS=$' ' # set space as delimiter
for module in $modules; do
  # For .js files within node_modules, skip the module
  if [[ "$module" == *".js" ]] && is_skippable "$module"; then
    continue
  fi
  echo -e "\n\n---- Processing module: $module ----"
  generate_module_overview "$module" "doc_$module"
done

# Generate codebase overview
# generate_codebase_overview