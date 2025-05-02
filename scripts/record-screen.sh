# {"deps": ["tmux", "ansi2html"]} #nix

SHELL=$(which shell) tmux new '$SHELL; tmux capture-pane -e -S - -E - -p > ~/screen-recording.ansi'
ansi2html < ~/screen-recording.ansi > ~/screen-recording.html
open ~/screen-recording.html
