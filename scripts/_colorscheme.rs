// {"deps": ["neovim-remote"]} #nix
extern crate dirs;

use anyhow::{anyhow, bail, Result};
use std::{env::{consts::OS, var}, fs, process::Command, str};

fn main() -> Result<()> {
    let usage = "usage: _colorscheme <light|dark|system-update>";
    match std::env::args().nth(1).ok_or(anyhow!(usage))?.as_str() {
        "light"         => set_colors("light",        false),
        "dark"          => set_colors("dark",         false),
        "system-update" => set_colors(&var("THEME")?, true),
        _ => bail!(usage),
    }
}

fn set_colors(which: &str, system: bool) -> Result<()> {
    // Change system theme (unless we are responding to a system change):
    if !system {
        if OS == "linux" {
            // Change system theme on Ubuntu.
            run("gsettings", &["set", "org.gnome.desktop.interface", "color-scheme", &format!("prefer-{which}")])?
        } else if OS == "macos" {
            // Change system theme on macOS.
            run("osascript", &["-e", &format!(
                    "tell app \"System Events\" to tell appearance preferences to set dark mode to {}",
                    if which == "dark" { "true" } else { "false" }
            )])?
        }
    }

    // Persist for next time.
    // This file is also used by my configs for vim, bat, and delta.
    Ok(fs::write(dirs::home_dir().unwrap().join(".config/colors"), which)?)
}

fn run(cmd: &str, args: &[&str]) -> Result<()> {
    Ok(anyhow::ensure!(
        Command::new(cmd).args(args).status()?.success(),
        format!("failed to run {cmd}"),
    ))
}
