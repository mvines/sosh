# source this to setup the sosh service environment

if [ -f ~/sosh-config.sh ]; then
  source ~/sosh-config.sh
else
  source "$(dirname "${BASH_SOURCE[0]}")"/sosh-config-default.sh
fi

if [[ ! -d ~/solana/.git ]]; then
  echo "Error: ~/solana/.git does not exist"
  exit 1
elif [[ ! -x ~/solana/rel/bin/solana-validator ]]; then
  echo "Error: Validator binary not found in ~/solana/rel/bin, consider running:"
  echo
  echo "  $SOLANA_ROOT/scripts/cargo-install-all.sh --validator-only ~/solana/rel"
  echo
  exit 1
fi

export PATH=~/solana/rel/bin:"$PATH"
SOLANA_ROOT="$(readlink -f ~/solana)"
echo "$(solana --version): $SOLANA_ROOT"

