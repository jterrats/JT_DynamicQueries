#!/bin/bash
# Script to fix ASCII diagram alignment in GITHUB_ISSUES_V3.md

FILE="/Users/jterrats/dev/JT_DynamicQueries/GITHUB_ISSUES_V3.md"

echo "Fixing ASCII diagrams in $FILE..."

# Replace 4 backticks with 3 backticks
sed -i '' 's/````/```/g' "$FILE"

# Remove the extra closing backticks at the end of issue descriptions
sed -i '' '/^````$/d' "$FILE"

# Fix lines that lost their leading spaces (│ text should be │  text)
# This adds 2 spaces after │ if it's followed directly by non-whitespace
sed -i '' 's/^│ \([^ ]\)/│  \1/g' "$FILE"

echo "✅ ASCII diagrams fixed!"
















