#!/bin/sh

# Check if /home/vscode/workspace exists
if [ ! -d "/home/vscode/workspace" ]; then
  echo "⚠️ The /home/vscode/workspace directory is missing!"
  echo "➡️ Please add the following to your devcontainer.json to mount it:"
  echo '  "mounts": [ "type=bind,source=/path/to/local/workspace/mount/folder,target=/home/vscode/workspace" ]'
fi

# Check if zsh is installed
if command -v zsh >/dev/null 2>&1; then
  echo "✅ zsh found! Starting zsh..."
  exec zsh "$@"
else
  echo "⚠️ zsh not found, defaulting to bash."
  exec bash "@"
fi
