#!/usr/bin/env bash


### OPTIONS
set -o errexit -o pipefail

### DEFINITIONS
PROG=$(basename "${0}")
VERSION="v1.0.1"
#VERBOSE=1
USER_NAME="${SUDO_USER}"
APT_CMD="apt -y -q -q"
INSTALL_PACKAGES=(
  bat
  curl
  fd-find
  fzf
  git
  neovim
  ripgrep
  wget
  zsh
)


### HELPER FUNCTIONS

function show_help() {
    cat <<EOH
NAME:

  ${PROG}

VERSION:

  ${VERSION}

DESCRIPTION:

  This script runs commands to configure a Raspberry Pi running raspberrypiOS

USAGE:

  ./${PROG}

OPTIONS:

  Options are parsed in no particular order. Options marked as '(required)' are mandatory

    -x --xxxx     : xxxxx (required)


META OPTIONS:

    -f --force    : Force setup. Force reinstallation
    -v --verbose  : Increase output verbosity
    -V --version  : Shows the version number of this script
    -h --help     : Shows the help documentation for this script

EXAMPLES:

  Running init script

    ./${PROG}


EOH
}

function write_error(){
  local error_input="${*}"
  printf "[ERROR]: %s  :(\n" "${error_input}" >&2
  printf "\nRun: '%s --help' to show the help documentation\n\n" "${PROG}"
  exit 1
}

function write_warning(){
  local warning_input="${*}"
  printf "[WARNING]: %s ...  :/\n" "${warning_input}"
}

function write_status(){
  local status_input="${*}"
  printf "[STATUS]: %s ...\n" "${status_input}"
}

function write_verbose(){
  local verbose_input="${*}"
  [[ -n "${VERBOSE}" ]] && printf "[VERBOSE]: %s\n" "${verbose_input}"
}

function write_done(){
  local done_input="${*}"
  printf "[DONE]: %s  ;)\n" "${done_input}"
}

function is_installed(){
  local package="${1}"
  if ! command -v "${package}" >/dev/null 2>&1; then
    # printf "Cannot find command: %s\n" "${package}"
    return 1
  else
    write_verbose "Found command: ${package}"
    return 0
  fi
}

# Function to check if the script is running as root
function is_root(){
  if [[ "$(id -u)" -eq 0 ]]; then
    write_verbose "You are running as root"
    return 0
  else
    write_error "You are not running as root"
  fi
}

### CASE

## Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        # -n | --vm_name)
        #     VM_NAME="$2"
        #     shift
        #     ;;
        -f | --force)
            export FORCE=1
            write_verbose "--force flag set. Forcing installation"
            ;;
        -v | --verbose)
            export VERBOSE=1
            export APT_CMD="apt -y"
            ;;
        -V | --version)
            printf "%s %s\n" "${PROG}" "${VERSION}"
            exit 0
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            write_error "Unknown option: ${1}"
            ;;
    esac
    shift
done


### MAIN

## Check to see if we have all the packages we need
is_installed "apt" || write_error "Are you running RaspberryPiOS? ... Exiting..."
is_installed "sudo" || write_error "Are you running RaspberryPiOS? ... Exiting..."


## Check if we are root
write_status "Checking if running with root privileges"
is_root


## Upgrade system
write_status "Updating system packages"
${APT_CMD} update
write_status "Upgrading system packages"
${APT_CMD} full-upgrade
write_status "Cleaning system packages"
${APT_CMD} autoremove
${APT_CMD} autoclean


## Install packages
write_status "Installing packages: ${INSTALL_PACKAGES[*]}"
${APT_CMD} install "${INSTALL_PACKAGES[@]}"


## Install docker
#if is_installed "docker" && [[ -z "${FORCE}" ]]; then
#  write_error "Docker seems to be already installed. --force is not set"
#elif is_installed "docker" && [[ -n "${FORCE}" ]]; then
#  write_warning "Docker seems to be already installed."
#  write_verbose "Reinstalling anyway due to --force flag"
#  write_status "Reinstalling docker"
#  curl -sSL "https://get.docker.com" | sh
#else
#  write_status "Installing docker"
#  curl -sSL "https://get.docker.com" | sh
#fi


## Create docker group
write_status "Creating docker group"
#usermod -aG docker "${USER_NAME}"


## Done
write_done ""

## Show how to install dotfiles
cat <<EOD

-------------------------------------------------------------------------------
 Install Dotfiles:

   Run the following commands:

     \$  git clone \\
      --bare                                                    \\
      --config status.showUntrackedFiles=no                     \\
      --config core.excludesfile="\${HOME}/.dotfiles/.gitignore" \\
      --recurse-submodules                                      \\
      --verbose --progress                                      \\
      https://github.com/ConnerWill/dotfiles.git "\${HOME}/.dotfiles"

     \$  git --work-tree="\${HOME}" --git-dir="\${HOME}/.dotfiles" checkout --force main && exec zsh


    Alternativly, Run this single line command:

     \$  export DOTFILES="\${HOME}/.dotfiles" ; alias dotf='git --work-tree="\${HOME}" --git-dir="\${DOTFILES}"' ; git clone --bare --config status.showUntrackedFiles=no --config core.excludesfile="\${DOTFILES}/.gitignore" --verbose --progress --recurse-submodules https://github.com/ConnerWill/dotfiles.git "\${DOTFILES}" && git --work-tree="\${HOME}" --git-dir="\${DOTFILES}" checkout --force main && exec zsh

-------------------------------------------------------------------------------

EOD


exit 0
