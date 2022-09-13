# Solana Validator Shell Scripts

This project contains useful scripts for easily running a Solana validator on a fresh Ubuntu 20.04 machine. It uses my ([mvines](https://github.com/mvines)) preferred Solana mainnet settings and best practices. The command names are slightly quirky, and currently not too well documented

## Approximate Clean Machine Setup

### Rust
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Solana Cli
```
sh -c "$(curl -sSfL https://release.solana.com/beta/install)"
```

then restart shell to apply new PATH

### Tuning
View all `journalctl -f` with:
```
sudo adduser sol adm
sudo adduser sol sudo
```

```
sudo bash -c "cat >/etc/sysctl.d/20-solana.conf <<EOF
# Increase UDP buffer size
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728

net.core.optmem_max = 0
net.core.netdev_max_backlog = 0

# Increase memory mapped files limit
vm.max_map_count = 2000000
EOF" && \
sudo sysctl -p /etc/sysctl.d/20-solana.conf
```

```
sudo bash -c "cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
# Increase process file descriptor count limit
* - nofile 2000000
EOF"
```

```
sudo bash -c "cat >/etc/logrotate.d/sol <<EOF
$HOME/solana-validator.log {
  rotate 3
  daily
  missingok
  postrotate
    systemctl kill -s USR1 sol.service
  endscript
}
EOF"
```

### Packages
```
sudo apt-get update
sudo apt-get install -y git htop silversearcher-ag iotop \
  libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang \
  cmake make libprotobuf-dev protobuf-compiler nvme-cli
```

### SSH keygen
```
ssh-keygen -t ed25519 && cat .ssh/id_ed25519.pub
```

### Solana Git Setup
```
for ch in edge beta stable; do \
  git clone https://github.com/solana-labs/solana.git ~/$ch; \
done; \
(cd ~/beta; git checkout v1.14); \
(cd ~/stable; git checkout v1.13); \
ln -sf beta ~/solana
```

### Sosh
```
git clone https://github.com/mvines/sosh ~/sosh
```

then add to your bash config:
```
echo '[ -f $HOME/sosh/sosh.bashrc ] && source $HOME/sosh/sosh.bashrc' >> ~/.bashrc
echo '[ -f $HOME/sosh/sosh.profile ] && source $HOME/sosh/sosh.profile' >> ~/.profile
```

then restart shell

### Sosh Configuration

If you wish to customize the Sosh configuration
```
cat > ~/sosh-config.sh <<EOF
# Start with upstream defaults
source ~/sosh/sosh-config-default.sh

# Local config overrides go here
EOF
```
and adjust as desired

### Build your validator binaries

Pick the "beta" tree with:
```
p beta
```
or perhaps "stable":
```
p stable
```
or even "edge":
```
p edge
```

### Validator keypairs

#### Primary
The primary keypair is what your staked node uses by default.

```
mkdir -p ~/keys/primary
```
then either copy your existing `validator-identity.json` and
`validator-vote-account.json` into that directory or create new ones with
```
solana-keygen new -o ~/keys/primary/validator-identity.json --no-bip39-passphrase -s && \
  solana-keygen new -o ~/keys/primary/validator-vote-account.json --no-bip39-passphrase -s
```

If you wish to activate the primary keypair,
```
sosh-set-config primary
```

#### Secondary
Secondary keypairs are host-specific and used by hot spare machines that can be switched over to
primary at runtime. Once your primary keypair is configured, run

```
mkdir -p ~/keys/secondary && \
  solana-keygen new -o ~/keys/secondary/validator-identity.json --no-bip39-passphrase -s
```

If you wish to activate the secondary keypair,
```
sosh-set-config secondary
```

Later run `tranny <secondary-host>` from your primary to transfer voting to the
secondary.

#### Other keypairs...

Any string other than `primary` and `secondary` may be used to configure other keypairs for dev and testing.
For example to configure a `dev` keypair:

```
mkdir -p ~/keys/dev && \
  solana-keygen new -o ~/keys/dev/validator-identity.json --no-bip39-passphrase -s && \
  solana-keygen new -o ~/keys/dev/validator-vote-account.json --no-bip39-passphrase -s
```

If you wish to activate the dev keypair,
```
sosh-set-config dev
```

#### Maybe Setup tmpfs
Depending on RAM size add an entry like this to `/etc/fstab`:

128GB RAM machine:
```
tmpfs /mnt/tmpfs tmpfs rw,size=32G,user=ops,noatime 0 0
```
256GB RAM machine:
```
tmpfs /mnt/tmpfs tmpfs rw,size=128G,user=ops,noatime 0 0
```
512GB RAM machine:
```
tmpfs /mnt/tmpfs tmpfs rw,size=256G,user=ops,noatime 0 0
```
then
```
sudo mkdir /mnt/tmpfs
sudo mount /mnt/tmpfs
```

#### Recommended tmpfs configuration
* 128GB RAM: incremental snapshots
* 256GB RAM: incremental snapshots, accounts
* 512GB RAM: : incremental snapshots, full snapshots, accounts

#### Maybe Adjust FileSystem Usage

##### rocksdb filesystem

Assuming `/mnt/ledger-rocksdb` is the desired location for rocksdb, such as a
separate nvme:
```
mkdir -p ~/ledger/
ln -sf /mnt/ledger-rocksdb/level ~/ledger/rocksdb
ln -sf /mnt/ledger-rocksdb/fifo ~/ledger/rocksdb_fifo
```

##### accounts filesystem(s)

If present the `/mnt/accounts1`, `/mnt/accounts2`, and `/mnt/accounts3`
locations will be added as an `--account` arg to validator startup.

If none are present, accounts will be placed in the default location of
`~/ledger/accounts`

Example of putting all accounts in tmpfs:
```
sudo ln -s /mnt/tmpfs /mnt/account1
```

Example of putting 50% of accounts in tmpfs, 50% on a separate drive:
```
sudo ln -s /mnt/tmpfs /mnt/account1
sudo ln -s /mnt/nvme2 /mnt/account2
```

##### snapshot filesystems

If not present, snapshots will be placed in the default location of `~/ledger`

Example of putting all snapshots in tmpfs:
```
sudo ln -s /mnt/tmpfs /mnt/snapshots
```

Example of putting incremental snapshots in tmpfs, full snapshots in default
location:
```
sudo ln -s /mnt/tmpfs /mnt/incremental-snapshots
```

Note that when snapshots are placed in tmpfs you will need to manually recover
the validator if the system ever reboots by running `fetch-snapshot.sh` with
usable args.

### Start the node manually to initialize the ledger
```
validator.sh init
```
then monitor logs with `t`. This will prepare ~/ledger and download the correct
genesis config for the cluster.

### Fetch a current snapshot

Use `fetch_snapshot.sh` to get a snapshot from a specific node.

* Mainnet NA-based nodes, try `fetch_snapshot.sh bv1` or `fetch_snapshot.sh bv2`.
* Mainnet EU-based nodes, try `fetch_snapshot.sh bv3`
* Mainnet Asia-based nodes, try `fetch_snapshot.sh bv4`
* Testnet, try `fetch_snapshot.sh tv`


### Start the sol service

```
sudo bash -c "cat >/etc/systemd/system/sol.service <<EOF
[Unit]
Description=Solana Validator
After=network.target
StartLimitIntervalSec=0
Wants=sol-hc.service

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
LimitNOFILE=2000000
LogRateLimitIntervalSec=0
ExecStart=$HOME/sosh/bin/validator.sh

[Install]
WantedBy=multi-user.target
EOF" &&

sudo bash -c "cat >/etc/systemd/system/sol-hc.service <<EOF
[Unit]
Description=Solana Validator Healthcheck
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
ExecStart=$HOME/sosh/bin/hc-service.sh

[Install]
WantedBy=multi-user.target
EOF" && sudo systemctl daemon-reload
```

then run:
```
soshr          # Sosh alias for `sudo systemctl restart sol sol-hc`
```
and monitor with:
```
jf            # Sosh alias for `journalctl -f`
```
and
```
t
```
