# {"deps": ["mypy"]} #nix
mypy "$1" && python "$1"
