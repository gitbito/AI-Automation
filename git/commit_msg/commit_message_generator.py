import subprocess
import argparse
import os

def generate_commit_message(repo_path, prompt_path):
    diff_command = "git -C {} diff".format(repo_path)
    diff_output = subprocess.check_output(diff_command, shell=True, universal_newlines=True)

    # Write diff output to a file
    diff_file = os.path.join(repo_path, 'diff_output.txt')
    with open(diff_file, 'w') as file:
        file.write(diff_output)

    # Process the diff_output and generate the commit message using bito CLI commands
    bito_command = "bito -p {} -f {}".format(prompt_path, diff_file)
    bito_output = subprocess.check_output(bito_command, shell=True, universal_newlines=True)
    commit_message = bito_output.strip()

    # Write commit message to a file
    commit_file = os.path.join(repo_path, 'commit_message.txt')
    with open(commit_file, 'w') as file:
        file.write(commit_message)

    # Remove the diff_output file
    os.remove(diff_file)

    return commit_message

def parse_arguments():
    parser = argparse.ArgumentParser(description='Generate commit message based on diff of changes.')
    parser.add_argument('--repo', required=True, help='Path to the git repository')
    parser.add_argument('--prompt', required=True, help='Path to the prompt file')
    args = parser.parse_args()
    return args

def main():
    args = parse_arguments()
    commit_message = generate_commit_message(args.repo, args.prompt)
    print("Commit message to use:")
    print(commit_message)

if __name__ == "__main__":
    main()

