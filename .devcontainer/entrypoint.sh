##!/usr/bin/env bash

echo "Welcome to mc-rtc-superbuild image for Ubuntu `lsb_release -cs`!"
echo "All the tools needed to work with mc_rtc are pre-installed in this image."
echo "To build, use one of the proposed cmake presets:"
cd ~/workspace/mc-rtc-superbuild
cmake --list-presets

exec "$@"
