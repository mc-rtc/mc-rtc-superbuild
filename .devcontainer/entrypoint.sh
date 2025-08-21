#!/usr/bin/env bash

echo "-- Setting up the container --"
echo "-- Checking devcontainer requirements --"
if [ "$BUILD_VERSION" = "devcontainer" ]; then
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

echo "-- Sourcing additional files --"
# If the install folder is present, source it
if [ -d $WORKSPACE_INSTALL_DIR ]; then
  echo "--> Sourcing mc-rtc-superbuild environment from $WORKSPACE_INSTALL_DIR/setup_mc_rtc.sh"
  source $WORKSPACE_INSTALL_DIR/setup_mc_rtc.sh
fi

# If the image was built with a custom entrypoint, source it as well
if [ -f ~/.docker-custom-entrypoint.sh ]; then
  echo '--> Using custom entrypoint ~/.docker-custom-entrypoint.sh'
  source ~/.docker-custom-entrypoint.sh
fi

echo "-- Setting up environment variables --"
# Makes GNUPG ask for password in the terminal
export GPG_TTY=$(tty)
echo "GPG_TTY=$GPG_TTY"

echo "-- ccache --"
echo "ccache is configured as follows:"
# Copy cache from the image to the local repository
# This ensures that cache is kept between successive container runs
echo "Synching local .ccache in your workspace with the pre-built cache in the docker image"
echo "CCACHE_DIR=$CCACHE_DIR"
rsync -a ~/.cache/ccache/ ~/workspace/.ccache --exclude='**.tmp.*' --ignore-existing
export CCACHE_DIR=~/workspace/.ccache
ccache -sv
# Add checkbox emoji
echo "✅ Container setup complete"

echo ""
echo ""
echo "-- Welcome to mc-rtc-superbuild image for Ubuntu `lsb_release -cs`! --"
echo ""
echo "All the tools needed to work with mc_rtc are pre-installed in this image."
echo "To build, use one of the proposed cmake presets:"
echo ""
cd ~/superbuild
cmake --list-presets
echo ""
echo '$ cmake --preset relwithdebinfo # configures cmake and install system dependencies'
echo ""
echo '$ cmake --build --preset relwithdebinfo'
echo '- clones projects in ~/workspace/devel and builds all projects in the superbuild'
echo '- generates a build folder for the superbuild in ~/workspace/build/superbuild'
echo '- generates a build folder for all projects in ~/workspace/build/projects/<project_name>'
echo
echo 'To update all projects in the superbuild, run:'
echo '$ cmake --build --preset relwithdebinfo --target update'
echo '$ cmake --build --preset relwithdebinfo'
echo
echo 'Projects are installed in ~/workspace/install'
echo
echo "Please refer to README.md for more information about the superbuild."
echo ""
echo ""
echo 'After building, please run source ~/workspace/install/setup_mc_rtc.sh'
echo ""
