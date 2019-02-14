#!/bin/bash

# https://codeinthehole.com/tips/tips-for-using-a-git-pre-commit-hook/

STASH_NAME="pre-commit-$(date +%s)"
git stash save -q --keep-index $STASH_NAME

# check for ADDED lines with tabs
for file in "$(git diff --name-status --cached | grep -v ^D | cut -c3-)"; do
    if [[ "${file}" =~ [.](h|hpp|c|cpp|cxx|cc|sh|bash)$ ]]; then
        git diff --cached "${file}" | grep -n -E '^\+.*	.*$' | sed "s/^/${file}:/" && { echo error; exit 1; }
    fi
done

STASHES=$(git stash list)
if [[ $STASHES == "$STASH_NAME" ]]; then
  git stash pop -q
fi
