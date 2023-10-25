
---

# High-Level Documentation Generator

This script facilitates the automatic generation of high-level documentation for a given project directory. It aggregates module docstrings, creates a system overview, and generates flow maps for selected programming languages.

## Features

1. **Aggregate High-Level Understanding**: For every module in the directory, the script extracts a high-level summary using the `bito` command with specific prompts.
2. **System Overview**: Generate a system-level summary by aggregating individual module summaries.
3. **Flow Maps**: Create flow maps using `code2flow`.
4. **Refined Design Document**: Create a consolidated design documentation in markdown format, including flow maps.
5. **Log Word and Character Count**: Log word and character counts for each module to a specified log file.
6. **Tool and File Checker**: Verify the presence of required tools and files before executing.

## Prerequisites

Ensure the following tools are installed:

- `bito`
- `code2flow`
- `dot`

Also, make sure these prompt files are present in a specified prompt folder (`AI_Prompts` by default):

- `high_level_docstrings_prompt.txt`
- `system_summary_prompt.txt`
- `refined_organized_markdown_prompt.txt`

## How to Use

1. **Clone the Repository**: Clone this repository to your local machine.
2. **Set Execution Permissions**: Provide the necessary execution permissions to the script:
   ```bash
   chmod +x <script_name>.sh
   ```
3. **Run the Script**: Execute the script by providing the folder you wish to document as an argument:
   ```bash
   ./<script_name>.sh <folder_to_document>
   ```

## Output

The script will generate documentation in a folder named `doc_<folder_to_document>`. Within this folder, you'll find:

- `aggregated_module_docstrings.txt`: Aggregated module-level summaries.
- `system_overview.txt`: System-level summary.
- `High_Level_Design.md`: Consolidated high-level design documentation in markdown format, including the flow maps.
- Flow maps as `.png` files for Python (`flow_map_py.png`) and JavaScript (`flow_map_js.png`), if applicable.

## Skip List

Certain directories and files are skipped during the documentation process. This includes commonly ignored directories like `node_modules`, `logs`, etc., and files with extensions like `.json`, `.js`, etc. You can update the skip list within the script as per your requirements.

---

Adjust the `<script_name>.sh` placeholder with the actual name of your script before using this README.