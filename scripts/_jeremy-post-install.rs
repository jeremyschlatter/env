// {"deps": ["hashdeep"]} #nix
extern crate dirs;

use anyhow::{anyhow, Result};
use std::{collections::HashSet, fs, io::ErrorKind, os};

fn main() -> Result<()> {
    let home = dirs::home_dir().ok_or(anyhow!("no HOME"))?;
    let nix_conf = home.join(".nix-profile/config");
    let home_conf = home.join(".config");

    // Make ~/.config if it does not yet exist.
    fs::create_dir_all(&home_conf)?;

    let mut want_symlink = HashSet::new();

    // Symlink ~/.nix-profile/config/* into ~/.config.
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

    // Remove old symlinks from ~/.config.
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

    // Build bat cache if bat config changed. (Or we haven't built it before.)
    {
        let bat_config = nix_conf.join("bat");
        let bat_cache = home.join(".cache/bat");
        let config_hash = bat_cache.join("config-hash.txt");
        if !config_hash.exists()
            && duct::cmd!("hashdeep", "-r", "-a", "-k", &config_hash, &bat_config).run().is_ok()
        {
            println!("rebuilding bat cache...");
            fs::create_dir_all(&bat_cache)?;
            fs::write(&config_hash, duct::cmd!("hashdeep", "-r", &bat_config).read()?)?;
            duct::cmd!("bat", "cache", "--build").run()?;
        }
    }

    Ok(())
}
