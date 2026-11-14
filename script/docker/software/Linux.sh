#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

Installs Cosyses, OpenSSH and Tini on Debian, RHEL, Fedora or openSUSE.

OPTIONS:
  --help            Show this message
  --containerName   Container to execute the script in
  --openSshVersion  OpenSSH version

Example: ${scriptName} --containerName server --openSshVersion 9.2
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

# setup.sh is downloaded with wget, which the base images of Debian and openSUSE lack
if [[ -x "$(command -v apt-get)" ]]; then
  apt-get update
  DEBIAN_FRONTEND="noninteractive" apt-get install -y wget 2>&1
elif [[ -x "$(command -v dnf)" ]]; then
  dnf install -y wget 2>&1
elif [[ -x "$(command -v zypper)" ]]; then
  zypper --non-interactive install wget 2>&1
else
  >&2 echo "No supported package manager found!"
  exit 1
fi

wget -q -O - https://raw.githubusercontent.com/cosyses/app/master/setup.sh | bash

install-package curl
install-package nano
install-package less

cosyses \
  --applicationName OpenSSH \
  --applicationVersion "${openSshVersion}"

cosyses \
  --applicationName Tini \
  --applicationVersion 0.19

generate-ssh-key
echo "Generated public key:"
get-ssh-public-key
