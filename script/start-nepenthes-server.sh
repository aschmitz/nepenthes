#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "Please run this script as root." 1>&2
  exit 1
fi

cd nepenthes
tmux new-session -s nepenthesserver -n unicorn -d \
  'unicorn_rails -E production'
tmux new-window -t nepenthesserver:1 -n results \
  'sidekiq -e production -c 5 -q results -v'
tmux new-window -t nepenthesserver:1 -n batch \
  'sidekiq -e production -c 1 -q batch -v'

echo -e "\n[*] Go to http://`hostname`:8080/ to load Nepenthes."
