# xontrib load fzf-widgets
# $fzf_history_binding = "c-r"

(aliases.update({
  'e': 'exa --classify',
  'ea': 'e --all',
  'ee': 'e --long --header --git',
  'ert': 'e --long --sort time',
  'et': 'e --tree',

  'g': 'git',
  'gst': 'g status',
  'gdiff': 'g diff',
  'gadd': 'g add',

  '"cd.."': 'cd ..',
  'd': 'docker',
  'c': 'gcloud compute',
  'cs': 'gcloud compute instances',

  'gotop': 'gotop -c default-dark',

  'cat': 'bat',

  'vit': 'vi -c ":vsplit term://shell"',

  'x': 'xonsh',

  'clone': lambda args: execx($(github @(args[0]))),
  'dark': lambda: execx($(colorscheme dark)),
  'light': lambda: execx($(colorscheme light)),
}))

execx($(colorscheme restore-colors))

execx($(starship init xonsh))
