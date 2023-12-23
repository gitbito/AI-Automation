#!/bin/bash
set +x

# Setting some required variables
BITO_CMD=`which bito`
BITO_CMD_VEP=""
BITO_VERSION=`$BITO_CMD -v | awk '{print $NF}'`
# Compare BITO_VERSION to check if its greater than 3.7
if awk "BEGIN {exit !($BITO_VERSION > 3.7)}"; then
	BITO_CMD_VEP="--agent create_code_doc"
fi


# Check if folder name is provided as command line argument
if [ $# -eq 0 ]; then
    echo "Please provide folder name as command line argument"
    exit 1
fi

# Get folder name from command line argument
folder=$1

# Check if folder exists
if [ ! -d "$folder" ]; then
    echo "Folder $folder does not exist"
    exit 1
fi

# Create document folder by prepending "doc" to folder name
doc_folder="doc_$(basename $folder)"

# Create document folder if it does not exist
if [ ! -d "$doc_folder" ]; then
    mkdir -p "$doc_folder"
fi

# Create documentation for each file in folder and subfolders
find "$folder" -type f -name "*.sh" -o -name "*.py" -o -name "*.php" -o -name "*.js" | while read file; do
    # Get relative path of file from folder
    rel_path="${file#$folder/}"

    # Get directory path of file in document folder
    doc_dir="$doc_folder/$(dirname "$rel_path")"

    # Create directory if it does not exist
    if [ ! -d "$doc_dir" ]; then
        mkdir -p "$doc_dir"
    fi

    # Create documentation using bito and save it in document folder
    file2write="$doc_dir/$(basename "${file%.*}").md"
    echo "Creating documentation in: " $file2write
    # The below command does not work and gives following error
    # Only "-p" flag is applicable for this command. Remove any additional flags and then try again.
#    bito -p docprmt.txt -f "$file" >> "$file2write"
     cat $file | bito -p ./prompts/structured_doc.txt $BITO_CMD_VEP > $file2write
done

echo "Documentation created in $doc_folder"
