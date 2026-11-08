#!/usr/bin/env bash
if [[ -f /usr/local/etc/.anodosys ]]; then
  source /usr/local/etc/.anodosys
fi
if [[ ! -v NO_SSH_SERVER ]]; then
  # Alpine has no /etc/init.d/ssh, its OpenSSH routine provides a stop script
  if [[ -x /usr/local/bin/openssh-stop.sh ]]; then
    /usr/local/bin/openssh-stop.sh
  else
    /etc/init.d/ssh stop
  fi
fi
