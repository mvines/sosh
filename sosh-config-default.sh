#
# Default local node configuration used if `$HOME/sosh-config.sh` does not
# exist.
#
# To customize:
#   cp sosh-config-default.sh $HOME/sosh-config.sh
#

## Force the performance governor
SOSH_PERFORMANCE_GOVERNOR=x

## Set a custom `--limit-ledger-size`
#SOSH_LIMIT_LEDGER_SIZE=5000000

## Specify `--accounts-index-memory-limit-mb` with this amount
#SOSH_ACCOUNTS_INDEX_MEMORY_LIMIT_MB=10000

## Define a webhook for light notifications
#SOSH_SLACK_WEBHOOK=somewhere

if [[ -z $SOSH_CLUSTER ]]; then
  SOSH_CLUSTER=mainnet
fi

case "$SOSH_CLUSTER" in
mainnet)
  ## Set rpc pubsub thread count to 0 if not using pubsub
  SOSH_RPC_PUBSUB_NOTIFICATION_THREADS=0

  SOSH_EXPECTED_GENESIS_HASH=5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d
  SOSH_EXPECTED_SHRED_VERSION=51382

  #SOSH_WAIT_FOR_SUPERMAJORITY=135986379
  #SOSH_EXPECTED_BANK_HASH=DfRg2DQzWVQjRTBSXwTaYgHDPZbQ85ebLrfayJmMENtp

  SOSH_KNOWN_VALIDATORS=(
    7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2
    GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ
    DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ
  )
  SOSH_KNOWN_VALIDATORS+=(
    XkCriyrNwS3G4rzAXtG5B1nnvb5Ka1JtCku93VqeKAr
    EvnRmnMrd69kFdbLMxWkTn1icZ7DCceRhvmb2SJXqDo4
    DWvDTSh3qfn88UoQTEKRV2JnLt5jtJAVoiCo3ivtMwXP
    Awes4Tr6TX8JDzEhCZY2QVNimT6iD1zWHzf1vNyGvpLM
  )

  SOSH_ENTRYPOINTS=(
    entrypoint.mainnet-beta.solana.com:8001
    entrypoint2.mainnet-beta.solana.com:8001
    entrypoint3.mainnet-beta.solana.com:8001
    entrypoint4.mainnet-beta.solana.com:8001
    entrypoint5.mainnet-beta.solana.com:8001
  )

  SOSH_HEALTH_CHECK_SLOT_DISTANCE=300
  ;;
testnet)
  ## Request `--rpc-pubsub-enable-vote-subscription`. Impacts performance
  SOSH_RPC_PUBSUB_ENABLE_VOTE_SUBSCRIPTION=x

  SOSH_EXPECTED_GENESIS_HASH=4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY
  SOSH_EXPECTED_SHRED_VERSION=24371

  #SOSH_WAIT_FOR_SUPERMAJORITY=144871251
  #SOSH_EXPECTED_BANK_HASH=4NstanApNPjCAd2HwBhHokqCQbJfCAYgp92VvJibSM5M

  SOSH_KNOWN_VALIDATORS=(
    5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on
  )

  SOSH_ENTRYPOINTS=(
    entrypoint.testnet.solana.com:8001
    entrypoint2.testnet.solana.com:8001
    entrypoint3.testnet.solana.com:8001
  )
  SOSH_HEALTH_CHECK_SLOT_DISTANCE=600
  ;;
*)
  echo "Error: Unknown cluster: $SOSH_CLUSTER"
  exit 1
esac

export SOLANA_METRICS_CONFIG=
export RUST_BACKTRACE=1
export RUST_LOG=solana=info
#export RUST_LOG=solana=error
