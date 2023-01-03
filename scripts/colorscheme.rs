// {"deps": ["neovim-remote"]} #nix
extern crate dirs;

use anyhow::{anyhow, bail, ensure, Result};
use clap::{Parser, Subcommand};
use std::{env::{consts::OS, var}, io, fs, path, process::Command, str};

#[derive(Parser)]
struct Cli {
    #[clap(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Dark,
    Light,
    RestoreColors,
    SystemUpdate,
}

fn conf() -> Result<path::PathBuf> {
    Ok(dirs::home_dir().ok_or(anyhow!("no HOME"))?.join(".config/colors"))
}

#[derive(PartialEq, Eq)]
enum Mode {
    CLI,
    System,
    NewShell,
}
use Mode::*;

fn main() -> Result<()> {
    let cli = Cli::parse();

    match &cli.command {
        Commands::Light => {
            set_colors("light", CLI)
        },
        Commands::Dark => {
            set_colors("dark", CLI)
        },
        Commands::RestoreColors => {
            set_colors(
                &(match fs::read_to_string(conf()?) {
                    Ok(s) => s.trim().to_string(),
                    Err(error) => match error.kind() {
                        io::ErrorKind::NotFound => "light".to_string(),
                        other_error => bail!("failed to read ~/.config/colors: {:?}", other_error)
                    },
                }),
                NewShell,
            )
        },
        Commands::SystemUpdate => {
            set_colors(
                if var("DARKMODE") == Ok("1".to_string()) {
                    "dark"
                } else {
                    "light"
                },
                System,
            )
        },
    }
}

fn set_colors(which: &str, mode: Mode) -> Result<()> {
    // Set terminal colors.
    //
    // There are several possible terminals I might be in, and the behavior I
    // want is different for each one.
    if var("VIMRUNTIME").is_ok() {
        // neovim terminal
        //
        // Do nothing to the terminal, but continue with other changes.
    } else if var("SSH_TTY").is_ok() {
        // Connected over ssh.
        //
        // The terminal is therefore not running on this machine, and we
        // will not try to manipulate its colors.
        //
        // Do nothing to the terminal, but continue with other changes.
    } else if mode == System && OS == "linux" || var("TERM").unwrap_or("".to_string()).contains("kitty") {
        // kitty
        run("kitty", &[
            "@", "set-colors",
            "--configured",
            "--all",
            &format!("~/.nix-profile/config/kitty/{which}.conf"),
        ])?
    } else if mode == System && OS == "macos" || var("TERM_PROGRAM") == Ok("iTerm.app".to_string()) {
        // iTerm2
        //
        // Do nothing. As of v3.5+, iTerm2 responds to system color changes itself.
    } else {
        eprintln!("I don't recognize this terminal, so not trying to change its color.");
    }

    if mode == NewShell {
        return Ok(());
    }

    // Set colors in nvim windows.
    let nvim_servers = str::from_utf8(
        &Command::new("nvr")
            .arg("--serverlist")
            .output()?
            .stdout
    )?.trim().to_owned();
    for server in nvim_servers.split("\n") {
        if server.starts_with("/") {
            run("nvr", &[
                "--servername", server,
                "--remote-send", &format!("<esc>:set bg={which}<cr>"),
            ])?
        }
    }

    // Change system theme (unless we are responding to a system change):
    if mode != System {
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
    // My vim config also reads this file to determine colors on startup.
    Ok(fs::write(conf()?, which)?)
}

fn run(cmd: &str, args: &[&str]) -> Result<()> {
    Ok(ensure!(
        Command::new(cmd).args(args).status()?.success(),
        format!("failed to run {cmd}"),
    ))
}
