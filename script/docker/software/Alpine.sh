#!/bin/sh
# shellcheck shell=bash
# Plain Alpine has no bash, so install it and run this script again with bash
if [ -z "${BASH_VERSION}" ]; then
  apk add --no-interactive bash >/dev/null 2>&1 || { apk update && apk add --no-interactive bash; }
  exec bash "$0" "$@"
fi
set -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help            Show this message
  --containerName   Container to execute the script in
  --openSshVersion  OpenSSH version

Example: ${scriptName} --containerName server --openSshVersion 10.3
EOF
}

openSshVersion=
source "/prepare-parameters.sh"

if [[ -z "${openSshVersion}" ]]; then
  >&2 echo "No OpenSSH version specified!"
  echo ""
  usage
  exit 1
fi

apk update
apk add --no-interactive wget 2>&1

wget -q -O - https://raw.githubusercontent.com/cosyses/app/master/setup.sh | bash

install-package curl
install-package nano
install-package less

# started.sh uses pgrep --ns, which the busybox pgrep lacks
install-package procps-ng

cosyses \
  --applicationName OpenSSH \
  --applicationVersion "${openSshVersion}"

cosyses \
  --applicationName Tini \
  --applicationVersion 0.19

generate-ssh-key
echo "Generated public key:"
get-ssh-public-key
