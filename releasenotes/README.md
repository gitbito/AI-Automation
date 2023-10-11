# release_notes_generator.py

This Python script is a tool to generate release notes based on the diff of changes in a git repository between commits. The script uses `subprocess` to run shell commands, `argparse` to parse command line arguments, and `os` for file and directory operations. 
It is heavily based on the commit_message_generator.py

## Function: generate_release_notes(repo_path, prompt_path, commit1, commit2, diff_file, verbose)
This function generates a release note in Markdown format based on either the diff of changes between commits in a git repository or the diff found in the specified file. 

### Parameters:
- `repo_path`: A string representing the path to the git repository. No default value.
- `prompt_path`: A string representing the path to the prompt file. No default value.
- `commit1`: A string representing the hash or tag of the oldest commit to compare the differences to. This parameter is optional, in case it is ommited it will use the HEAD version.
- `commit2`: A string representing the hash or tag of the newest commit to compare the differences with. This parameter is optional, in case it is ommited it will use the current status of the working dir.
- `diff_file` : Path to a manually generated difference file. Use only when not using --commit1 and --commit2. This parameter is optional.
- `verbose`: A boolean, when enabled it will print the strings used by the script for debugging purposes.

### Return:
This function returns a string representing release notes in Markdown format.
NOTE:The commit message will also be stored in `release_noted.md` file in the git repository directory.

### Exceptions:
This function might raise a `subprocess.CalledProcessError` if the `git diff` or `bito` command fails.

## Function: parse_arguments()
This function parses command line arguments. Valid arguments are:
- `--repo_path`: Path to the git repository. Required.
- `--prompt_path`: Path to the prompt file. Required.
- `--oldver`: Commit Tag/Hash of the old version. Optional, in case it is ommited it will use the HEAD version.
- `--newver`: Commit Tag/Hash of the new version. Optional, in case it is ommited it will use the current status of the working dir.
- `--diff_file` : Path to a manually generated difference file. Use only when not using --oldver and --newver. Optional.
- `-v` or `--verbose`: Optional flag for debugging purposes.
- `-h` or `--help`: Optional flag to display the help screen

### Return:
This function returns an `argparse.Namespace` object containing the parsed arguments.

## Function: main()
This function is the main entry point of the script. It parses command line arguments and generates release notes based on the diff of changes.

## Usage:
To use this script, run it from the command line with the `--repo` and `--prompt` and `--oldver` and `--newver` options, like so:

```
python .\release_notes_generator.py --repo /path/to/repo --prompt /path/to/prompt --oldver <oldhash> --newver <newhash> -v
```
or alternatively with the `--repo` and `--prompt` and `--diff_file` options, like so:
```
python .\release_notes_generator.py --repo /path/to/repo --prompt /path/to/prompt --diff_file /path/to/diff_file
```


Replace `/path/to/repo` with the path to your git repository, and `/path/to/prompt` with the path to your prompt file. The script will print the generated release message. The release message will also be stored in `release_notes.md` file in the git repository directory, respectively.

Prompt to generate release message is provided in `prompts/genrelease.pmt` in this folder

## Assumptions:
- The `git` command is available in the system's PATH.
- The `bito` command is available in the system's PATH. Available here: https://github.com/gitbito/CLI
- The repository at `repo_path` is a valid git repository.
- The `prompt_path` file exists and is readable.

