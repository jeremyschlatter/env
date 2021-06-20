# xontrib load fzf-widgets
# $fzf_history_binding = "c-r"

aliases['e'] = 'exa --classify'
aliases['ea'] = 'e --all'
aliases['ee'] = 'e --long --header --git'
aliases['ert'] = 'e --long --sort time'
aliases['et'] = 'e --tree'

aliases['g'] = lambda args: $[git @(args)]
aliases['gst'] = 'g status'
aliases['gdiff'] = 'g diff'
aliases['gadd'] = 'g add'

aliases['"cd.."'] = 'cd ..'
aliases['d'] = 'docker'
aliases['c'] = 'gcloud compute'
aliases['cs'] = 'gcloud compute instances'

aliases['gotop'] = 'gotop -c default-dark'

aliases['cat'] = 'bat'

aliases['vit'] = 'vi -c ":vsplit term://shell"'

aliases['x'] = 'xonsh'

aliases['clone'] = lambda args: execx($(github @(args[0])))
aliases['dark'] = lambda: execx($(colorscheme dark))
aliases['light'] = lambda: execx($(colorscheme light))

# Work around undesired xonsh capture until
# https://github.com/xonsh/xonsh/pull/4283 is merged.
aliases['f'] = lambda: $['$HOME/.nix-profile/bin/f']
aliases['ff'] = lambda: $['$HOME/.nix-profile/bin/ff']

execx($(colorscheme restore-colors))

execx($(/Users/jeremy/src/github.com/starship/starship/target/debug/starship init xonsh))
