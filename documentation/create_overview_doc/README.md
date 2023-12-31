# High-Level Documentation Generator

This powerful tool streamlines the creation of high-level documentation for software project directories. It analyzes code modules, generates visual flow maps, and compiles comprehensive documentation, all while keeping track of usage metrics.

## Features

- **AI Enhanced Module Analysis**: Leverages an AI-driven process to analyze each module, using a user-editable prompt high_level_doc_prompt.txt from the AI_Prompts directory. You can adjust the prompt to obtain a variety of module insights such as:
   - Module Name
   - Primary Objectives
   - Key Functions and Roles
   - Important Variables
   - Interactions with Other System Parts
   - Main vs. Supportive Operations
   - Operational Sequence
   - Performance Factors
   - Reusability and Adaptability
   - Usage
   - Assumptions

- **Auto-Retry Logic and Enhanced Error Handling**: Ensures reliable documentation generation even in unstable environments through sophisticated error handling and retry mechanisms.

- **Visualization with Mermaid.js Flow Maps and Enhanced Syntax Handling**: AI-generated visual flow maps to represent module interactions. Now with improved handling of Mermaid diagram syntax, minimizing manual interventions.

- **Mermaid CLI Image Conversion**: Transforms Mermaid.js diagrams into images, offering a clear visual representation of your code architecture.

- **Skippable Files and Directories**: Customize which files and directories to ignore during documentation via the `skip_list.csv`.

- **Comprehensive Documentation**: Generates detailed markdown files for each module and compiles them into an overarching High_Level_Doc, complete with visual flow maps. 

- **Documentation Metrics Logging**: Track your session duration and token usage metrics, recorded in `bito_usage_log.txt`.

- **Required Tool and File Verification**: Checks for the presence of necessary tools ("bito", "mmdc") and prompt files before starting the documentation process.

## Supported Languages

Supports Python, C, C++, Java, JavaScript, Go, Rust, Ruby, PHP, Bash, Kotlin and is extensible to other languages.

To add support for a new language, simply add the file extension to the CSV file `programming_languages.csv`.

```
py
c
cpp
java
js
go
rs
rb
php
sh
kt
```

## Prerequisites

Ensure the following tools are installed:

- `bito` : https://github.com/gitbito/CLI

- `mermaidcli` : https://github.com/mermaid-js/mermaid-cli

Also, make sure these prompt files are present in a specified prompt folder (`AI_Prompts` by default):

- `high_level_doc_prompt.txt`
- `mermaid_doc_prompt.txt`
- `fix_mermaid_syntax_prompt.txt`
- `system_introduction_prompt.txt`
- `system_overview_mermaid_update_prompt.txt`

## How to Use

1. **Clone the Repository**: Clone this repository to your local machine.
2. **Set Execution Permissions**: Provide the necessary execution permissions to the script:
   ```bash
   chmod +x createdoc.sh
   ```
3. **Run the Script**: Execute the script by providing the folder you wish to document as an argument:
   ```bash
   ./createdoc.sh <folder_to_document>
   ```

## Output

Upon successful execution, the tool generates a directory named `doc_<folder_name>`

The directory includes:

- Module Documentation: Individual markdown files for each module, titled `<module_name>_Doc.md`, detailing the module's purpose, functions, and interactions.

- Aggregated Documentation: A comprehensive markdown file `High_Level_Doc.md`, which consolidates the documentation from each module. This file also includes SVG format flow maps created by Mermaid.js for a visual overview of module interactions, and a final Full System Flow Map in PNG format generated by code2flow for a broader system perspective.

## Skip List

The Skip List feature enables the exclusion of specific files and directories from the documentation process. By default, the tool ignores common directories like `node_modules` and log files, as well as various temporary or compiled files.

### Updating the Skip List

By customizing the Skip List, you gain control over the documentation content, ensuring it's concise, relevant, and tailored to showcase the most significant aspects of your project.

To customize the Skip List to fit your project's needs, follow these steps:

1. **Open the CSV File**:
   - Locate and edit the skip_list.csv file, which should be in the same directory as the createdoc.sh script.

2. **Modify the Skip List**:
   - Add or remove file or directory patterns you want to exclude.
   - Each line in the CSV file represents a pattern to be skipped.
   - Example: To add a custom pattern, simply add a new line with the pattern, like `private_`.
   - Your modified list might look like this:
      ```
      logs
      node_modules
      private_
      dist
      build
      .gradle
      ```
      Now all files or folders with the pattern `private_` in its name will be ignored in the documentation process.

3. **Save the CSV File**:
   - After making your changes, save and close the CSV file.

5. **Re-run the Script**:
   - Execute the script again to apply the new Skip List settings.

## Known Issues and Solutions

### Syntax Errors in Mermaid Diagrams
- **Issue**: Occasional syntax errors in AI-generated Mermaid diagrams, such as misplaced quotes or empty parentheses.
- **Current Solutions**:
  - **Automated Fixes**: Script (`fix_mermaid_syntax`) and AI-driven (`fix_mermaid_syntax_with_bito`) methods are used for common syntax corrections.
  - **Manual Editing**: For unresolved errors, manual editing can be done using the [Mermaid Live Editor](https://mermaid.live/).
  - **Update Command**: Post-editing, update diagrams in your markdown documentation using: 
    ```
    mmdc -i High_Level_Doc.md -o High_Level_Doc.md
    ```

### Ongoing Efforts
- We're continuously improving our AI models and scripts based on user feedback.
- Future updates will focus on reducing manual intervention and enhancing the user experience.

Your feedback is invaluable in helping us refine and improve this tool.
