#! /usr/bin/env bash

set -euo pipefail

cat << EOF
 _______  _______  __   __  ___   __    _
|   _   ||       ||  | |  ||   | |  |  | |
|  |_|  ||_     _||  | |  ||   | |   |_| |
|       |  |   |  |  |_|  ||   | |       |
|       |  |   |  |       ||   | |  _    |
|   _   |  |   |  |       ||   | | | |   |
|__| |__|  |___|  |_______||___| |_|  |__|

Magical shell history

Atuin setup
https://github.com/ellie/atuin

Please file an issue if you encounter any problems!

===============================================================================

EOF

if ! command -v curl &> /dev/null; then
    echo "curl not installed. Please install curl."
    exit
elif ! command -v sed &> /dev/null; then
    echo "sed not installed. Please install sed."
    exit
fi

LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/ellie/atuin/releases/latest)
# Allow sed; sometimes it's more readable than ${variable//search/replace}
# shellcheck disable=SC2001
LATEST_VERSION=$(echo "$LATEST_RELEASE" | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')

__atuin_install_arch(){
	echo "Arch Linux detected!"

	if command -v pacman &> /dev/null
	then
		echo "Installing with pacman"
		sudo pacman -S atuin
	else
		echo "Attempting AUR install"
		if command -v yaourt &> /dev/null; then
			echo "Found yaourt"
			yaourt -S atuin
		elif command -v yay &> /dev/null; then
			echo "Found yay"
			yay -S atuin
		elif command -v pakku &> /dev/null; then
			echo "Found pakku"
			pakku -S atuin
		elif command -v pamac &> /dev/null; then
			echo "Found pamac"
			pamac install atuin
		else
			echo "Failed to install atuin! Please try manually: https://aur.archlinux.org/packages/atuin-git/"
		fi
	fi

}

__atuin_install_ubuntu(){
	echo "Ubuntu detected"
	# TODO: select correct AARCH too
	ARTIFACT_URL="https://github.com/ellie/atuin/releases/download/$LATEST_VERSION/atuin_${LATEST_VERSION//v/}_amd64.deb"

	TEMP_DEB="$(mktemp)".deb &&
	curl -Lo "$TEMP_DEB" "$ARTIFACT_URL"
	if command -v sudo &> /dev/null; then
		sudo apt install "$TEMP_DEB"
	else
		su -l -c "apt install '$TEMP_DEB'"
	fi
	rm -f "$TEMP_DEB"
}

__atuin_install_mac(){
	echo "Detected Mac!"

	if command -v brew &> /dev/null
	then
		echo "Installing with brew"
		brew install atuin
	else
		echo "Could not find brew, installing with Cargo"
		__atuin_install_unsupported
	fi

}

__atuin_install_termux(){
	echo "Termux detected!"

	if command -v pkg &> /dev/null; then
		echo "Installing with pkg"
		pkg install atuin
	else
		echo "Could not find pkg"
		__atuin_install_unsupported
	fi
}

__atuin_install_cargo(){
	echo "Attempting install with cargo"

	if ! command -v cargo &> /dev/null
	then
		echo "cargo not found! Attempting to install rustup"

		if command -v rustup &> /dev/null
		then
			echo "rustup was found, but cargo wasn't. Something is up with your install"
			exit 1
		fi

		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -q

		echo "rustup installed! Attempting cargo install"

	fi

	cargo install atuin
}

__atuin_install_unsupported(){
	echo "Unknown or unsupported OS"
	echo "Please check the README at https://github.com/ellie/atuin for manual install instructions"
	echo "If you have any problems, please open an issue!"

	while true; do
		read -r -p "Do you wish to attempt an install with 'cargo'? [Y/N] " yn
		case $yn in
			[Yy]* ) __atuin_install_cargo; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

__get_os() {
  if [ -f "/etc/os-release" ]; then
    OS="$(grep -Po '(?<=^ID=).*$' /etc/os-release | tr '[:upper:]' '[:lower:]')" 2>/dev/null
  elif [ -f "/etc/debian_version" ]; then
    OS="debian"
  elif [ -f "/etc/centos-release" ]; then
    OS="centos"
  elif [ -f "/etc/manjaro-release" ]; then
    OS="manjarolinux"
  elif [ -f "/etc/fedora-release" ]; then
    OS="fedora"
  elif [ -f "/etc/arch-release" ]; then
    OS="arch"
  elif [ -f "/etc/gentoo-release" ]; then
    OS="gentoo"
  else
    if uname -r | grep -qi "microsoft"; then
      if [ -f "/etc/os-release" ]; then
        PRETTY_NAME="$(grep -Po '(?<=^PRETTY_NAME=).*$' /etc/os-release | tr -d '"' | tr '[:upper:]' '[:lower:]')"
        case "$PRETTY_NAME" in
          "ubuntu"* ) OS="ubuntu" ;;
          "debian"* ) OS="debian" ;;
          "fedora"* ) OS="fedora" ;;
          # Add more distributions as needed
          * ) OS="unknownwsl" ;;
        esac
      else
        OS="unknownwsl"
      fi
    else
      echo "Unknown"
      exit 1
    fi
  fi
}


