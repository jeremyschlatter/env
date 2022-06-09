# {"requirements": ["click"], "darwinRequirements": ["iterm2"], "deps": ["neovim-remote"]} #nix
import os.path
from subprocess import check_output, run
import sys

import click

if sys.platform == 'darwin':
    import iterm2

#################  entrypoints  #################

@click.group()
def cli():
    pass

@cli.command()
def light():
    set_colors('light')

@cli.command()
def dark():
    set_colors('dark')

@cli.command()
def restore_colors():
    try:
        with open(color_config_path) as f:
            colors = f.read().strip()
    except FileNotFoundError:
        colors = 'light'

    set_colors(colors, restore=True)

#################  helpers  #################

color_config_path = os.path.expanduser('~/.config/colors')

def set_colors(which, restore=False):
    # Set terminal colors.
    #
    # There are several possible terminals I might be in, and the behavior I
    # want is different for each one.
    if os.getenv('VIMRUNTIME'):
        # neovim terminal
        #
        # Do nothing to the terminal, but continue with other changes.
        pass
    elif os.getenv('SSH_TTY'):
        # Connected over ssh.
        #
        # The terminal is therefore not running on this machine, and we
        # will not try to manipulate its colors.
        #
        # Do nothing to the terminal, but continue with other changes.
        pass
    elif 'kitty' in os.getenv('TERM'):
        # kitty
        run(['kitty', '@', 'set-colors', '--configured', '--all', f'~/.nix-profile/config/kitty/{which}.conf', ], check=True)
    elif os.getenv('TERM_PROGRAM') == 'iTerm.app':
        # iterm2
        #
        # We don't need to restore on iterm2, because the color is stored in the profile.
        # And every time we change the color, iterm2 pops up a confirmation box, which
        # we don't want on every new tab and window.
        if not restore:
            async def iterm2_set_colors(connection):
                preset = await iterm2.ColorPreset.async_get(
                    connection,
                    f'Solarized {"Dark" if which == "dark" else "Light"}',
                )
                for partial in (await iterm2.PartialProfile.async_query(connection)):
                    if partial.name in ["Default"]:
                        await partial.async_set_color_preset(preset)
            iterm2.run_until_complete(iterm2_set_colors)
    else:
        print(
            "I don't recognize this terminal, so not trying to change its color.",
            # important to print to stderr, because stdout gets consumed as
            # a shell script
            file=sys.stderr,
        )

    # Set colors in nvim windows.
    for server in check_output(['nvr', '--serverlist'], text=True).strip().splitlines():
        if server.startswith('/'):
            run(['nvr', '--servername', server, '--remote-send', f'<esc>:set bg={which}<cr>'], check=True)

    # Change system theme on Ubuntu.
    if not restore and sys.platform == 'linux':
         run(['gsettings', 'set', 'org.gnome.desktop.interface', 'color-scheme', f'prefer-{which}'], check=True)
         run(['gsettings', 'set', 'org.gnome.desktop.interface', 'gtk-theme', f'Yaru{"-dark" if which == "dark" else ""}'], check=True)

    # Change system theme on macOS.
    if not restore and sys.platform == 'darwin':
        run(['osascript', '-e', f'tell app "System Events" to tell appearance preferences to set dark mode to {"true" if which == "dark" else "false"}'], check=True)

    # Persist for next time.
    # My vim config also reads this file to determine colors on startup.
    with open(color_config_path, 'w') as f:
        f.write(which)

#################  main  #################

if __name__ == '__main__':
    cli()
