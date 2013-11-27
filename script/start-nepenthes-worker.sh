#!/bin/bash

cd nepenthes
tmux new-session -s nepenthes -n lomem -d \
  'sidekiq -e sidekiq -c 20 -q lomem_fast -q lomem_slow -v'
tmux new-window -t nepenthes:1 -n himem \
  'sidekiq -e sidekiq -c 2 -q himem_fast -q himem_slow -v'