set -eux
curl -L https://nixos.org/nix/install | sh
. $HOME/.nix-profile/etc/profile.d/nix.sh
sudo mkdir -p /etc/nix && echo 'experimental-features = nix-command flakes ca-references' | sudo tee -a /etc/nix/nix.conf
nix profile install github:jeremyschlatter/env
_jeremy-post-install
