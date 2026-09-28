# {"deps": ["coreutils"]} #nix
#
# git's gpg.ssh.program. Signs with my 1Password SSH key via opcli, but if I
# don't approve the Touch ID prompt within the timeout (eg because I'm AFK and
# an agent is committing), the commit is made unsigned instead of failing.
#
# git calls this as: $0 -Y sign -n git -f <pubkeyfile> -U <bufferfile>, and
# reads the signature from <bufferfile>.sig. If that file is empty, git omits
# the gpgsig header entirely, yielding an ordinary unsigned commit.
#
# Killing opcli takes its Touch ID window down with it. (1Password's own
# op-ssh-sign leaves the prompt on screen after the client dies, and fails
# outright when the app isn't running; opcli reads the vault directly.)
#
# git also calls this program for verification (-Y find-principals, -Y verify);
# ssh-keygen handles those natively.
[ "$2" = sign ] || exec ssh-keygen "$@"
status=0
timeout 15 opcli ssh-sign "op://Jeremy/commit signing/private key" "$@" || status=$?
if [ $status -eq 124 ]; then
    # stdout, not stderr: git only relays a signer's stderr when it fails.
    echo "git signing: no Touch ID approval within 15s, committing unsigned"
    : > "${@: -1}.sig"
    exit 0
fi
exit $status
