import os.path

try:
    with open(os.path.expanduser('~/.config/colors')) as f:
        colors = f.read().strip()
except FileNotFoundError:
    colors = 'light'

print(f'export BAT_THEME="Solarized ({colors})"')
