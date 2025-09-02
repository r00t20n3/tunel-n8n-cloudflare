#!/bin/bash

# Find all .sh files in the current directory and make them executable
for file in *.sh; do
  if [ -f "$file" ]; then
    chmod +x "$file"
    echo "Made $file executable"
  else
    echo "No .sh files found in the current directory"
  fi
done 