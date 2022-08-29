#!/usr/bin/env bash

here="$(dirname "$0")"

last=
while true; do
  curr="$(curl -s -m 2 http://127.0.0.1:8899/health || echo fail)"
  if [[ $last != "$curr" ]]; then
    (
      #shellcheck source=/dev/null
      source "$here"/../service-env.sh

      msg="$(hostname): $SOSH_CONFIG $SOSH_CLUSTER health $curr"
      if [[ -n $SOSH_SLACK_WEBHOOK ]]; then
        curl -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"$msg\"}" \
          $SOSH_SLACK_WEBHOOK
      fi
      echo $msg
    )
    last="$curr"
  fi

  sleep 60
done
