#!/bin/bash

# Script to help deploy an HTML file to GitHub Pages.

echo "----------------------------------------------------"
echo " GitHub Pages Deployment Helper"
echo "----------------------------------------------------"
echo "This script will guide you through deploying an HTML file to GitHub Pages."
echo "Please make sure you are in the directory where your HTML file is located,"
echo "or where you want to initialize a new Git repository for this project."
echo ""

# --- Configuration ---
DEFAULT_HTML_FILE="lru_cache_threejs_visualization.html" # From your immersive
SUGGESTED_HTML_FILE="index.html"
DEFAULT_BRANCH_NAME="main"

# --- Get User Input ---
read -p "Enter your GitHub Username: " GITHUB_USERNAME
if [[ -z "$GITHUB_USERNAME" ]]; then
    echo "GitHub Username cannot be empty. Exiting."
    exit 1
fi

read -p "Enter your GitHub Repository Name (e.g., lru-cache-viz): " REPO_NAME
if [[ -z "$REPO_NAME" ]]; then
    echo "Repository Name cannot be empty. Exiting."
    exit 1
fi

read -p "Enter the name of your HTML file (default: $DEFAULT_HTML_FILE): " HTML_FILE_INPUT
HTML_FILE_TO_DEPLOY="${HTML_FILE_INPUT:-$DEFAULT_HTML_FILE}"

if [[ ! -f "$HTML_FILE_TO_DEPLOY" ]]; then
    echo "Error: HTML file '$HTML_FILE_TO_DEPLOY' not found in the current directory."
    echo "Please make sure the file exists and you are in the correct directory."
    exit 1
fi

# Suggest renaming to index.html
FINAL_HTML_FILE_NAME="$HTML_FILE_TO_DEPLOY"
if [[ "$HTML_FILE_TO_DEPLOY" != "$SUGGESTED_HTML_FILE" ]]; then
    read -p "For best results with GitHub Pages, it's recommended to name your main HTML file '$SUGGESTED_HTML_FILE'. Do you want to rename '$HTML_FILE_TO_DEPLOY' to '$SUGGESTED_HTML_FILE' for deployment? (y/N): " RENAME_CHOICE
    if [[ "$RENAME_CHOICE" =~ ^[Yy]$ ]]; then
        if [[ -f "$SUGGESTED_HTML_FILE" ]]; then
            echo "Warning: '$SUGGESTED_HTML_FILE' already exists. Please resolve this manually."
            read -p "Do you want to proceed using '$HTML_FILE_TO_DEPLOY}' as the filename? (y/N): " PROCEED_ANYWAY
            if [[ ! "$PROCEED_ANYWAY" =~ ^[Yy]$ ]]; then
                echo "Exiting."
                exit 1
            fi
        else
            mv "$HTML_FILE_TO_DEPLOY" "$SUGGESTED_HTML_FILE"
            if [[ $? -eq 0 ]]; then
                echo "File renamed to '$SUGGESTED_HTML_FILE'."
                FINAL_HTML_FILE_NAME="$SUGGESTED_HTML_FILE"
            else
                echo "Error renaming file. Proceeding with '$HTML_FILE_TO_DEPLOY'."
            fi
        fi
    fi
else
    FINAL_HTML_FILE_NAME="$SUGGESTED_HTML_FILE" # It's already index.html
fi


read -p "Enter the branch name to deploy to (default: $DEFAULT_BRANCH_NAME): " BRANCH_NAME_INPUT
BRANCH_NAME="${BRANCH_NAME_INPUT:-$DEFAULT_BRANCH_NAME}"

echo ""
echo "--- Configuration Summary ---"
echo "GitHub Username: $GITHUB_USERNAME"
echo "Repository Name: $REPO_NAME"
echo "HTML File:       $FINAL_HTML_FILE_NAME"
echo "Deploy Branch:   $BRANCH_NAME"
echo "Remote URL:      https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
echo "-----------------------------"
read -p "Is this information correct? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled by user."
    exit 1
fi

# --- Git Operations ---
echo ""
echo "--- Starting Git Operations ---"

# Check if .git directory exists, if not, initialize git
if [ ! -d ".git" ]; then
    echo "No .git directory found. Initializing a new Git repository..."
    git init -b "$BRANCH_NAME"
    if [[ $? -ne 0 ]]; then echo "Error initializing Git repository. Exiting."; exit 1; fi
    echo "Git repository initialized."
