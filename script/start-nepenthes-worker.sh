#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "Please run this script as root." 1>&2
  exit 1
fi

cd nepenthes
tmux new-session -s nepenthes -n lomem -d \
  'sidekiq -e sidekiq -c 20 -q lomem_fast -q lomem_slow -v'
tmux new-window -t nepenthes:1 -n himem \
  'sidekiq -e sidekiq -c 2 -q himem_fast -q himem_slow -v'
