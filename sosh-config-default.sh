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
