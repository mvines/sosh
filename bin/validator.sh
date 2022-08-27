#!/usr/bin/env bash
set -e

#shellcheck source=/dev/null
source "$(dirname "$0")"/../service-env.sh

# TODO: Add TRANNY...

set -x

if [[ -n $SOSH_PERFORMANCE_GOVERNOR ]]; then
  for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance | sudo tee $g; done
  cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
fi

# Delete any zero-length snapshots that can cause validator startup to fail
find ~/ledger/ -name 'snapshot-*' -size 0 -print -exec rm {} \; || true

args=(
  --no-untrusted-rpc
  --dynamic-port-range 8000-8022
  --identity ~/validator-identity.json
  --ledger ~/ledger
  --expected-genesis-hash $SOSH_EXPECTED_GENESIS_HASH
  --limit-ledger-size $SOSH_LIMIT_LEDGER_SIZE
  --contact-debug-interval 120000
  --log ~/solana-validator.log
  --no-port-check
  --no-os-memory-stats-reporting
  --no-os-network-stats-reporting
  --no-os-cpu-stats-reporting
  --private-rpc
  --rpc-bind-address 127.0.0.1
  --rpc-port 8899
  --full-rpc-api
  --rpc-threads 4
  --skip-poh-verify
  --no-poh-speed-test
  --wal-recovery-mode skip_any_corrupted_record
  --rocksdb-shred-compaction fifo
  --accounts-db-skip-shrink
  --full-snapshot-interval-slots 12000
  --incremental-snapshots
  --maximum-incremental-snapshots-to-retain 2
  #--maximum-local-snapshot-age 5000
  --no-check-vote-account
  --vote-account ~/validator-vote-account.json
)


if [[ -n $SOSH_RPC_PUBSUB_ENABLE_VOTE_SUBSCRIPTION ]]; then
  args+=(--rpc-pubsub-enable-vote-subscription)

fi

if [[ -n $SOSH_RPC_PUBSUB_NOTIFICATION_THREADS ]]; then
  args+=(--rpc-pubsub-notification-threads $SOSH_RPC_PUBSUB_NOTIFICATION_THREADS)
fi

if [[ -n $SOSH_ACCOUNTS_INDEX_MEMORY_LIMIT_MB ]]; then
  args+=(--accounts-index-memory-limit-mb $SOSH_ACCOUNTS_INDEX_MEMORY_LIMIT_MB)
fi


if [[ -r ~/ledger/genesis.bin ]]; then
  args+=(--no-genesis-fetch)
  args+=(--no-snapshot-fetch)
fi

if [[ $(solana-validator --version) =~ \ 1\.10\. ]]; then
  echo 1.10 detected
else
  echo 1.11 or greater detected
  args+=(--no-os-disk-stats-reporting)
fi

if [[ -n $AUTHORIZED_VOTER ]]; then
  args+=(--authorized-voter "$AUTHORIZED_VOTER")
fi

if [[ -n $SOSH_HEALTH_CHECK_SLOT_DISTANCE ]]; then
  args+=(--health-check-slot-distance $SOSH_HEALTH_CHECK_SLOT_DISTANCE)
fi

if [[ -w /mnt/account1/ ]]; then
  args+=(--accounts /mnt/account1/accounts)
fi
if [[ -w /mnt/account2/ ]]; then
  args+=(--accounts /mnt/account2/accounts)
fi
if [[ -w /mnt/account3/ ]]; then
  args+=(--accounts /mnt/account3/accounts)
fi
if [[ -w /mnt/snapshots/ ]]; then
  args+=(--snapshots /mnt/snapshots)
fi
if [[ -w /mnt/incremental-snapshots/ ]]; then
  args+=(--incremental-snapshot-archive-path /mnt/incremental-snapshots)
fi

for e in "${SOSH_ENTRYPOINTS[@]}"; do
  args+=(--entrypoint "$e")
done

if [[ -n $SOSH_EXPECTED_SHRED_VERSION ]]; then
  args+=(--expected-shred-version "$SOSH_EXPECTED_SHRED_VERSION")
fi

if [[ -n "$SOSH_EXPECTED_BANK_HASH" ]]; then
  args+=(--expected-bank-hash "$SOSH_EXPECTED_BANK_HASH")
  if [[ -n "$SOSH_WAIT_FOR_SUPERMAJORITY" ]]; then
    args+=(--wait-for-supermajority "$SOSH_WAIT_FOR_SUPERMAJORITY")
  fi
elif [[ -n "$SOSH_WAIT_FOR_SUPERMAJORITY" ]]; then
  echo "SOSH_WAIT_FOR_SUPERMAJORITY requires SOSH_EXPECTED_BANK_HASH be specified as well!" 1>&2
  exit 1
fi

for tv in "${SOSH_KNOWN_VALIDATORS[@]}"; do
  args+=(--known-validator "$tv")
done

if [[ -n $SOSH_SLACK_WEBHOOK ]]; then
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$(hostname): $CONFIG $SOSH_CLUSTER validator start at $(date): $(solana-validator --version)\"}" \
    $SOSH_SLACK_WEBHOOK || true
fi

exec solana-validator "${args[@]}"
