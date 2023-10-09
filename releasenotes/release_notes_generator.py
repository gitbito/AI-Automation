import subprocess
import argparse
import os

def generate_release_notes(repo_path, prompt_path, commit1=None, commit2=None, diff_file=None, verbose=False):
    temp_diff = False

    if commit1 and commit2:
        # Compare between 2 specified committed versions
        diff_command = f"git -C {repo_path} diff {commit1}..{commit2}"
    elif commit1:
        # compare between working copy and specified committed version
        diff_command = f"git -C {repo_path} diff {commit1}"
    elif diff_file:
        diff_command = None
    else:
        # compare between working copy and HEAD
        diff_command = f"git -C {repo_path} diff"

    if verbose:
        print(diff_command)

    # execute the diff command
    if diff_command:
        # diff_output = subprocess.check_output(diff_command, shell=True, universal_newlines=True, encoding='utf-8')
        output = subprocess.run(diff_command, capture_output=True)
        diff_output = output.stdout.decode("utf-8")
        if verbose:
            print(diff_output)
        
        # Write diff output to a file
        diff_file = os.path.join(repo_path, 'diff_output.txt')
        with open(diff_file, 'w', encoding="utf-8") as file:
            file.write(diff_output)
        temp_diff = True

    # Process the diff_output and generate the commit message using bito CLI commands
    bito_command = f"bito -p {prompt_path} -f {diff_file}"
    bito_output = subprocess.check_output(bito_command, shell=True, universal_newlines=True)
    release_notes = bito_output.strip()
    if verbose:
        print("\nRelease Notes:")
        print(release_notes)

    # Write release notes to a markdown file
    release_file = os.path.join(repo_path, 'release_notes.md')
    with open(release_file, 'w') as file:
        file.write(release_notes)

    # Remove the temporary diff_output file
    if temp_diff:
        os.remove(diff_file)


def parse_arguments():
    parser = argparse.ArgumentParser(description='Generate release notes based on diff of 2 arbitrary commits.')
    parser.add_argument('--repo', required=True, help='Path to the git repository')
    parser.add_argument('--prompt', required=True, help='Path to the prompt file')
    parser.add_argument('--oldver', required=False, help='Commit Tag/Hash of the old version (optional)')
    parser.add_argument('--newver', required=False, help='Commit Tag/Hash of the new version (optional)')
    parser.add_argument('--diff_file', required=False, help='Path to file containing the differences between release versions (optional, only when --oldver and --never are not specified)')
    parser.add_argument('-v', '--verbose', required=False, help='Display info', action='store_true')
    args = parser.parse_args()
    if args.verbose:
        print(args)
    return args


def main():
    args = parse_arguments()
    generate_release_notes(args.repo, args.prompt, args.oldver, args.newver, args.diff_file, args.verbose)


if __name__ == "__main__":
    main()