else
    echo "Existing Git repository found."
    # Optionally, check current branch and offer to switch or create
    CURRENT_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$CURRENT_GIT_BRANCH" != "$BRANCH_NAME" ]]; then
        read -p "You are currently on branch '$CURRENT_GIT_BRANCH'. Do you want to switch to/create branch '$BRANCH_NAME'? (y/N): " SWITCH_BRANCH_CHOICE
        if [[ "$SWITCH_BRANCH_CHOICE" =~ ^[Yy]$ ]]; then
            git checkout -B "$BRANCH_NAME" # Creates if not exists, otherwise switches
            if [[ $? -ne 0 ]]; then echo "Error switching/creating branch '$BRANCH_NAME'. Exiting."; exit 1; fi
        else
            echo "Staying on branch '$CURRENT_GIT_BRANCH'. Make sure this is the branch you intend to deploy."
        fi
    fi
fi

# Set up remote origin
REMOTE_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
if ! git remote -v | grep -q "origin.*$REMOTE_URL"; then
    if git remote -v | grep -q "origin"; then
        echo "Remote 'origin' already exists but points to a different URL."
        read -p "Do you want to set 'origin' to '$REMOTE_URL'? This will overwrite the existing remote 'origin'. (y/N): " SET_REMOTE
        if [[ "$SET_REMOTE" =~ ^[Yy]$ ]]; then
            git remote set-url origin "$REMOTE_URL"
            if [[ $? -ne 0 ]]; then echo "Error setting remote URL. Exiting."; exit 1; fi
        else
            echo "Remote 'origin' not changed. Please ensure it's configured correctly for your intended repository. Exiting."
            exit 1
        fi
    else
        echo "Adding remote 'origin' with URL: $REMOTE_URL"
        git remote add origin "$REMOTE_URL"
        if [[ $? -ne 0 ]]; then echo "Error adding remote 'origin'. Exiting."; exit 1; fi
    fi
else
    echo "Remote 'origin' is already correctly configured."
fi

# Add, Commit, and Push
echo "Adding '$FINAL_HTML_FILE_NAME' to staging..."
git add "$FINAL_HTML_FILE_NAME"
if [[ $? -ne 0 ]]; then echo "Error adding file to Git. Exiting."; exit 1; fi

echo "Committing changes..."
COMMIT_MESSAGE="Deploy $FINAL_HTML_FILE_NAME to GitHub Pages"
git commit -m "$COMMIT_MESSAGE"
# Allow empty commit if file hasn't changed but user wants to push, or handle commit failure
if [[ $? -ne 0 ]]; then
    echo "Git commit failed. This might be because there are no changes to commit."
    echo "If you intended to push existing commits, you can ignore this. Otherwise, check your file."
    read -p "Do you want to try to push anyway? (y/N): " PUSH_ANYWAY_CHOICE
    if [[ ! "$PUSH_ANYWAY_CHOICE" =~ ^[Yy]$ ]]; then
        echo "Exiting without pushing."
        exit 1
    fi
fi

echo "Pushing to GitHub (branch: $BRANCH_NAME)..."
git push -u origin "$BRANCH_NAME"
if [[ $? -ne 0 ]]; then
    echo "Error pushing to GitHub. Please check your credentials, repository permissions, and internet connection."
    echo "Common issues:"
    echo "- Ensure the repository '$REPO_NAME' exists on GitHub under user '$GITHUB_USERNAME'."
    echo "- Ensure you have push access to the repository."
    echo "- If the remote branch does not exist, this command should create it."
    echo "- If the local branch is behind the remote, you might need to 'git pull' first (resolve conflicts if any) and then push."
    exit 1
fi

echo ""
echo "----------------------------------------------------"
echo " Successfully Pushed to GitHub!"
echo "----------------------------------------------------"
echo ""
echo "--- Next Steps to Enable GitHub Pages ---"
echo "1. Go to your GitHub repository in your web browser:"
echo "   https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "2. Click on the 'Settings' tab."
echo "3. In the left sidebar, click on 'Pages' (under 'Code and automation')."
echo "4. Under 'Build and deployment':"
echo "   - For 'Source', select 'Deploy from a branch'."
echo "   - For 'Branch', select '$BRANCH_NAME' and ensure the folder is set to '/ (root)'."
echo "   - Click 'Save'."
echo "5. GitHub Pages will build and deploy your site. This might take a few minutes."
echo "   You should see a message with the URL of your live site on that same 'Pages' settings page."
echo ""
echo "Your site should be available at a URL like:"
if [[ "$FINAL_HTML_FILE_NAME" == "index.html" ]]; then
    echo "   https://$(echo $GITHUB_USERNAME | tr '[:upper:]' '[:lower:]').github.io/$REPO_NAME/"
else
    echo "   https://$(echo $GITHUB_USERNAME | tr '[:upper:]' '[:lower:]').github.io/$REPO_NAME/$FINAL_HTML_FILE_NAME"
fi
echo ""
echo "Deployment script finished."

