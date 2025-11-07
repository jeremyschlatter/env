extern crate dirs;

use anyhow::{anyhow, bail, Result};
use std::env::consts::OS;

fn main() -> Result<()> {
    let usage = "usage: _colorscheme <light|dark|read>";
    match std::env::args().nth(1).ok_or(anyhow!(usage))?.as_str() {
        "light" => set_colors("light"),
        "dark" => set_colors("dark"),
        "read" => read_theme(),
        _ => bail!(usage),
    }
}

fn read_theme() -> Result<()> {
    Ok(println!(
        "{}",
        match OS {
            "macos" => {
                // See https://stackoverflow.com/a/25214873
                match &*duct::cmd!("defaults", "read", "-g", "AppleInterfaceStyle")
                    .unchecked()
                    .stderr_capture()
                    .read()?
                {
                    "Dark" => "dark",
                    "" => "light",
                    x => bail!(
                        "unexpected result from `defaults read -g AppleInterfaceStyle`:\n{}",
                        x
                    ),
                }
            }
            "linux" => {
                match &*duct::cmd!(
                    "gsettings",
                    "get",
                    "org.gnome.desktop.interface",
                    "color-scheme"
                )
                .read()?
                {
                    "prefer-light" => "light",
                    "prefer-dark" => "dark",
                    x => bail!("unexpected color-scheme: {}", x),
                }
            }
            _ => bail!("_colorscheme read: not implemented yet on {}", OS),
        }
    ))
}

fn set_colors(which: &str) -> Result<()> {
    // Change system theme.
    match OS {
        "linux" =>
            run("gsettings", &["set", "org.gnome.desktop.interface", "color-scheme", &format!("prefer-{which}")]),
        "macos" =>
            run("osascript", &["-e", &format!(
                    "tell app \"System Events\" to tell appearance preferences to set dark mode to {}",
                    if which == "dark" { "true" } else { "false" }
            )]),
        _ => bail!("_colorscheme: not implemented yet on {}", OS),
    }
}

fn run(cmd: &str, args: &[&str]) -> Result<()> {
    duct::cmd(cmd, args).run()?;
    Ok(())
}
