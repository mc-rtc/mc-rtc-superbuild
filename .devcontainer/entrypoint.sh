##!/usr/bin/env bash

echo ""
echo "Welcome to mc-rtc-superbuild image for Ubuntu `lsb_release -cs`!"
echo "All the tools needed to work with mc_rtc are pre-installed in this image."
echo "To build, use one of the proposed cmake presets:"
cd ~/workspace/mc-rtc-superbuild
cmake --list-presets
echo ""
echo "Please refer to README.md for more information about the superbuild."
echo ""

# Makes GNUPG ask for password in the terminal
export GPG_TTY=$(tty)
# Ensure cache paths are the same as during docker build
# See https://github.com/amitds1997/remote-nvim.nvim/issues/196 
export CCACHE_DIR=$HOME/.cache/.ccache
export CYTHON_CACHE_DIR=$HOME/.cache/.cython
