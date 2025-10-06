extern crate dirs;

use anyhow::{anyhow, bail, Result};
use std::{
    env::consts::OS,
    io::{self, Write},
    process::Command,
    str,
};

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
    Ok(println!("{}", match OS {
        "macos" => {
            // See https://stackoverflow.com/a/25214873
            let x = Command::new("defaults")
                .args(["read", "-g", "AppleInterfaceStyle"])
                .output()?;
            if !x.status.success() {
                "light"
            } else if x.stdout == b"Dark\n" {
                "dark"
            } else {
                let _ = io::stdout().write_all(&x.stdout);
                let _ = io::stderr().write_all(&x.stderr);
                bail!("^ unexpected result from defaults read -g AppleInterfaceStyle")
            }
        }
        "linux" => {
            let scheme = &*Command::new("gsettings")
                .args(["get", "org.gnome.desktop.interface", "color-scheme"])
                .output()?
                .stdout;
            match scheme {
                b"'prefer-light'\n" => "light",
                b"'prefer-dark'\n" => "dark",
                _ => bail!("unexpected color-scheme: {}", String::from_utf8_lossy(scheme))
            }

        },
        _ => bail!("_colorscheme read: not implemented yet on {}", OS),
    }))
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
    Ok(anyhow::ensure!(
        Command::new(cmd).args(args).status()?.success(),
        format!("failed to run {cmd}"),
    ))
}
