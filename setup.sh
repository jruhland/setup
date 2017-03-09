#!/bin/sh

fancy_echo() {
  local fmt="$1"; shift
  printf "\n$fmt\n" "$@"
}

append_to_zshrc() {
  local text="$1" zshrc
  local skip_new_line="${2:-0}"

  zshrc="$HOME/.zshrc"

  if ! grep -Fqs "$text" "$zshrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\n" "$text" >> "$zshrc"
    else
      printf "\n%s\n" "$text" >> "$zshrc"
    fi
  fi
}

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

if [ ! -d "$HOME/Projects/" ]; then
  mkdir "$HOME/Projects"
fi

HOMEBREW_PREFIX="/usr/local"

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" /usr/local
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

case "$SHELL" in
  */zsh) : ;;
  *)
    fancy_echo "Changing your shell to zsh ..."
      chsh -s "$(which zsh)"
    ;;
esac

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
    curl -fsS 'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby
    append_to_zshrc 'export PATH="/usr/local/bin:$PATH"' 1
    export PATH="/usr/local/bin:$PATH"
fi

if brew list | grep -Fq brew-cask; then
  fancy_echo "Uninstalling old Homebrew-Cask ..."
  brew uninstall --force brew-cask
fi

fancy_echo "Updating Homebrew formulae ..."
brew update
brew bundle --file=- <<EOF
tap "caskroom/cask"

# Unix
brew "git"

# Tools
brew "hub"
brew "vim"
brew "htop"
brew "heroku-toolbelt"
brew "awscli"
brew "gnupg2"

# Development Tools
cask "iterm2"
cask "alfred"
cask "sizeup"
cask "filezilla"
cask "caffeine"
cask "1password"

# Programming languages
brew "node"
brew "python"
brew "ruby"

# Databases
brew "postgresql", restart_service: true
brew "redis", restart_service: true
brew "rabbitmq", restart_service: true
brew "elasticsearch", restart_service: true

# GUI Based Applications
cask "google-chrome"
cask "firefox"
cask "spotify"
EOF

cp ./dotfiles/.helpers $HOME/

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

pip install --upgrade pip virtualenv virtualenvwrapper
gem install travis

append_to_zshrc "alias fuck='sudo $(fc -nl -1)'"
append_to_zshrc "alias git=hub"
append_to_zshrc "export WORKON_HOME=$HOME/.virtualenvs"
append_to_zshrc "export PROJECT_HOME=$HOME/Projects"
append_to_zshrc "source /usr/local/bin/virtualenvwrapper.sh"
append_to_zshrc "source ~/.helpers"
