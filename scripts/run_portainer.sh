#!/usr/bin/env bash
# https://docs.portainer.io/start/install-ce/server/docker/linux

set -e

PORTAINER_DATA="/portainer/data" ## Can either be a docker volume or a directory
CONTAINER_NAME="portainer"
IMAGE="portainer/portainer-ce:latest"
PORTAINER_PORT_WEB=9443  ## Will be used for host and container
PORTAINER_PORT_DATA=8000 ## Will be used for host and container
# SCRIPT_PATH="$(readlink -f "${0}")"
SCRIPT_DIR="$(dirname "${script_path}")"
ENV_FILE="${SCRIPT_DIR}/env"
ansi_red='\x1B[38;5;196m'
ansi_green='\x1B[38;5;81m'
ansi_reset='\x1B[0m'


function write_error(){
  local input="${*}"
  printf "${ansi_red}[ERROR]: %s${ansi_reset}\n" "${input}"
  return 1
}

function write_success(){
  local input="${*}"
  printf "${ansi_green}[DONE]: %s${ansi_reset}\n" "${input}"
  return 0
}

function is_root(){
  if [[ $(id -u) -ne 0 ]]; then
    write_error "Must be running as root"
  fi
}

function show_stats(){
  local my_hostname="$(hostname --fqdn)"
  local my_ip="$(hostname -I | cut -d' ' -f1)"
  cat <<EOF

  -------------------------------------------------
   Portainer URLs:

     https://${my_hostname}:${PORTAINER_PORT_WEB}
     https://${my_ip}:${PORTAINER_PORT_WEB}

  -------------------------------------------------

EOF
}

is_root

[[ -f "${ENV_FILE}" ]] || touch "${ENV_FILE}"

docker run \
  --detach                                                    \
  --env-file "${ENV_FILE}"                                    \
  --name "${CONTAINER_NAME}"                                  \
  --publish "${PORTAINER_PORT_DATA}":"${PORTAINER_PORT_DATA}" \
  --publish "${PORTAINER_PORT_WEB}":"${PORTAINER_PORT_WEB}"   \
  --restart=always                                            \
  --volume "${PORTAINER_DATA}":/data                          \
  --volume /var/run/docker.sock:/var/run/docker.sock          \
  "${IMAGE}" || write_error "Unable to start portainer docker container" && write_success "Started portainer docker container" && show_stats
