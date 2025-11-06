use std::{process::{Command, Stdio}, vec, vec::Vec};
use anyhow::Result;

fn main() -> Result<()> {
    let (shell, fmts) = match std::env::args().nth(1).as_deref() {
        Some("bash") => ("bash", (
            "ghostty.bash",
            "export {k}=\"{v}\"",
            "alias {k}=\"{v}\"",
            "{k}() { eval \"$({v} $1)\" ; }",
            "eval \"$({k} bash)\"",
        )),
        Some("zsh") => ("zsh", (
            "ghostty-integration",
            "export {k}=\"{v}\"",
            "alias {k}=\"{v}\"",
            "{k}() { eval \"$({v} $1)\" ; }",
            "eval \"$({k} zsh)\"",
        )),
        Some("fish") => ("fish", (
            "vendor_conf.d/ghostty-shell-integration.fish",
            "set -gx {k} \"{v}\"",
            "abbr --add {k} \"{v}\"",
            "function {k}; {v} $argv | source; end",
            "{k} fish | source",
        )),
        _ => anyhow::bail!("usage: _jeremy-shell-init <bash|zsh|fish>"),
    };
    fn fmt(f: &str, k: &str, v: &str) {
        println!("{}", f.replace("{k}", k).replace("{v}", v));
    }
    if std::env::var("GHOSTTY_RESOURCES_DIR").is_ok() {
        println!("source $GHOSTTY_RESOURCES_DIR/shell-integration/{}/{}", shell, fmts.0);
    }
    for (k, v) in env(shell).iter() {
        fmt(fmts.1, k, v);
    }
    for (k, v) in aliases().iter() {
        fmt(fmts.2, k, v);
    }
    for (k, v) in eval_wraps().iter() {
        fmt(fmts.3, k, v);
    }
    for k in hooks().iter() {
        fmt(fmts.4, k, "");
    }
    Ok(())
}

fn hooks() -> Vec<&'static str> {
    vec![
        "direnv hook",
        "starship init",
        "atuin init",
        "zoxide init",
    ]
}

fn eval_wraps() -> Vec<(&'static str, &'static str)> {
    vec![
        ("clone", "_gitx github"),
        ("gitlab", "_gitx gitlab"),
    ]
}

fn aliases() -> Vec<(&'static str, &'static str)> {
    vec![
        ("k", "kubectl"),
        ("kg", "kubectl get"),
        ("kgp", "kubectl get pods"),

        ("e",   "exa --classify"),
        ("ea",  "exa --classify --all"),
        ("ee",  "exa --classify --long --header --git"),
        ("ert", "exa --classify --long --sort time"),
        ("et",  "exa --classify --tree"),

        ("g", "git"),
        ("gst", "git status"),
        ("gdiff", "git diff"),
        ("gadd", "git add"),

        ("c",  "gcloud compute"),
        ("cs", "gcloud compute instances"),

        ("cd", "z"),

        ("cd..", "cd .."),
        ("cat",  "bat"),
        ("vit",  "vi -c ':vsplit term://shell'"),
        ("d",    "docker"),

        ("light", "_colorscheme light"),
        ("dark",  "_colorscheme dark"),

        ("ff", "vi $HOME/nix/public-base/flake.nix"),
        ("f", "vi $HOME/nix/public-base/flake.nix && i"),
        ("u", "I_DOT_PY_DO_FULL_UPDATE=1 i"),

        ("gemma", "llm -m gemma3:12b"),
    ]
}

fn env(shell: &'static str) -> Vec<(&'static str, &'static str)> {
    // NOTE: The values here get interpreted by the shell before getting put in the environment.
    // This may or may not be what I want?
    vec![
        ("NIX_PROFILE", "$HOME/.nix-profile"),

        // Use vim for editing.
        ("EDITOR", "vim"),

        // Make git diff, and anything else that pipes through less,
        // display utf-8 characters properly.
        // Credit to http://stackoverflow.com/a/19436421
        ("LESSCHARSET", "UTF-8"),

        ("XDG_DATA_DIRS", "$NIX_PROFILE/share"),

        // https://stackoverflow.com/a/37578829
        ("XDG_DATA_DIRS", "$XDG_DATA_DIRS:/usr/share/ubuntu:/usr/share/gnome:/usr/local/share/:/usr/share/"),

        ("PATH", "$HOME/.npm-global/bin:$PATH"),
        ("PATH", "$NIX_PROFILE/bin:$PATH"),
        ("PATH", "$HOME/go/bin:$PATH"),

        // Don't log starship warnings.
        // (Most common warning: git command timed out in large git directory).
        ("STARSHIP_LOG", "error"),

        // ghostty (and most other terminals) set this by default,
        // but it doesn't get propagated through ssh sessions.
        // So we'll set it again just in case we're running in an ssh session.
        ("COLORTERM", "truecolor"),

        // npm defaults to ~/.npmrc for user config. Need this to get my checked-in config.
        ("NPM_CONFIG_USERCONFIG", "$HOME/.config/npmrc"),

        // with SHELL=fish, nix remote building says
        //   `Couldn't execute fish -c "echo started": No such file or directory`
        // with SHELL= , nix remote building works but nix shell says
        //   `unable to execute '': No such file or directory`
        ("SHELL", shell),

        // Lame that gpg can't figure this out itself, but here we are.
        ("GPG_TTY", "$(tty)"),
    ]
}
