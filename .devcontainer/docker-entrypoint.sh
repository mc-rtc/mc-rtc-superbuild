#!/bin/sh

if [ $BUILD_VERSION = "devcontainer" ]; then
  echo "Using the devcontainer entrypoint"
  # Check if /home/vscode/workspace exists
  if [ ! -d "/home/vscode/workspace" ]; then
    echo "⚠️ The /home/vscode/workspace directory is missing!"
    echo "➡️ Please add the following to your devcontainer.json to mount it:"
    echo '  "mounts": [ "type=bind,source=/path/to/local/workspace/mount/folder,target=/home/vscode/workspace" ]'
  fi
  if [ ! -d "/home/vscode/superbuild" ]; then
    echo "⚠️ The /home/vscode/superbuild directory is missing!"
    echo "➡️ Please add the following to your devcontainer.json to mount it:"
    echo '"workspaceMount": "source=${localWorkspaceFolder},target=/home/vscode/superbuild,type=bind",'
    echo '"workspaceFolder": "/home/vscode/superbuild"'
  fi
fi

# Check if zsh is installed
if command -v zsh >/dev/null 2>&1; then
  echo "✅ zsh found! Starting zsh..."
  exec zsh "$@"
else
  echo "⚠️ zsh not found, defaulting to bash."
  exec bash "@"
fi
