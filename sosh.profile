# source this file from .profile to add sosh to the PATH

export PATH="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"/bin:"$PATH"
source "$(dirname "${BASH_SOURCE[0]}")"/sosh.bashrc
