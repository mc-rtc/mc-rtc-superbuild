#!/usr/bin/env bash

if ! command -v brew > /dev/null
then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_BASICS="cmake coreutils gnu-sed ninja git gcc"
brew update || true
brew install ${BREW_BASICS} || true
brew upgrade ${BREW_BASICS} || true
