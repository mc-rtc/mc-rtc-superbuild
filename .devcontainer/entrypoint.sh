##!/usr/bin/env bash

echo ""
echo "Welcome to mc-rtc-superbuild image for Ubuntu `lsb_release -cs`!"
echo "All the tools needed to work with mc_rtc are pre-installed in this image."
echo "To build, use one of the proposed cmake presets:"
cd ~/superbuild
cmake --list-presets
echo ""
echo "Please refer to README.md for more information about the superbuild."
echo ""

# Makes GNUPG ask for password in the terminal
export GPG_TTY=$(tty)
export CYTHON_CACHE_DIR=$HOME/.cython
# Copy cache from the image to the local repository
# This ensures that cache is kept between successive container runs
rsync -av ~/.cache/ccache/ ~/superbuild/.ccache --exclude=**.tmp.* --ignore-existing
export CCACHE_DIR=$HOME/superbuild/.ccache
