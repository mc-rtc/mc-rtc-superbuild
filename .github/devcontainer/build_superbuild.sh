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
  if [ "$IS_KEEP_CCACHE" = "true" ]; then
    echo "CCACHE: Moving the generated ccache cache to the image folder $CCACHE_IMAGE_DIR so that it can be used at runtime"
    mkdir -p $CCACHE_IMAGE_DIR
    sudo chown vscode $CCACHE_IMAGE_DIR
    cp -r $CCACHE_BUILD_DIR/* $CCACHE_IMAGE_DIR
  fi
fi

# Cleanup files to leave in the container
# Set default values for IS_KEEP_* depending on BUILD_VERSION
IS_KEEP_CATKIN_DEVEL="false"
# Devcontainer: no sources and install, keep only ccache folder
# for quick builds. The user is expected to mount the corresponding superbuild folder
# and a workspace folder
if [ "${BUILD_VERSION}" = "devcontainer" ]; then
  IS_KEEP_SOURCES="${KEEP_SOURCES:-false}"
  IS_KEEP_BUILD="${KEEP_BUILD:-false}"
  IS_KEEP_INSTALL="${KEEP_INSTALL:-false}"
  IS_KEEP_CCACHE="${KEEP_CCACHE:-true}"
# Full image with developpement and install
# This allows full reproducibility of the build environment
# The image is likely to be huge >10Gb
elif [ "${BUILD_VERSION}" = "standalone-devel" ]; then
  IS_KEEP_SOURCES="${KEEP_SOURCES:-true}"
  IS_KEEP_BUILD="${KEEP_BUILD:-true}"
  IS_KEEP_INSTALL="${KEEP_INSTALL:-true}"
  IS_KEEP_CCACHE="${KEEP_CCACHE:-true}"
  IS_KEEP_CATKIN_DEVEL="true"
else # standalone-release (install files only)
  IS_KEEP_SOURCES="${KEEP_SOURCES:-false}"
  IS_KEEP_BUILD="${KEEP_BUILD:-false}"
  IS_KEEP_INSTALL="${KEEP_INSTALL:-true}"
  IS_KEEP_CCACHE="${KEEP_CCACHE:-false}"
  # Needed for robot_description packages and other ros tools
  IS_KEEP_CATKIN_DEVEL="true"
fi

echo "  IS_KEEP_SOURCES=${IS_KEEP_SOURCES}"
echo "  IS_KEEP_BUILD=${IS_KEEP_BUILD}"
echo "  IS_KEEP_INSTALL=${IS_KEEP_INSTALL}"
echo "  IS_KEEP_CCACHE=${IS_KEEP_CCACHE}"
echo "  IS_KEEP_CATKIN_DEVEL=${IS_KEEP_CATKIN_DEVEL}"

if [ "$IS_KEEP_SOURCES" = "false" ]; then
  echo "CLEAN: Removing sources in ${WORKSPACE_DEVEL_DIR}"
  if [ "$IS_KEEP_CATKIN_DEVEL" = "true" ]; then
    echo "CLEAN: but keeping catkin workspaces"
    find ${WORKSPACE_DEVEL_DIR} -mindepth 1 -not -path "${WORKSPACE_DEVEL_DIR}/catkin_ws" -not -path "${WORKSPACE_DEVEL_DIR}/catkin_ws/*" -not -path "${WORKSPACE_DEVEL_DIR}/catkin_data_ws" -not -path "${WORKSPACE_DEVEL_DIR}/catkin_data_ws/*" -delete
    # Remove empty directories
    # find ${WORKSPACE_DEVEL_DIR} -type d -empty -delete
  else
    echo "CLEAN: removing catkin workspaces"
    rm -rf ${WORKSPACE_DEVEL_DIR}
  fi
  echo "CLEAN: Removing superbuild in ${SUPERBUILD_DIR}"
  rm -rf ${SUPERBUILD_DIR}
fi
if [ "$IS_KEEP_BUILD" = "false" ]; then
  echo "CLEAN: Removing build in ${WORKSPACE_BUILD_DIR}"
  rm -rf ${WORKSPACE_BUILD_DIR}
fi
if [ "$IS_KEEP_INSTALL" = "false" ]; then
  echo "CLEAN: Removing install in ${WORKSPACE_INSTALL_DIR}"
  rm -rf ${WORKSPACE_INSTALL_DIR}
fi
if [ -d $WORKSPACE_DIR ] && [ -z "$(ls -A $WORKSPACE_DIR 2>/dev/null)" ]; then
  echo "CLEAN: Removing the empty $WORKSPACE_DIR folder"
  rmdir $WORKSPACE_DIR
fi

# Further cleanup
rm -f ~/.gitconfig
sudo rm -rf /var/lib/apt/lists/*
