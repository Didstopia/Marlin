#!/usr/bin/env bash

# Check if current directory is a valid git repository
if [ ! -d ".git" ] || ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "::error::The current directory doesn't appear to be a valid Git repository, the 'git' command is unavailable or an unexpected error occurred. Ensure that the 'checkout' action has run successfully before executing this action."
    exit 1
fi

# If no branch is provided as an argument, use the current branch.
BRANCH=${1:-$(git rev-parse --abbrev-ref HEAD)}
if [ -z "$BRANCH" ]; then
    echo "::error::Branch name is invalid or not set. Please provide a valid branch name to sync."
    exit 1
fi

# Get the upstream repository in GitHub format.
UPSTREAM_REPO=${2}
if [ -z "$UPSTREAM_REPO" ]; then
    echo "::error::Upstream repository is invalid or not set. Please provide a valid upstream repository in the GitHub format of 'owner/repo'."
    exit 1
fi

# Get the list of protected branches in comma-separated format.
PROTECTED_BRANCHES_INPUT=${3:-"master,main,production"}

# If the protected-branches input is provided but is empty, set PROTECTED_BRANCHES to an empty array.
if [ -z "$PROTECTED_BRANCHES_INPUT" ]; then
    PROTECTED_BRANCHES=()
else
    IFS=',' read -ra PROTECTED_BRANCHES <<< "$PROTECTED_BRANCHES_INPUT"
fi

# Safety Check: If the branch is in the list of protected branches, exit.
for protected in "${PROTECTED_BRANCHES[@]}"; do
    if [ "$BRANCH" == "$protected" ]; then
        echo "::error::$BRANCH is a protected branch and cannot be synced!"
        exit 1
    fi
done

# Add remote upstream. If this fails, exit with an error.
if ! git remote add upstream "https://github.com/$UPSTREAM_REPO.git"; then
    echo "::error::Failed to add remote upstream repository $UPSTREAM_REPO. Make sure the repository format or URL is correct."
    exit 1
fi

# Fetch from upstream. If this fails, exit with an error.
if ! git fetch upstream; then
    echo "::error::Failed to fetch from upstream repository $UPSTREAM_REPO. Make sure you have permissions to access it."
    exit 1
fi

# Reset branch to match the upstream branch. If this fails, exit with an error.
if ! git reset --hard upstream/$BRANCH; then
    echo "::error::Failed to reset the branch $BRANCH. Make sure the branch $BRANCH exists in the upstream repository $UPSTREAM_REPO."
    exit 1
fi

# Push to the forked repository. If this fails, exit with an error.
if ! git push origin $BRANCH --force; then
    echo "::error::Failed to push changes. Make sure you have push access and ensure that your inputs correctly set and valid."
    exit 1
fi

echo "::info::Branch $BRANCH successfully synced with upstream repository $UPSTREAM_REPO."
