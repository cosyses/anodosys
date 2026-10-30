#!/usr/bin/env bash
if [[ -f /usr/local/etc/.anodosys ]]; then
  source /usr/local/etc/.anodosys
fi
if [[ ! -v NO_SSH_SERVER ]]; then
  /etc/init.d/ssh stop
fi
