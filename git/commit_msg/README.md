# commit_message_generator.py

This Python script is a tool to generate commit messages based on the diff of changes in a git repository. The script uses `subprocess` to run shell commands, `argparse` to parse command line arguments, and `os` for file and directory operations.

## Function: generate_commit_message(repo_path, prompt_path)
This function generates a commit message based on the diff of changes in a git repository. 

### Parameters:
- `repo_path`: A string representing the path to the git repository. No default value.
- `prompt_path`: A string representing the path to the prompt file. No default value.

### Return:
This function returns a string representing the commit message.
NOTE:The commit message will also be stored in `commit_message.txt` file in the git repository directory, respectively

### Exceptions:
This function might raise a `subprocess.CalledProcessError` if the `git diff` or `bito` command fails.

## Function: parse_arguments()
This function parses command line arguments.

### Return:
This function returns an `argparse.Namespace` object containing the parsed arguments.

## Function: main()
This function is the main entry point of the script. It parses command line arguments, generates a commit message based on the diff of changes, and prints the commit message.

## Usage:
To use this script, run it from the command line with the `--repo` and `--prompt` options, like so:

```
python commit_message_generator.py --repo /path/to/repo --prompt /path/to/prompt
```

Replace `/path/to/repo` with the path to your git repository, and `/path/to/prompt` with the path to your prompt file. The script will print the generated commit message. The commit message will also be stored in `commit_message.txt` file in the git repository directory, respectively.

Prompt to generate commit message is provided in `prompts/commitmsg.pmt` in this folder

## Assumptions:
- The `git` command is available in the system's PATH.
- The `bito` command is available in the system's PATH. Available here: https://github.com/gitbito/CLI
- The repository at `repo_path` is a valid git repository.
- The `prompt_path` file exists and is readable.

