#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "Please run this script as root." 1>&2
  exit 1
fi

cd nepenthes
tmux new-session -s nepenthesserver -n unicorn -d \
  'bundle exec unicorn_rails -E production -c config/unicorn.rb'
tmux new-window -t nepenthesserver:1 -n results \
  'bundle exec sidekiq -e production -c 5 -q results -v'
tmux new-window -t nepenthesserver:2 -n batch \
  'bundle exec sidekiq -e production -c 1 -q batch -v'

echo -e "\n[*] Go to http://`hostname`:8080/ to load Nepenthes."
