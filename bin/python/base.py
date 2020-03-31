import os.path
from subprocess import run
import sys

#################  entrypoints  #################

def pylight():
    set_colors('light')

def pydark():
    set_colors('dark')

def restore_colors():
    try:
        with open(color_config_path) as f:
            colors = f.read().strip()
    except FileNotFoundError:
        colors = 'light'

    set_colors(colors)

def base():
    print('hello from base.py')

#################  helpers  #################

color_config_path = os.path.expanduser('~/.config/colors')

def set_colors(which):
    # kitty set-colors (unless we're in a neovim terminal)
    if not os.getenv('VIMRUNTIME'):
        run(['kitty', '@', 'set-colors', '--configured', '--all', f'~/.nix-profile/config/kitty/{which}.conf', ], check=True)

    # bat config var
    print(f'export BAT_THEME="Solarized ({which})"')

    # persist for next time
    with open(color_config_path, 'w') as f:
        f.write(which)

#################  main  #################

if __name__ == '__main__':
    locals()[os.path.basename(__file__)]()
