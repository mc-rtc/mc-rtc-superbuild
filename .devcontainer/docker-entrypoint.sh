#!/bin/bash

# # If the image was built with a custom entrypoint, source it as well
# if [ -f ~/.docker-custom-entrypoint.sh ]; then
#   echo 'echo "--> Using custom entrypoint ~/.docker-custom-entrypoint.sh"' >> ~/.zshrc
#   echo 'source ~/.docker-custom-entrypoint.sh' >> ~/.zshrc
# fi

# Check if zsh is installed
if command -v zsh >/dev/null 2>&1; then
  echo "✅ zsh found, setting as default shell! ..."
  sudo chsh -s /usr/bin/zsh vscode
  if [ "$#" -eq 0 ]; then
    echo "✅ starting zsh"
    exec zsh
  else
    echo "✅ starting zsh with arguments: $@"
    exec zsh "$@"
  fi
  echo "✅ zsh stopped"
fi
