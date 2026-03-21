{
  lib,
  stdenvNoCC,
  fetchzip,
  system,
}:

let
  sources = {
    aarch64-darwin = {
      url = "https://github.com/schpet/linear-cli/releases/download/v1.7.0/linear-aarch64-apple-darwin.tar.xz";
      hash = "sha256-p91XxWEjMz3snxyP8P/JXSOd+LkjXE5Pb4q/hxCxz1A=";
    };
    x86_64-darwin = {
      url = "https://github.com/schpet/linear-cli/releases/download/v1.7.0/linear-x86_64-apple-darwin.tar.xz";
      hash = "sha256-J1gezQoUa22s7zFbP535DNJ8XfgraxKHjig3+3uM5oM=";
    };
    aarch64-linux = {
      url = "https://github.com/schpet/linear-cli/releases/download/v1.7.0/linear-aarch64-unknown-linux-gnu.tar.xz";
      hash = "sha256-dkeIs+ez6CTzAaq+KWoWOIkGlPDsm36SWSv/8UdhD+0=";
    };
    x86_64-linux = {
      url = "https://github.com/schpet/linear-cli/releases/download/v1.7.0/linear-x86_64-unknown-linux-gnu.tar.xz";
      hash = "sha256-b8g41e2Ql7x4ANifOMmUDCeOhkfPeL8MEEywQDaYcnc=";
    };
  };
  src = fetchzip sources.${system};
in
stdenvNoCC.mkDerivation {
  pname = "linear-cli";
  version = "1.7.0";
  inherit src;

  installPhase = ''
    install -Dm755 linear $out/bin/linear
  '';

  meta = {
    description = "A CLI for Linear";
    homepage = "https://github.com/schpet/linear-cli";
    license = lib.licenses.mit;
    mainProgram = "linear";
    platforms = builtins.attrNames sources;
  };
}
