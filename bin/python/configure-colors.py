import os.path

try:
    with open(os.path.expanduser('~/.config/colors')) as f:
        colors = f.read().strip()
except FileNotFoundError:
    colors = 'light'

print(colors)
