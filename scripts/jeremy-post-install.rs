extern crate dirs;

use anyhow::{anyhow, bail, Result};
use std::{collections, fs, io::ErrorKind, os, process};

fn main() -> Result<()> {
    let home = dirs::home_dir().ok_or(anyhow!("no HOME"))?;
    let nix_conf = home.join(".nix-profile/config");
    let home_conf = home.join(".config");

    // Make ~/.config if it does not yet exist.
    fs::create_dir_all(&home_conf)?;

    let mut want_symlink = collections::HashSet::new();

    // Symlink ~/.nix-profile/config/* into ~/.config
    for entry in fs::read_dir(&nix_conf)? {
        let name = entry?.file_name();
        if name == "README.md" {
            continue;
        }
        want_symlink.insert(name.clone());
        let link_from = home_conf.join(&name);
        let have_link = fs::read_link(&link_from);
        let want_link = nix_conf.join(&name);
        match have_link {
            Ok(p) if p == want_link => (), // Nothing more to do.
            Ok(p) => println!(
                "I want to install a symlink at {:?}, but it is already symlinked to {:?}",
                link_from, p
            ),
            Err(err) if err.kind() == ErrorKind::NotFound => {
                println!("symlinking {:?} config...", name);
                os::unix::fs::symlink(want_link, link_from)?;
            }
            Err(_) => match fs::metadata(&link_from) {
                Ok(_) => println!(
                    "I want to install a symlink at {:?}, but there is already something else there.",
                    link_from
                ),
                Err(err) => println!(
                    "I want to install a symlink at {:?}, but I failed to stat the existing file: {}",
                    link_from, err
                ),
            },
        }
    }

    // Remove old symlinks from ~/.config
    for entry in fs::read_dir(&home_conf)? {
        let entry = entry?;
        let name = entry.file_name();
        match fs::read_link(home_conf.join(&name)) {
            Ok(link) if link.starts_with(&nix_conf) && !want_symlink.contains(&name) => {
                println!("removing {:?} config...", name);
                fs::remove_file(entry.path())?;
            }
            _ => (), // doesn't matter
        }
    }

    // Build bat theme
    match fs::metadata(home.join(".cache/bat/themes.bin")) {
        Err(err) if err.kind() == ErrorKind::NotFound => {
            println!("installing solarized theme for bat...");
            if !process::Command::new("bat")
                .args(["cache", "--build"])
                .status()?
                .success()
            {
                bail!("`bat cache --build` failed");
            }
            Ok(())
        }
        _ => Ok(()),
    }
}
