#!/bin/bash

set -e # make script fail early in case of error

if [ "$BUILD_SUPERBUILD" != "true" ]; then
  echo "SUPERBUILD: Skipping build because BUILD_SUPERBUILD=$BUILD_SUPERBUILD"
else
  ./utils/bootstrap-linux.sh
  git config --global user.email "$EMAIL" && git config --global user.name "$NAME"

  # CMake configure will install all APT/PIP dependencies (keep downloaded packages in mounted APT cache)
  # Check if there is an existing ccache from a previous build
  echo "CCACHE: Clean stats"
  ccache -z
  echo "CCACHE: Checking ccache stats:"
  ccache -sv
  echo "CCACHE: Checking ccache size:"
  du -hs $CCACHE_DIR

  # Configure the chosen superbuild preset
  echo "SUPERBUILD: Configuring superbuild with preset $CMAKE_PRESET"
  cmake --preset $CMAKE_PRESET
  # Build the whole superbuild
  echo "SUPERBUILD: Building the superbuild"
  cmake --build --preset $CMAKE_PRESET

  echo "CCACHE: Checking ccache contents after build:"
  ccache -sv

  # Always copy ccache to image directory for potential use
  echo "CCACHE: Moving the generated ccache cache to the image folder $CCACHE_IMAGE_DIR"
  mkdir -p $CCACHE_IMAGE_DIR
  sudo chown vscode $CCACHE_IMAGE_DIR
  cp -r $CCACHE_BUILD_DIR/* $CCACHE_IMAGE_DIR
fi

# Basic cleanup only
rm -f ~/.gitconfig
sudo rm -rf /var/lib/apt/lists/*

echo "SUPERBUILD: Build completed. All files preserved for multi-stage Docker build."
