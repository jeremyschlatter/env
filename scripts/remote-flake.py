# {"requirements": ["click"]} #nix

import os
import re
import sys
import textwrap

import readline  # noqa: F401

from pathlib import Path
from subprocess import CompletedProcess, check_call, run

import click


def fail(msg: str):
    print(msg, file=sys.stderr)
    try:
        run(["direnv", "deny"])
    except:  # noqa: E722
        sys.exit(1)


def write(path, txt):
    if not txt.endswith("\n"):
        txt += "\n"
    if os.path.exists(path):
        print(f"{path} already exists, skipping it")
        return
    print(f"Creating {path}")
    with open(path, "w") as f:
        f.write(textwrap.dedent(txt).lstrip())


def remote_git(*args, check=True) -> CompletedProcess:
    args = ("git", "-C", flake_dir) + args
    p = run(args)
    if check and p.returncode:
        fail(f"{args} returned {p.returncode}")
    return p


def find_envrc() -> Path | None:
    current = Path.cwd()
    while True:
        envrc = current / ".envrc"
        if envrc.exists():
            return envrc
        if current == current.parent:
            return None
        current = current.parent


if envrc := find_envrc():
    match = re.match(r"use flake (\S+)", envrc.read_text())
    if not match:
        fail(f'Found .envrc at {envrc}, but no "use flake <path>" directive')
    flake_dir = Path(match.group(1))
    click.edit(filename=flake_dir / "flake.nix")
    check_call(["direnv", "exec", ".", "true"])
    if remote_git(
        "diff",
        "--quiet",
        "flake.nix",
        "flake.lock",
        check=False,
    ).returncode:
        remote_git(
            "commit",
            "-m",
            f"update flake: {flake_dir.name}",
            "flake.nix",
            "flake.lock",
        )
        remote_git("push")
else:
    while True:
        flake_name = input("Choose a unique name for the new remote flake: ")
        flake_dir = Path.home() / "src/my/flakes" / flake_name
        if not flake_dir.exists():
            break
        print(f"{flake_dir} is already taken.")

    # TODO: duplicated in flake.py
    flake_dir.mkdir(parents=True)
    write(flake_dir / "flake.nix", """
        {
          inputs = {
            nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
            flake-utils.url = github:numtide/flake-utils;
          };

          outputs = { self, nixpkgs, flake-utils }:
            flake-utils.lib.eachDefaultSystem (system:
            with nixpkgs.legacyPackages.${system};
            let
              scripts = {};
            in {
              devShell = mkShellNoCC {
                packages = lib.attrsets.mapAttrsToList writeShellScriptBin scripts ++ [
                ];
              };
            });
        }
    """)  # noqa: E501
    click.edit(filename=flake_dir / "flake.nix")
    remote_git("add", "flake.nix")
    write(".envrc", f"use flake {flake_dir}")
    check_call(["direnv", "allow"])
    check_call(["direnv", "exec", ".", "true"])

    remote_git(
        "commit",
        "-m",
        f"add flake: {flake_name}",
        "flake.nix",
        "flake.lock",
    )
    remote_git("push")
