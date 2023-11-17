# Introduction :

The createdoc.sh module is a powerful tool designed to automate the process of document creation. Its primary objectives are to streamline workflow, increase efficiency, and reduce manual effort. 

The core functionality of the createdoc.sh module is to take a user's project, process, and generate a documents.

In terms of security, the createdoc.sh module is designed with a strong emphasis on data privacy. The system does not retain any sensitive information. This ensures that the user's data is protected at all times.

The createdoc.sh module is a robust and versatile tool that can significantly enhance productivity and efficiency in document creation tasks. Its combination of advanced AI technology, user-friendly features, and strong security measures makes it an excellent choice for users who need to create high-quality documents quickly and easily.

# Full System Overview
![diagram](./High_Level_Doc-1.svg)
# Module Overview
## Module: createdoc.sh
 Here is a comprehensive analysis of the provided module:

**Module Name**: createdoc.sh

**Primary Objectives**: This Bash script automates the generation of documentation for a codebase by leveraging Bito's AI capabilities. It extracts information from source code files, calls Bito to generate high-level documentation, creates visual diagrams, and aggregates everything into markdown files.

**Critical Functions**:

- check_tools_and_files: Validates required tools like Bito CLI and files are present.

- read_skip_list: Reads list of files/folders to skip from a CSV. 

- create_module_documentation: Generates high-level text documentation for a module using Bito.

- create_mermaid_diagram: Uses Bito to create a Mermaid diagram for a module.

- fix_and_validate_mermaid: Fixes invalid Mermaid syntax and validates it.

- generate_mermaid_diagram: Replaces Mermaid code blocks in Markdown with generated diagrams.

- generate_mdd_overview: Aggregates all Mermaid diagrams into an overview diagram.

- main: Orchestrates the overall workflow - processes files, calls functions, aggregates documentation.

**Key Variables**: 

- prompt_folder: Directory containing prompt files for Bito.

- docs_folder: Output folder for generated documentation.

- aggregated_md_file: Main aggregated Markdown file.

- lang_csv: CSV containing file extensions for documentation.

- skip_list_csv: CSV containing files/folders to skip.

**Interdependencies**:

- Depends on Bito CLI, Mermaid CLI for core functionality.

- Extracts information from source code files.

- Outputs documentation as Markdown files.

**Core vs Auxiliary Operations**:

Core:

- Documentation generation functions like create_module_documentation, create_mermaid_diagram etc.

- Bito calls to generate content.

- Mermaid validation and diagram generation.

Auxiliary:

- Setup like tools check, skip list reading. 

- Logging token usage.

**Operational Sequence**:

1. Check requirements and inputs.

2. Process source files.

3. Generate docs and diagrams for each module.

4. Aggregate documentation.

5. Create overview diagram.

6. Log results.

**Performance Aspects**:

- Uses retry logic and rate limiting when calling Bito to handle errors.

- Leverages parallel file processing for faster documentation generation.

- Limits Bito calls by reusing output where applicable.

**Reusability**:

- Highly adaptable to other languages by configuring the file extension CSV.

- Prompt files can be tailored for different documentation needs and need not only be used for code.

- Modular functions make customization easier.

**Usage**:

Called with path to codebase as argument. Orchestrates documentation generation by processing files, calling Bito, creating diagrams and aggregating output.

**Assumptions**:

- Source code files contain modules/functions to document.

- Bito CLI and Mermaid CLI are installed and configured.

- Prompt files match the documentation requirements.

- CSVs are configured with correct file extensions and skip rules.
