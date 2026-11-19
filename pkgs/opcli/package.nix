{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.23.0";
  arch = if stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64";
in

stdenv.mkDerivation {
  pname = "opcli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jeremyschlatter/opcli/releases/download/v${version}/opcli-v${version}-darwin-${arch}.tar.gz";
    hash = "sha256-aDIFmAJtQfKgpekOiFxW3dRqQwhsunC4fVaHnQK/PvU=";
  };

  sourceRoot = ".";

  # Preserve the code signature from the release
  dontFixup = true;

  # opcli only gets at its keychain items when it runs from the signed bundle,
  # which carries its provisioning profile. A symlink into the bundle is fine.
  installPhase = ''
    mkdir -p $out/Applications $out/bin
    cp -R opcli.app $out/Applications/
    ln -s $out/Applications/opcli.app/Contents/MacOS/opcli $out/bin/opcli
  '';

  meta = with lib; {
    description = "Fast 1Password CLI";
    homepage = "https://github.com/jeremyschlatter/opcli";
    license = licenses.mit;
    mainProgram = "opcli";
    platforms = platforms.darwin;
  };
}
