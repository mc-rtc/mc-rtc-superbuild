#!/bin/bash

if [ "$BUILD_VERSION" = "devcontainer" ]; then
  echo "Using the devcontainer entrypoint"
  # Check if /home/vscode/workspace exists
  if [ ! -d /home/vscode/workspace ]; then
    echo "⚠️ The /home/vscode/workspace directory is missing!"
    echo "➡️ Please add the following to your devcontainer.json to mount it:"
    echo '  "mounts": [ "type=bind,source=/path/to/local/workspace/mount/folder,target=/home/vscode/workspace" ]'
  fi
  if [ ! -d /home/vscode/superbuild ]; then
    echo "⚠️ The /home/vscode/superbuild directory is missing!"
    echo "➡️ Please add the following to your devcontainer.json to mount it:"
    echo '"workspaceMount": "source=${localWorkspaceFolder},target=/home/vscode/superbuild,type=bind",'
    echo '"workspaceFolder": "/home/vscode/superbuild"'
  fi
fi

# If the install folder is present, source it
if [ -d $WORKSPACE_INSTALL_DIR ]; then
  echo 'echo "--> Sourcing mc-rtc-superbuild environment from $WORKSPACE_INSTALL_DIR/setup_mc_rtc.sh"' >> ~/.zshrc
  echo 'source $WORKSPACE_INSTALL_DIR/setup_mc_rtc.sh' >> ~/.zshrc;
fi

# If the superbuild folder is present, source its entrypoint instructions
if [ ! -d ${SUPERBUILD_DIR} ]; then
  echo 'echo "--> Sourcing default entrypoint ${SUPERBUILD_DIR}/.devcontainer/entrypoint.sh"' >> ~/.zshrc
  echo 'source ${SUPERBUILD_DIR}/.devcontainer/entrypoint.sh' >> ~/.zshrc
fi

# If the image was built with a custom entrypoint, source it as well
if [ -f ~/.docker-custom-entrypoint.sh ]; then
  echo 'echo "--> Using custom entrypoint ~/.docker-custom-entrypoint.sh"' >> ~/.zshrc
  echo 'source ~/.docker-custom-entrypoint.sh' >> ~/.zshrc
fi

echo "Checking env exported from docker build"
export
echo "export" >> ~/.zshrc

# Check if zsh is installed
if command -v zsh >/dev/null 2>&1; then
  echo "✅ zsh found! Starting zsh..."
  if [ "$#" -eq 0 ]; then
    exec zsh
  else
    exec zsh "$@"
  fi
else
  echo "⚠️ zsh not found, defaulting to bash."
  if [ "$#" -eq 0 ]; then
    exec bash
  else
    exec bash "@"
  fi
fi
