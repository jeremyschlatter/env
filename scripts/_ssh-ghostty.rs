use anyhow::{anyhow, Result};
use std::{collections::HashSet, env, fs, process::ExitCode};

fn main() -> Result<ExitCode> {
    let args: Vec<String> = env::args().skip(1).collect();

    // Extract the host from args (first arg that doesn't start with '-' and isn't an option value)
    let host = extract_host(&args).ok_or(anyhow!("no host specified"))?;

    // Determine cache file path
    let cache_dir = dirs::cache_dir().ok_or(anyhow!("no cache dir"))?;
    let cache_file = cache_dir.join("ssh-ghostty-hosts.txt");

    // Load known hosts
    let mut known_hosts: HashSet<String> = fs::read_to_string(&cache_file)
        .unwrap_or_default()
        .lines()
        .map(String::from)
        .collect();

    // If this is a new host, install the terminfo first
    if !known_hosts.contains(&host) {
        eprintln!("ssh-ghostty: installing terminfo on {}...", host);
        let result = duct::cmd!("infocmp", "-x", "xterm-ghostty")
            .pipe(duct::cmd!("ssh", &host, "--", "tic", "-x", "-"))
            .run();
        if result.is_ok() {
            known_hosts.insert(host.clone());
            fs::create_dir_all(&cache_dir)?;
            fs::write(&cache_file, known_hosts.into_iter().collect::<Vec<_>>().join("\n"))?;
        } else {
            eprintln!("ssh-ghostty: failed to install terminfo, continuing anyway");
        }
    }

    // Run ssh with original args, replacing this process
    let err = exec::execvp("ssh", &std::iter::once("ssh".to_string()).chain(args).collect::<Vec<_>>());
    Err(anyhow!("exec failed: {}", err))
}

fn extract_host(args: &[String]) -> Option<String> {
    // Skip options and their values to find the destination
    let mut i = 0;
    while i < args.len() {
        let arg = &args[i];
        if arg == "--" {
            // Everything after -- is the command, host must be before
            return None;
        }
        if arg.starts_with('-') {
            // Options that take a value
            if matches!(arg.as_str(), "-b" | "-c" | "-D" | "-E" | "-e" | "-F" | "-I" | "-i" |
                       "-J" | "-L" | "-l" | "-m" | "-O" | "-o" | "-p" | "-Q" | "-R" | "-S" |
                       "-W" | "-w") {
                i += 2; // Skip option and its value
                continue;
            }
            i += 1; // Skip flag-only option
            continue;
        }
        // This is the destination (possibly user@host)
        return Some(arg.clone());
    }
    None
}
