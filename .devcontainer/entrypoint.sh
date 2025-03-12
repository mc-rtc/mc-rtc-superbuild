##!/usr/bin/env bash

echo "------"
echo "Setting up environment variables..."
# Makes GNUPG ask for password in the terminal
export GPG_TTY=$(tty)
echo "GPG_TTY=$GPG_TTY"
export CYTHON_CACHE_DIR=$HOME/.cython
echo "CYTHON_CACHE_DIR=$CYTHON_CACHE_DIR"

echo ""
echo "------"
echo "ccache is configured as follows:"
# Copy cache from the image to the local repository
# This ensures that cache is kept between successive container runs
echo "Synching local .ccache in your workspace with the pre-built cache in the docker image"
rsync -a ~/.cache/ccache/ ~/superbuild/.ccache --exclude='**.tmp.*' --ignore-existing
export CCACHE_DIR=$HOME/superbuild/.ccache
ccache -sv
echo ""

echo "------"
echo "Welcome to mc-rtc-superbuild image for Ubuntu `lsb_release -cs`!"
echo "All the tools needed to work with mc_rtc are pre-installed in this image."
echo "To build, use one of the proposed cmake presets:"
cd ~/superbuild
cmake --list-presets
echo ""
echo '$ cmake --preset relwithdebinfo'
echo "- configures cmake and install system dependencies"
echo ""
echo '$ cmake --build --preset relwithdebinfo'
echo '- clones projects in ./devel and builds all projects in the superbuild'
echo '- generates a build folder for the superbuild in build/relwithdebinfo/superbuild'
echo '- generates a build folder for all projects superbuild in build/relwithdebinfo/projects/<project_name>'
echo
echo 'To update all projects in the superbuild, run:'
echo '$ cmake --build --preset relwithdebinfo --target update'
echo '$ cmake --build --preset relwithdebinfo'
echo
echo 'Projects are installed in ./install/relwithdebinfo'
echo 'After building, please run source ./install/relwithdebinfo/setup_mc_rtc.sh'
echo
echo "Please refer to README.md for more information about the superbuild."
echo ""
