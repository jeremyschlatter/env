set -eux
curl -L https://nixos.org/nix/install | sh
. $HOME/.nix-profile/etc/profile.d/nix.sh
nix-env -iAf https://github.com/NixOS/nixpkgs/tarball/release-21.05 nixUnstable
sudo mkdir -p /etc/nix && echo 'experimental-features = nix-command flakes ca-references' | sudo tee -a /etc/nix/nix.conf
nix profile install github:jeremyschlatter/nixpkgs#lite
