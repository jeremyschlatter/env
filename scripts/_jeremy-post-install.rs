// {"deps": ["hashdeep"]} #nix
extern crate dirs;

use anyhow::{anyhow, Result};
use std::{collections::HashSet, fs, io::ErrorKind, os, path::Path};

fn ensure_symlink(link_from: &Path, link_to: &Path, description: &str) -> Result<()> {
    match fs::read_link(link_from) {
        Ok(p) if p == link_to => (),
        Ok(p) => println!(
            "I want to install a symlink at {:?}, but it is already symlinked to {:?}",
            link_from, p
        ),
        Err(err) if err.kind() == ErrorKind::NotFound => {
            println!("symlinking {}...", description);
            os::unix::fs::symlink(link_to, link_from)?;
        }
        Err(_) => match fs::metadata(link_from) {
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
    Ok(())
}

// Symlink each entry of `src` into `dst`, and remove symlinks in `dst` that point
// at entries no longer in `src`.
fn link_entries(src: &Path, dst: &Path, kind: &str) -> Result<()> {
    fs::create_dir_all(dst)?;

    let mut want_symlink = HashSet::new();
    for entry in fs::read_dir(src)? {
        let name = entry?.file_name();
        if name == "README.md" {
            continue;
        }
        want_symlink.insert(name.clone());
        ensure_symlink(&dst.join(&name), &src.join(&name), &format!("{:?} {}", name, kind))?;
    }

    for entry in fs::read_dir(dst)? {
        let entry = entry?;
        let name = entry.file_name();
        match fs::read_link(entry.path()) {
            Ok(link) if link.starts_with(src) && !want_symlink.contains(&name) => {
                println!("removing {:?} {}...", name, kind);
                fs::remove_file(entry.path())?;
            }
            _ => (),
        }
    }
    Ok(())
}

fn main() -> Result<()> {
    let home = dirs::home_dir().ok_or(anyhow!("no HOME"))?;

    // Symlink ~/.nix-profile/config/* into ~/.config.
    link_entries(&home.join(".nix-profile/config"), &home.join(".config"), "config")?;

    // Symlink ~/.nix-profile/skills/* into ~/.claude/skills.
    {
        let skills = home.join(".claude/skills");
        // ~/.claude/skills used to be a symlink to the whole skills dir.
        if fs::symlink_metadata(&skills).is_ok_and(|m| m.file_type().is_symlink()) {
            println!("replacing {:?} symlink with a directory...", skills);
            fs::remove_file(&skills)?;
        }
        link_entries(&home.join(".nix-profile/skills"), &skills, "skill")?;
    }

    // Build bat cache if bat config changed. (Or we haven't built it before.)
    {
        let bat_config = home.join(".nix-profile/config/bat");
        let bat_cache = home.join(".cache/bat");
        let config_hash = bat_cache.join("config-hash.txt");
        if !(config_hash.exists()
            && duct::cmd!("hashdeep", "-r", "-a", "-k", &config_hash, &bat_config)
                .stdout_capture()
                .run()
                .is_ok())
        {
            println!("rebuilding bat cache...");
            fs::create_dir_all(&bat_cache)?;
            fs::write(&config_hash, duct::cmd!("hashdeep", "-r", &bat_config).read()?)?;
            duct::cmd!("bat", "cache", "--build").run()?;
        }
    }

    Ok(())
}
