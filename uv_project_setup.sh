#!/bin/bash

# Exit on error
set -e

# Prompt for project name
read -p "Enter the UV project name: " PROJECT_NAME

# Use the UV Python tool to initialize the project
uv init "$PROJECT_NAME"

# Navigate to the project directory
cd "$PROJECT_NAME"

echo "Created Folder"

# Add a GitHub Action to install and run ruff
mkdir -p .github/workflows
cat > .github/workflows/ruff.yml <<EOL
name: Ruff
on: [ push, pull_request ]

jobs:
    ruff:
        runs-on: ubuntu-latest 
        steps:
            - uses: actions/checkout@v4
            - uses: astral-sh/ruff-action@v3
EOL

# Initialize Git repository
git init

# Add files to Git
git add .
git commit -m "Initial commit for $PROJECT_NAME"

# Retrieve GitHub username
USER_NAME=$(git config user.name)

# Create remote repository on GitHub
echo "Creating remote repository on GitHub..."
gh repo create "$PROJECT_NAME" --private --source=. --remote=origin

# Push to GitHub
git branch -M main
git push -u origin main

echo "UV project '$PROJECT_NAME' has been initialized and pushed to GitHub."