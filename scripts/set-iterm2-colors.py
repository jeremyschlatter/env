# {"requirements": ["click"], "darwinRequirements": ["iterm2"]} #nix

import click
import iterm2

@click.group()
def cli():
    pass

@cli.command()
def light():
    set_colors('light')

@cli.command()
def dark():
    set_colors('dark')

def set_colors(which):
    async def iterm2_set_colors(connection):
        preset = await iterm2.ColorPreset.async_get(
            connection,
            f'Solarized {"Dark" if which == "dark" else "Light"}',
        )
        for partial in (await iterm2.PartialProfile.async_query(connection)):
            if partial.name in ["Default"]:
                await partial.async_set_color_preset(preset)
    iterm2.run_until_complete(iterm2_set_colors)

if __name__ == '__main__':
    cli()
