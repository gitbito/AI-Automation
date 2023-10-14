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

---