__atuin_install() {
  case "$OSTYPE" in
    linux-android*)
      __atuin_install_termux
      ;;
    linux*)
      OS=$(__get_os)
      case "$OS" in
        "arch"|"manjarolinux"|"endeavouros"|"artix"|"manjaro")
          __atuin_install_arch
          ;;
        "ubuntu"|"ubuntuwsl"|"debian"|"linuxmint"|"parrot"|"kali"|"elementary"|"pop")
          __atuin_install_ubuntu
          ;;
        *)
          __atuin_install_unsupported
          ;;
      esac
      ;;
    darwin*)
      __atuin_install_mac
      ;;
    msys*)
      __atuin_install_unsupported
      ;;
    *)
      __atuin_install_unsupported
      ;;
  esac
}


__get_os
# TODO: would be great to support others!
case "$OSTYPE" in
  linux-android*) __atuin_install_termux ;;
  linux*)         __atuin_install ;;
  darwin*)        __atuin_install_mac ;;
  msys*)          __atuin_install_unsupported ;;
  solaris*)       __atuin_install_unsupported ;;
  bsd*)           __atuin_install_unsupported ;;
  *)              __atuin_install_unsupported ;;
esac



case "$SHELL" in
    *bash*)
    		# shellcheck disable=SC2016
        printf '\neval "$(atuin init zsh)"\n' >> ~/.bashrc
        curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o ~/.bash-preexec.sh
        printf '\n[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh\n' >> ~/.bashrc
        # Use of single quotes around $() is intentional here
        # shellcheck disable=SC2016
        echo 'eval "$(atuin init bash)"' >> ~/.bashrc 
        ;;
    *zsh*)
    		# shellcheck disable=SC2086,SC2016
		    printf '\neval "$(atuin init zsh)"\n' >> ${ZDOTDIR:-$HOME}/.zshrc
        echo "Running under zsh"
        ;;
    *)
        echo "Unknown shell"	
        # shellcheck disable=SC2016
		    printf '\neval "$(atuin init zsh)"\n' >> ~/.zshrc
        # shellcheck disable=SC2016
        printf '\neval "$(atuin init zsh)"\n' >> ~/.bashrc
		    curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o ~/.bash-preexec.sh
		    printf '\n[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh\n' >> ~/.bashrc
		    # Use of single quotes around $() is intentional here
		    # shellcheck disable=SC2016
		    echo 'eval "$(atuin init bash)"' >> ~/.bashrc 
        ;;
esac


cat << EOF



 _______  __   __  _______  __    _  ___   _    __   __  _______  __   __ 
|       ||  | |  ||   _   ||  |  | ||   | | |  |  | |  ||       ||  | |  |
|_     _||  |_|  ||  |_|  ||   |_| ||   |_| |  |  |_|  ||   _   ||  | |  |
  |   |  |       ||       ||       ||      _|  |       ||  | |  ||  |_|  |
  |   |  |       ||       ||  _    ||     |_   |_     _||  |_|  ||       |
  |   |  |   _   ||   _   || | |   ||    _  |    |   |  |       ||       |
  |___|  |__| |__||__| |__||_|  |__||___| |_|    |___|  |_______||_______|



Thanks for installing Atuin! I really hope you like it.

If you have any issues, please open an issue on GitHub or visit our Discord (https://discord.gg/dPhv2B3x)!

Otherwise, Atuin is a hobby project - if you find it valuable, you can help us out!

- ⭐️ Give us a star on GitHub (https://github.com/ellie/atuin)
- 🚀 Contribute! We would love more regular contributors (https://github.com/ellie/atuin)
- 🤑 Sponsor me! If you value the project + want to help keep the hosted sync server free (https://github.com/sponsors/ellie)

~ Ellie 🐢💖
EOF
