#!/usr/bin/env bash
set -e

here="$(dirname "$0")"

#shellcheck source=/dev/null
source "$here"/../service-env.sh

set -x

if [[ $SOSH_CLUSTER = mainnet && $SOSH_CONFIG = primary ]]; then
  if [[ -z $SOSH_WAIT_FOR_SUPERMAJORITY ]]; then
    if [[ -n $SOSH_RESTART_XFERID_FAILOVER_HOSTNAME ]]; then
      "$here"/xferid -f -f $SOSH_RESTART_XFERID_FAILOVER_HOSTNAME

      # Reload config in case `xferid` changed it
      #shellcheck source=/dev/null
      source "$here"/../service-env.sh
    else
      echo Warn: Unable to xferid on primary restart, SOSH_RESTART_XFERID_FAILOVER_HOSTNAME not set
    fi
  else
    echo No xferid on cluster restart
  fi
fi


if [[ -n $SOSH_PERFORMANCE_GOVERNOR ]]; then
  for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance | sudo tee $g; done
  cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
fi

# Delete any zero-length snapshots that can cause validator startup to fail
find ~/ledger/ -name 'snapshot-*' -size 0 -print -exec rm {} \; || true

args=(
  --no-untrusted-rpc
  --gossip-port $SOSH_GOSSIP_PORT
  --dynamic-port-range $SOSH_GOSSIP_PORT-$((SOSH_GOSSIP_PORT + 22))
  --identity $SOSH_VALIDATOR_IDENTITY
  --ledger ~/ledger
  --expected-genesis-hash $SOSH_EXPECTED_GENESIS_HASH
  --limit-ledger-size $SOSH_LIMIT_LEDGER_SIZE
  --contact-debug-interval 120000
  --log ~/solana-validator.log
  #--no-port-check
  #--no-os-cpu-stats-reporting
  #--no-os-memory-stats-reporting
  #--no-os-network-limits-test
  #--no-os-network-stats-reporting
  --private-rpc
  --rpc-bind-address 127.0.0.1
  --rpc-port 8899
  --full-rpc-api
  --rpc-send-leader-count 3 # (default is 2)
  --skip-poh-verify
  --no-poh-speed-test
  --wal-recovery-mode skip_any_corrupted_record
  --full-snapshot-interval-slots 12000
  --maximum-full-snapshots-to-retain 1
  --maximum-incremental-snapshots-to-retain 1
  --no-snapshot-fetch
  --vote-account $SOSH_VALIDATOR_VOTE_ACCOUNT
)

if [[ -n $SOSH_GOSSIP_HOST ]]; then
  args+=(--gossip-host $SOSH_GOSSIP_HOST)
fi

if [[ -n $SOSH_RPC_PUBSUB_ENABLE_VOTE_SUBSCRIPTION ]]; then
  args+=(--rpc-pubsub-enable-vote-subscription)
fi

if [[ -n $SOSH_RPC_PUBSUB_NOTIFICATION_THREADS ]]; then
  args+=(--rpc-pubsub-notification-threads $SOSH_RPC_PUBSUB_NOTIFICATION_THREADS)
fi

if [[ -n $SOSH_ACCOUNTS_INDEX_MEMORY_LIMIT_MB ]]; then
  args+=(
    --accounts-index-memory-limit-mb $SOSH_ACCOUNTS_INDEX_MEMORY_LIMIT_MB
  )
else
  args+=(--disable-accounts-disk-index)
fi


if [[ -r ~/ledger/genesis.bin ]]; then
  args+=(--no-genesis-fetch)
fi

v="$(solana-validator --version)"
echo "Version: $v"
case $v in
*\ 1.14.*|*\ 1.13.*)
  echo Solana 1.14/1.13 detected
  ;;
*\ 1.16.*)
  echo Solana 1.16 detected
  args+=(--replay-slots-concurrently)
  ;;
*\ 1.17.*)
  echo Solana 1.17 detected
  args+=(--replay-slots-concurrently)
  #args+=(--use-snapshot-archives-at-startup when-newest)
  ;;
*\ 1.18.*)
  echo Solana 1.18 detected
  args+=(--replay-slots-concurrently)
  args+=(--block-production-method central-scheduler)
  #args+=(--use-snapshot-archives-at-startup when-newest)
  ;;
*)
  echo Solana 1.19 or greater detected
  args+=(--replay-slots-concurrently)
  #args+=(--use-snapshot-archives-at-startup when-newest)
  ;;
esac

args+=(--no-os-disk-stats-reporting)

if [[ -n $SOSH_AUTHORIZED_VOTER ]]; then
  args+=(--authorized-voter "$SOSH_AUTHORIZED_VOTER")
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

for tv in "${SOSH_KNOWN_VALIDATORS[@]}"; do
  args+=(--known-validator "$tv")
done

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

if [[ -n $JITO ]]; then
  echo Jito detected

  args+=(
    --tip-payment-program-pubkey $TIP_PAYMENT_PROGRAM_PUBKEY
    --tip-distribution-program-pubkey $TIP_DISTRIBUTION_PROGRAM_PUBKEY
    --merkle-root-upload-authority $MERKLE_ROOT_UPLOAD_AUTHORITY
    --commission-bps $COMMISSION_BPS
    --relayer-url $RELAYER_URL
    --block-engine-url $BLOCK_ENGINE_URL
  )
  if [[ -n $SHRED_RECEIVER_ADDR ]]; then
    args+=(--shred-receiver-address $SHRED_RECEIVER_ADDR)
  fi
fi

if [[ -n $SOSH_SLACK_WEBHOOK ]]; then
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$(hostname): $SOSH_CONFIG $SOSH_CLUSTER validator start at $(date): $(solana-validator --version)\"}" \
    $SOSH_SLACK_WEBHOOK || true
fi

exec solana-validator "${args[@]}" "$@"
