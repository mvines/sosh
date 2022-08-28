# source this file from .profile to add sosh to the PATH

SOSH="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
export PATH="$SOSH"/bin:"$PATH"
source "$SOSH"/sosh.bashrc

(
  echo --[ system solana cli ]----------------------------------------
  solana-install info --local
  solana -V

  echo --[ system summary ]--------------------------------------------
  (
    shopt -s nullglob
    export PS4="==> "
    set -x
    hc
    df -h . /mnt/tmpfs*
    ded
    free -h
    uptime
  )

  echo --[ sosh solana version ]------------------------------------
  (
    #shellcheck source=/dev/null
    . "$SOSH"/service-env.sh
  )

  echo --[ keypairs ]--------------------------------------------------
  shopt -s nullglob
  for keypair in ~/*.json; do
    echo "$(basename "$keypair"): $(solana-keygen pubkey "$keypair")"
  done

)
true
