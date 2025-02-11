#!/bin/sh
set -e

on_exit () {
	[ $? -eq 0 ] && exit
	echo 'ERROR: Feature "Neovim" (ghcr.io/duduribeiro/devcontainer-features/neovim) failed to install!'
}

trap on_exit EXIT

set -a
. ../devcontainer-features.builtin.env
. ./devcontainer-features.env
set +a

echo ===========================================================================

echo 'Feature       : Neovim'
echo 'Description   : A feature to install Neovim'
echo 'Id            : ghcr.io/duduribeiro/devcontainer-features/neovim'
echo 'Version       : 1.0.1'
echo 'Documentation : '
echo 'Options       :'
echo '    VERSION="nightly"'
echo 'Environment   :'
printenv
echo ===========================================================================

chmod +x ./install.sh
./install.sh
