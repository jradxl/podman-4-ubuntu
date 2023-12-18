#!/bin/bash

echo "I use RYE to manage my Python environment. If not RYE is not installed I try PIPX to install LASTVERSION"

if [[ $(rye version) ]]; then
   echo "Found RYE, so upgrading RYE and installing LASTVERSION..."
   rye self update
   #rye uninstall lastversion
   #Forcing to ensure latest version of LASTVERSION
   rye install --force lastversion
   lastversion --version
else
  echo "RYE not installed. Installing PIPX as root"
  sudo apt install pipx
  pipx ensurepath
  pipx install lastversion
  $HOME/.local/bin/lastversion --version
  echo "You will need to logout/in to update PATH"
fi

