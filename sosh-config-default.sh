#
# Default local node configuration used if `$HOME/sosh-config.sh` does not
# exist.
#
# To customize:
#   cp sosh-config-default.sh $HOME/sosh-config.sh
#

if [[ -z $SOSH_CLUSTER ]]; then
  SOSH_CLUSTER=mainnet
fi

## Force the performance governor
SOSH_PERFORMANCE_GOVERNOR=x

## Set a custom `--limit-ledger-size`
#SOSH_LIMIT_LEDGER_SIZE=5000000

## Specify `--accounts-index-memory-limit-mb` with this amount
#SOSH_ACCOUNTS_INDEX_MEMORY_LIMIT_MB=10000

## Define a webhook for light notifications
#SOSH_SLACK_WEBHOOK=somewhere

## Run `tranny -f -f $SOSH_RESTART_TRANNY_FAILOVER_HOSTNAME` on a restart if
# running `SOSH_CONFIG=primary` and `SOSH_CLUSTER=mainnet`.
#SOSH_RESTART_TRANNY_FAILOVER_HOSTNAME=secondary-server-to-ssh-into
