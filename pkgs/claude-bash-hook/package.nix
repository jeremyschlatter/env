{
  lib,
  rustPlatform,
  fetchFromGitHub,
  libclang,
}:

rustPlatform.buildRustPackage {
  pname = "claude-bash-hook";
  version = "0.2.1-macos.3";

  src = fetchFromGitHub {
    owner = "jeremyschlatter";
    repo = "claude-bash-hook";
    rev = "10f003b";
    hash = "sha256-QWYXyNFc3HntMacd1szMv/Z4SKdG3SLFD/zCcUZBZY8=";
  };

  cargoHash = "sha256-TBCPWMq/dbZD6mo5YzPR5vMsmuLdTPBrHMnvRaf1MII=";

  LIBCLANG_PATH = "${libclang.lib}/lib";

  meta = {
    description = "Claude Code PreToolUse hook for fine-grained bash command permissions";
    homepage = "https://github.com/Osso/claude-bash-hook";
    license = lib.licenses.mit;
    mainProgram = "claude-bash-hook";
  };
}
