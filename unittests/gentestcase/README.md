# Test Case Generation

## Description
This script is used to generate test cases. Provide the Bito CLI a file and it will automatically generate function/method tests along the happy path as well as boundary/edge cases. If it's an API/interface, it will build test related to testing the interface, authorization, input validation, throttling, etc. It will generate mocks/stubs as necessary. 

## Video explanation
[![YouTube video](https://i.ibb.co/pddzQDS/thumbnail.png)](https://youtu.be/qxpho1Q1Rlw)

# How to use:
## Usage
```bash
./generate_testcases.sh source_file context_file_1 context_file_2 ... 
```

# generate_testcases.sh

This code is a bash script that utilizes the "bito" command-line tool (https://github.com/gitbito/CLI) to generate test cases for a given code file. The script performs the following steps:

1. Check if "bito" is installed:
   - If "bito" is not found, it displays an error message and exits.

2. Check the number of arguments:
   - The script expects at least one argument, which should be the path to the code file.
   - The following arguments are code files that can be useful for the AI to have context.
   - If the number of arguments is incorrect, it displays a usage message and exits.

3. Delete the "context.txt" file if found.
   - This file can be useful if the user wants to keep talking with the AI after using the tool.
   - It is erased every time the tool runs to start from zero.

4. Extract the filename without the extension:
   - The script extracts the filename from the provided path and removes the file extension.
   - The extracted filename is stored for later use.

5. Ask the user for his/her preferred testing framework and save it in a variable.

6. Read the two promps into variables to be used by the "bito" command.
   - The script reads the prompts into variables.
   - Then replaces the desired framework, the file to cover name and pastes the concatenated context files at the end of the first prompt.

7. Run the "bito" command:
   - The script executes the "bito" command with the following options:
     - -p "$temp_prompt": This is the first prompt with the replaced variables according to the user's input.
     - -f "$1": Specifies the path to the code file provided as an argument.
     - -c "context.txt": the file where the context of the conversation with the AI is to be written.
   - The output of the "bito" command is redirected to "/dev/null" to avoid printing the conversation into the terminal.

8. Run the "bito" command:
   - The script executes the "bito" command with the following options:
     - -p "$temp_prompt": This time, this variable is loaded with the second prompt, which tells the AI to complete the test and cover error/boundary paths.
     - -f "$1": Specifies the path to the code file provided as an argument.
     - -c "context.txt": the file where the context of the conversation with the AI is to be written.
   - The output of the "bito" command is redirected to a temporary file named "${filename}.$$" for further processing.

9. Run "extract_code.sh" on the output file:
   - The script executes the "extract_code.sh" script on the temporary output file generated in the previous step.
   - The purpose and functionality of the "extract_code.sh" script is documented in section below.
   - If a code block does not specify a language or if the language is not one of the ones recognized by the script (`python`, `javascript`, `js`, `bash`), the script will save the code block to a `.txt` file. *Update the code to add more languages based on your needs*

10. Remove the temporary output file:
   - The script removes the temporary output file "${filename}.$$" to clean up after execution.

## Usage Detail
The script requires at least one argument: the path to the source file. If the source file does not exist or if the number of arguments is incorrect, the script will display an error message and exit.
The rest of the arguments are optional, but very useful. In addition to the file to cover with tests, you can pass more files to be used by the AI to have context about the code you want to cover with tests. You can pass as many files as you want, but for AI performance reasons, it is recommended not to pass more than 5 extra files.

NOTE: Please checkout and change mode to execute for all shell scripts in `AI-Automation/unittests/gentestcase` folder and run the script from the folder itself.

```bash
./generate_testcases.sh source_file context_file_1 context_file_2 ...
```

# extract_code.sh

This is a bash script that extracts code blocks from a given source file and saves them as separate files. The script assumes that the source file uses Markdown syntax, with code blocks surrounded by triple backticks (\```). The language of the code block is determined by the string immediately following the opening backticks (e.g., ```python).

## Usage Detail

The script requires one argument: the path to the source file. If the source file does not exist or if the number of arguments is incorrect, the script will display an error message and exit.

```bash
./extract_code.sh source_file
```

## Main Functionality
The script reads the source file line by line. When it encounters a line that starts with triple backticks, it checks whether this line signifies the start or the end of a code block.

- If it's the start of a code block, the script stores the language of the code block (the string immediately following the backticks) in `block_lang` and sets `in_code_block` to `true`.
- If it's the end of a code block, the script determines the file extension based on the language stored in `block_lang`. It then increments the counter corresponding to that language. The content of the code block is saved to a file named `test_case_<source_filename>_<counter>.<extension>`, where `<source_filename>` is the name of the source file without the extension, `<counter>` is the counter for the corresponding language, and `<extension>` is the file extension determined by the language.

## Edge Cases
The script assumes that the code blocks in the source file are correctly formatted according to Markdown syntax. If a code block does not specify a language or if the language is not one of the ones recognized by the script (`python`, `javascript`, `js`, `bash`), the script will save the code block to a `.txt` file. *Update the code to add more languages based on your needs*

## Example
Given a source file `example.md` with the following content:

```python
print("Hello, world!")
```

```bash
echo "Hello, world!"
```

The script will create two files: `test_case_example_1.py` and `test_case_example_1.sh`, each containing the corresponding code block.
