---

# `createdoc.sh` 


## Description
This is a bash script designed to automate the generation of documentation for a codebase. It's tailored to extract docstrings, file summaries, and code flow diagrams from Python and JavaScript files. The generated documentation utilizes tools such as Bito, Code2Flow, Graphviz, and jq.

## Prerequisites

Ensure the following CLI tools are installed:

- **Bito CLI**
- **Code2Flow**
- **Graphviz (dot)**
- **jq**

**Important**: Before executing, ensure you have the latest version of Bito CLI, Code2Flow, Graphviz, and jq installed. If any of these tools are missing, the script will terminate and guide you to install the necessary tools.

## Usage

Invoke the script by supplying the folder name as an argument:

```bash
./createdoc.sh <folder_name>
```

Replace `<folder_name>` with the directory you wish to document. 

Once initiated, the script:

1. Verifies the existence of the provided folder.
2. Copies the directory structure from the source to a `doc_` prefixed folder.
3. Extracts docstrings from Python and JavaScript files.
4. Aggregates file summaries using Bito CLI.
5. Creates code flow maps for each module via Code2Flow.
6. Constructs a markdown overview for each module.
7. Generates a comprehensive codebase overview.

## Output

The output is structured as:

- A `doc_` prefixed folder resembling the source directory. This folder houses:
  - `overview.md` for each module detailing module name, docstrings, file summaries, and associated flow map images.
  - A `codebase_overview.md` file offering a snapshot of the entire codebase, inclusive of individual module overviews, the whole codebase flow map, and a broad system summary.

## Limitations

- Supports only Python and JavaScript files.
- Ignores hidden directories.
- Prioritizes Python over JavaScript in Code2Flow for modules containing both.
- Modules without Python or JavaScript won't have flow maps.
- No code flow documentation is generated if a module lacks identifiable code flow.

## Future Improvements

- Introducing additional programming language support.
- Refining the approach to modules containing both Python and JavaScript.
- Ensuring flow map generation irrespective of the presence of Python or JavaScript files.
- Always generating code flow documentation, even in the absence of identifiable module code flow.

Based on the provided ticket, here's a suggested improvement for the README to make it more structured and clear:

---

# Extending `createdoc.sh` to Support Additional Languages

`createdoc.sh` currently caters to Python and JavaScript codebases. To integrate other languages, follow the detailed steps below:

## 1. Define File Type Constants

File extensions are defined at the script's start:

```bash
PYTHON_FILES="*.py"
JS_FILES="*.js"
```

For a new language, e.g., Ruby, add:

```bash
RUBY_FILES="*.rb"
```

## 2. Modify `check_tools` Function

Adapt the `check_tools` function to verify the availability of tools pertinent to the new language.

## 3. Introduce Docstring Extraction Function

Create a function to extract docstrings or comments for the new language, resembling `extract_python_docstrings` and `extract_js_docstrings`. For Ruby:

```bash
extract_ruby_comments() {
  # Logic to extract Ruby comments
}
```

## 4. Revise `extract_docstrings` Function

Incorporate a condition in the `extract_docstrings` function to invoke your new function based on file type:

```bash
elif [[ "$1" == $RUBY_FILES ]]; then 
    extract_ruby_comments "$1"
```

## 5. Tweak `aggregate_file_summaries` Function

Update the `find` command within this function to recognize the new file extension.

## 6. Amend `generate_module_overview` Function

Adapt this function's section that discerns a module's language. Recognize your added language and configure the suitable `lang_option` for `code2flow`.

## 7. Manage Additional Dependencies

Should the new language necessitate third-party tools or dependencies, integrate them within the script. Potentially, you might have to append checks in the `check_tools` function.

---

### Rationale Behind These Amendments:

- **File Type Constants**: Determines which files to analyze.
  
- **`check_tools` Function**: Confirms the requisite tools for the new language.

- **Docstring Extraction**: Different languages employ distinct comment/docstring syntax, necessitating language-tailored functions.

- **`extract_docstrings` and `aggregate_file_summaries` Functions**: These ensure the documentation generation accommodates the new language files.

- **`generate_module_overview` Function**: It customizes documentation flow per the module's programming language.

- **Additional Dependencies**: Some languages might have distinct tools/libraries essential for documentation generation or code structure comprehension.

---

### Conclusion

Broadening support for other languages in an open-source project necessitates an in-depth grasp of the prevailing script's design and functionalities. This guide is curated to assist contributors in effortlessly incorporating new languages. Looking ahead, the script might benefit from a refactor to make language integration more modular and efficient.

---
