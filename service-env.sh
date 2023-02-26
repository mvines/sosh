# source this to setup the sosh service environment

if [[ -z $SOSH_SKIP_SOLANA_SOURCE_CHECK ]]; then
  [[ -d ~/solana/.git ]] || {
    echo "Error: ~/solana/.git does not exist";
    exit 1
  }

  [[ -x ~/solana/rel/bin/solana-validator ]] || {
    echo "Error: ~/solana/rel/bin/solana-validator not found"
    exit 1
  }
  export PATH=~/solana/rel/bin:"$PATH"
fi

[[ -L ~/active-key ]] || {
  echo "Error: No active key"
  exit 1
}

if [[ -d ~/solana/jito-programs ]]; then
  JITO=1
fi

SOSH_CONFIG="$(basename "$(readlink ~/active-key)")"


SOSH_VALIDATOR_IDENTITY=~/keys/"$SOSH_CONFIG"/validator-identity.json
if [[ $SOSH_CONFIG = secondary ]]; then
  SOSH_VALIDATOR_VOTE_ACCOUNT=~/keys/primary/validator-vote-account.json
  SOSH_AUTHORIZED_VOTER=~/keys/primary/validator-identity.json
else
  SOSH_VALIDATOR_VOTE_ACCOUNT=~/keys/"$SOSH_CONFIG"/validator-vote-account.json
fi

export SOLANA_METRICS_CONFIG=
export RUST_BACKTRACE=1
if [[ -z $RUST_LOG ]]; then
  export RUST_LOG=solana=info
fi

if [ -f ~/sosh-config.sh ]; then
  source ~/sosh-config.sh
else
  source "$(dirname "${BASH_SOURCE[0]}")"/sosh-config-default.sh
fi

case "$SOSH_CLUSTER" in
mainnet)
  SOSH_EXPECTED_GENESIS_HASH=5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d
  SOSH_EXPECTED_SHRED_VERSION=56177

  #SOSH_EXPECTED_BANK_HASH=69p75jzzT1P2vJwVn3wbTVutxHDcWKAgcbjqXvwCVUDE
  #SOSH_WAIT_FOR_SUPERMAJORITY=179526403

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

  # Ref: https://jito-labs.gitbook.io/mev/validators/command-line-arguments#mainnet-arguments
  TIP_PAYMENT_PROGRAM_PUBKEY=T1pyyaTNZsKv2WcRAB8oVnk93mLJw2XzjtVYqCsaHqt
  TIP_DISTRIBUTION_PROGRAM_PUBKEY=4R3gSG8BpU4t19KYj8CfnbtRpnT8gtk4dvTHxVRwc2r7
  MERKLE_ROOT_UPLOAD_AUTHORITY=GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib
  : ${COMMISSION_BPS:=800}

  # `~/sosh-config.sh` may override the default Jito config if desired
  #
  # See https://jito-labs.gitbook.io/mev/systems/connecting/mainnet
  if [[ -z $BLOCK_ENGINE_URL ]]; then
    BLOCK_ENGINE_URL=https://frankfurt.mainnet.block-engine.jito.wtf
    RELAYER_URL=http://frankfurt.mainnet.relayer.jito.wtf
    #SHRED_RECEIVER_ADDR=145.40.93.84:1002
  fi

  if [[ -z $SOSH_RPC_URL ]]; then
    SOSH_RPC_URL=m
  fi
  ;;
testnet)
  ## Request `--rpc-pubsub-enable-vote-subscription`. Impacts performance
  SOSH_RPC_PUBSUB_ENABLE_VOTE_SUBSCRIPTION=x

  SOSH_EXPECTED_GENESIS_HASH=4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY
  SOSH_EXPECTED_SHRED_VERSION=6995

  SOSH_KNOWN_VALIDATORS=(
    5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on
  )

  SOSH_ENTRYPOINTS=(
    entrypoint.testnet.solana.com:8001
    entrypoint2.testnet.solana.com:8001
    entrypoint3.testnet.solana.com:8001
  )

  if [[ -z $SOSH_RPC_URL ]]; then
    SOSH_RPC_URL=t
  fi

  # Ref: https://jito-labs.gitbook.io/mev/validators/command-line-arguments#testnet-arguments
  TIP_PAYMENT_PROGRAM_PUBKEY=7JCWzUcPQvA4PHAWzeckkDgfCMZHu9c42LzULg6cC2N8
  TIP_DISTRIBUTION_PROGRAM_PUBKEY=FhKaSCWdhK86Mbccwtz7xvfqQpjbrmWgsHExrXbmAzVW
  MERKLE_ROOT_UPLOAD_AUTHORITY=GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib

  : ${COMMISSION_BPS:=800}
  # `~/sosh-config.sh` may override the default Jito config if desired
  # See https://jito-labs.gitbook.io/mev/systems/connecting/testnet
  if [[ -z $BLOCK_ENGINE_URL ]]; then
    BLOCK_ENGINE_URL=https://dallas.testnet.block-engine.jito.wtf
    RELAYER_URL=http://dallas.testnet.relayer.jito.wtf
    #SHRED_RECEIVER_ADDR=147.28.154.132:1002
  fi
  ;;
*)
  echo "Error: Unknown cluster: $SOSH_CLUSTER"
  exit 1
esac
