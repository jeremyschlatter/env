# Jeremy's Dev Environment

This repo manages Jeremy's global dev environment via Nix.

## Structure

- `flake.nix` — Main flake; defines packages to install and helper functions
- `scripts/` — Custom utility scripts (Python, Rust, Bash, JS)
- `scripts.nix` — Builds scripts into Nix packages
- `config/` — Config files for various tools (git, nvim, zsh, ghostty, etc.)
- `skills/` — Claude Code skills

## Testing Scripts

Individual scripts can be built and run without rebuilding the full environment:

```bash
nix build '.#<script-name>'
nix run '.#<script-name>' -- <args>
```

Where `<script-name>` is the name of the script without its file extension,
eg `model` rather than `model.py`. When scripts are installed in the global
dev environment, they are installed without a file extension.

## Pushing Changes

`git push` doesn't work due to a config issue. Use:

```bash
git push lol && git pull
```

## Dev Environment Skill

@skills/dev-env/SKILL.md
