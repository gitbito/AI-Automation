#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <source_file>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Error: File $1 not found."
    exit 1
fi

# Extracting the filename without the extension
filename=$(basename -- "$1")
filename_no_ext="${filename%.*}"

in_code_block=false
block_content=""
block_lang=""

python_counter=0
javascript_counter=0
bash_counter=0
default_counter=0

while IFS= read -r line; do
    if [[ $line == \`\`\`* ]]; then
        if $in_code_block; then
            # End of a code block
            in_code_block=false

            # Determine file extension based on language and increment counter
            case "$block_lang" in
                python)
                    ext=".py"
                    ((python_counter++))
                    counter=$python_counter
                    ;;
                javascript)
                    ext=".js"
                    ((javascript_counter++))
                    counter=$javascript_counter
                    ;;
                js)
                    ext=".js"
                    ((javascript_counter++))
                    counter=$javascript_counter
                    ;;
                bash)
                    ext=".sh"
                    ((bash_counter++))
                    counter=$bash_counter
                    ;;
                *)
                    ext=".txt"
                    ((default_counter++))
                    counter=$default_counter
                    ;;
            esac

            # Construct the filename using the source file's name, language, and counter
            output_file="test_case_${filename_no_ext}_${counter}$ext"

            # Save content to file
            echo "$block_content" > "$output_file"
            block_content=""
            block_lang=""
            echo "Code saved in: $output_file"
        else
            # Start of a code block
            in_code_block=true
            block_lang="${line#\`\`\`}"
        fi
    elif $in_code_block; then
        if [ -z "$block_content" ]; then
            block_content="$line"
        else
            block_content="$block_content"$'\n'"$line"
        fi
    fi
done < "$1"
