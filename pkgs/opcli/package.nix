{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.21.0";
  arch = if stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64";
in

stdenv.mkDerivation {
  pname = "opcli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jeremyschlatter/opcli/releases/download/v${version}/opcli-v${version}-darwin-${arch}.tar.gz";
    hash = "sha256-JiSluz9D6UAHg+T5fXL9fG5pWRkH70YCYojJLS8SV4M=";
  };

  sourceRoot = ".";

  # Preserve the code signature from the release binary
  dontFixup = true;

  installPhase = ''
    install -Dm755 opcli $out/bin/opcli
  '';

  meta = with lib; {
    description = "Fast 1Password CLI";
    homepage = "https://github.com/jeremyschlatter/opcli";
    license = licenses.mit;
    mainProgram = "opcli";
    platforms = platforms.darwin;
  };
}
