#!/bin/sh

if [ $# -ne 2 ]; then
  echo "Usage: $0 lomem_workers himem_workers"
  exit 1
fi

sidekiq -e sidekiq -c $1 -q lomem_fast -q lomem_slow -d -P /tmp/lomem.pid -L /tmp/lomem.log
sidekiq -e sidekiq -c $2 -q himem_fast -q himem_slow -d -P /tmp/himem.pid -L /tmp/himem.log

sleep infinity
