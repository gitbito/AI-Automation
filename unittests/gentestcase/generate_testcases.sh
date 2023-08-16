#!/bin/bash

# Check if bito is installed
if ! command -v bito &> /dev/null
then
    echo "bito could not be found. Please install it and try again."
    exit 1
fi

# Ensure the correct number of arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <code_file>"
    exit 1
fi

# Extract the filename without the extension
filename=$(basename -- "$1")
extension="${filename##*.}"
filename="${filename%.*}"

# Run the bito command and store the output
bito -p "prompts/gen_test_case.pmt" -f "$1" > "${filename}.$$"

# Run extract_code.sh on the output file
./extract_code.sh "${filename}.$$"
rm "${filename}.$$"
