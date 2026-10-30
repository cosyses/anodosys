#!/usr/bin/env bash
if [[ -f /usr/local/etc/.anodosys ]]; then
  source /usr/local/etc/.anodosys
fi
if [[ ! -v NO_COSYSES_UPDATE ]]; then
  cosyses update
fi
