#!/bin/bash
#set -x

# Check if bito is installed
if ! command -v bito &> /dev/null
then
    echo "bito could not be found. Please install it and try again."
    exit 1
fi

# Setting some required variables
BITO_CMD=`which bito`
BITO_CMD_VEP=""
BITO_VERSION=`$BITO_CMD -v | awk '{print $NF}'`
# Compare BITO_VERSION to check if its greater than 3.7
if awk "BEGIN {exit !($BITO_VERSION > 3.7)}"; then
       BITO_CMD_VEP="--agent gentestcase"
fi


# Ensure at least one argument is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <code_file> [<context_file>...]"
    exit 1
fi

# Remove any context if found
rm -f "context.txt"

# Extract the filename without the extension
filename=$(basename -- "$1")
extension="${filename##*.}"
filename="${filename%.*}"
inputfile_for_ut_gen=$1

# Ask the user for their preferred testing framework
read -p "Please enter your preferred testing framework: " framework

# Read the prompts into variables
prompt=$(<prompts/gen_test_case_1.pmt)
prompt2=$(<prompts/gen_test_case_2.pmt)

# Replace the placeholders in the prompt with the user's input and filename
prompt=${prompt/\$framework/${framework}}
prompt=${prompt/\$filename/${filename}.${extension}}

# Initialize context variable
context=""

# If there are additional arguments, concatenate their contents into the context variable
shift # Skip the first argument
for file in "$@"; do
    if [ -f "$file" ]; then
        context+=$(<"$file")
    fi
done

# Replace the $context placeholder in the prompt with the context
prompt=${prompt/\$context/${context}}

# Create a temporary file and write the modified prompt to it
temp_prompt=$(mktemp)
echo "$prompt" > "$temp_prompt"

echo "Generating unit tests..."
# Run the bito command with the first prompt
if ! bito $BITO_CMD_VEP -p "$temp_prompt" -f $inputfile_for_ut_gen -c "context.txt" > /dev/null; then
    echo "Error: The bito command failed."
    rm "$temp_prompt"
    exit 1
fi

echo "$prompt2" > "$temp_prompt"

# Run the bito command with the second prompt and store the output
if ! bito $BITO_CMD_VEP -p "$temp_prompt" -f $inputfile_for_ut_gen -c "context.txt" > "${filename}.$"; then
    echo "Error: The bito command failed."
    rm "$temp_prompt"
    exit 1
fi

# Run extract_code.sh on the output file
./extract_code.sh "${filename}.$"
rm "${filename}.$"

# Remove the temporary file
rm "$temp_prompt"
