
---

# High-Level Documentation Generator

This tool is designed to simplify the process of creating high-level documentation for your project directory. It generates detailed information for each module, creates flow maps to visualize code execution paths, logs usage metrics, and aggregates all generated documentation.

## Features

- Customizable Module Analysis: Uses a user-editable prompt `high_level_doc_prompt.txt` from the `AI_Prompts` directory to analyze each module. Modify the prompt to extract details like:
   - Module Name
   - Primary Objectives
   - Key Functions and Roles
   - Important Variables
   - Interactions with Other System Parts
   - Main vs. Supportive Operations
   - Operational Sequence
   - Performance Factors
   - Reusability and Adaptability
- Skippable Files and Directories: The tool ignores specific files and directories by default, such as logs, node_modules, .gradle, and more. Adjust the skip list in the script to suit your project needs.

- Code Flow Maps: Generates flow maps in PNG format for languages like Python, JavaScript, Ruby, and PHP using code2flow.

- Comprehensive Documentation: Aggregates generated documentation from each module into an overarching markdown file.

- Documentation Metrics Logging: Records word and character counts for each module in the bito_usage_log.txt file.

- Required Tool and File Verification: The script checks for necessary tools and files before starting.

## Prerequisites

Ensure the following tools are installed:

- `bito`
- `code2flow`
- `dot`

Also, make sure these prompt files are present in a specified prompt folder (`AI_Prompts` by default):

- `high_level_doc_prompt.txt`
- `system_summary_prompt.txt`

## How to Use

1. **Clone the Repository**: Clone this repository to your local machine.
2. **Set Execution Permissions**: Provide the necessary execution permissions to the script:
   ```bash
   chmod +x <createdoc>.sh
   ```
3. **Run the Script**: Execute the script by providing the folder you wish to document as an argument:
   ```bash
   ./<createdoc>.sh <folder_to_document>
   ```

## Output

Upon successful execution, the tool generates a directory named doc_<folder_name>. Inside, you will find:

- Individual module markdown files, named as `<module_name>_High_Level_Doc.md`.
- An aggregated documentation named `Aggregated_High_Level_Doc.md`, which combines individual module documentations and flow maps.
- Flow maps for supported languages in PNG format: `flow_map_<lang>.png`.
- A summarized system documentation which explains the overall system's flow and functionality.

## Skip List

Certain directories and files are skipped during the documentation process. This includes commonly ignored directories like `node_modules`, `logs`, etc., and files with extensions like `.json`, `.js`, etc. You can update the skip list within the script as per your requirements.

---
