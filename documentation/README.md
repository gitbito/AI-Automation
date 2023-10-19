# AI Documentation Automations 

These intelligent AI automations provide various approaches to documenting your code. Use as is or feel free to edit them to fit your needs. 

Two documentation automations are available currently:

## [Module level overview and visualization](https://github.com/gitbito/AI-Automation/tree/main/documentation/create_overview_doc)
This is designed to automate the generation of documentation for a codebase. You get an overview of the module in natural language, an explanation of all the functions and variables and their role in the module. You also get a visualization Flow Map of the code flow. The generated documentation utilizes tools such as Bito, Code2Flow, Graphviz, and jq.  This currently works in Python or JS (you can add more languages easily) and documentation can be generated in over 50 spoken languages (English, German, Chinese, etc).

## [File level documentation](https://github.com/gitbito/AI-Automation/tree/main/documentation/create_code_doc)
This automation is used to generate documentation for files in a specified folder and its subfolders. It creates a document folder and copies the directory structure from the original folder to the document folder. Then, it creates documentation for each file in the specified folder and saves it in the corresponding location within the document folder.  Works in over 50+ programming languages, and documentation can be generated in over 50 spoken languages (English, German, Chinese, etc).
Several different automations. Provide Bito CLI a directory and it will automatically provide a detailed overview, visualization, and documentation for each file including summary of the file, dependencies, documentation regarding class/modules, function/methods, etc.  Works in over 50+ programming languages, and documentation can be generated in over 50 spoken languages (English, German, Chinese, etc).
