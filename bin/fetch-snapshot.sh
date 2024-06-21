#!/usr/bin/env bash

if [[ -z $1 ]]; then
  echo "Usage: $0 [bv1|bv2|bv3|bv4]"
  echo "Downloads the latest snapshot from a validator"
  exit 0
fi

case $1 in
bv1)
  host=147.28.180.247
  ;;
bv2)
  host=145.40.64.255
  ;;
bv3)
  host=147.28.134.81
  ;;
bv4)
  host=147.28.198.87
  ;;
bw1)
  host=147.28.186.63
  ;;
bw2)
  host=86.109.5.247
  ;;
bw3)
  host=145.40.126.129
  ;;
mapi)
  host=api.mainnet-beta.solana.com
  ;;
tv)
  host=api.testnet.solana.com
  ;;
t)
  host=testnet.solana.com
  ;;
*)
  echo "Error: unknown validator: '$1'"
  exit 1
  ;;
esac

set -ex

if [[ -w /mnt/snapshots/ ]]; then
  cd /mnt/snapshots
else
  cd ~/ledger
fi

if [[ $2 != i ]]; then
  wget --backups=1 --trust-server-names http://$host/snapshot.tar.bz2
fi

if [[ -w /mnt/incremental-snapshots/ ]]; then
  cd /mnt/incremental-snapshots
fi

if [[ $2 != f ]]; then
  wget --backups=1 --trust-server-names http://$host/incremental-snapshot.tar.bz2
fi
