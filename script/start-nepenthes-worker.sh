#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "Please run this script as root." 1>&2
  exit 1
fi

echo -e "\n[*] Checking for Redis..."
echo -en "PING\r\n" | nc -w 5 127.0.0.1 6379 | grep -q PONG
if [ $? -ne 0 ]; then
  echo "Couldn't detect Redis on localhost." \
    "Try SSHing to this worker like this:"
  echo "ssh -R 127.0.0.1:6379:127.0.0.1:6379 [user]@[host]"
  exit 1
fi
echo "Redis works."

cd nepenthes
tmux new-session -s nepenthes -n lomem -d \
  'sidekiq -e sidekiq -c 20 -q lomem_fast -q lomem_slow -v'
tmux new-window -t nepenthes:1 -n himem \
  'sidekiq -e sidekiq -c 2 -q himem_fast -q himem_slow -v'

echo -e "\n[*] Nepenthes worker running."
