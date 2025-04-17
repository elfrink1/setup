#!/bin/bash

# Exit on error
set -e

# Check if UV is installed
if ! command -v uv &> /dev/null
then
    echo "UV could not be found. Please install UV first."
    exit
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null
then
    echo "GitHub CLI could not be found. Please install GitHub CLI first."
    exit
fi

# Prompt for project folder
read -p "Enter the path to the project folder (default is /home/$USER): " PROJECT_FOLDER

# Set default folder if none is provided
if [ -z "$PROJECT_FOLDER" ]; then
  PROJECT_FOLDER="/home/$USER"
else
  PROJECT_FOLDER="/home/$USER/$PROJECT_FOLDER"
fi

# Create the project folder if it does not exist
while [ ! -d "$PROJECT_FOLDER" ]; do
  read -p "The specified folder does not exist. Would you like to create it? (yes/no) [yes]: " CREATE_FOLDER
  CREATE_FOLDER=${CREATE_FOLDER:-yes}
  if [[ "$CREATE_FOLDER" == "yes" ]]; then
    echo "Creating the folder..."
    mkdir -p "$PROJECT_FOLDER"
  else
    read -p "Enter a new path to the project folder (default is /home/$USER): " PROJECT_FOLDER
    if [ -z "$PROJECT_FOLDER" ]; then
      PROJECT_FOLDER="/home/$USER"
    else
      PROJECT_FOLDER="/home/$USER/$PROJECT_FOLDER"
    fi
  fi
done

# Prompt for project name
read -p "Enter the UV project name: " PROJECT_NAME

# Use the UV Python tool to initialize the project
cd /home/$USER
uv init "$PROJECT_NAME"
cd "$PROJECT_NAME"
echo "Created Folder"

# Install pre-commit into project
uv sync
uv pip install pre-commit

cat > ./.pre-commit-config.yaml <<EOL
repos:
- repo: https://github.com/astral-sh/ruff-pre-commit
  # Ruff version.
  rev: v0.11.5
  hooks:
    # Run the linter.
    - id: ruff
      args: ["check", "--select", "I", "--fix"]
    # Run the formatter.
    - id: ruff-format
EOL

uvx pre-commit install

# Add a GitHub Action to install and run ruff on push and pull request
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
            - run: ruff check
            - run: ruff format --check
EOL

# Initialize Git repository
git init

# Add files to Git
git add .
git commit -m "Initial commit for $PROJECT_NAME"

echo "Created local repository"

# Retrieve GitHub username
USER_NAME=$(git config user.name)

# Create remote repository on GitHub
echo "Creating remote repository on GitHub..."
gh repo create "$PROJECT_NAME" --private --source=. --remote=origin

# Push to GitHub
git branch -M main
git push -u origin main

echo "UV project '$PROJECT_NAME' has been initialized and pushed to GitHub."