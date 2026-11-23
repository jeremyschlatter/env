{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:

let
  version = "1.0.0-alpha.75";
  # Hashes are the ones upstream publishes at <url>.sha256.
  sources = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      sha256 = "c50d71bde9a8df077ad80da5e3435728e4f718278376f9a08a5c4f16974e90db";
    };
    x86_64-darwin = {
      target = "x86_64-apple-darwin";
      sha256 = "1c642bc4c36ac2c6fd64f4d658951bdc038c8ee9f078b6a59944c3f4f73b04db";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      sha256 = "e3d8f016a2b67e7d5d6a0b810906fd07cfddb67a935939bf172076236d2491b8";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      sha256 = "8dd3dd58f7270c638ad583f3d89dea4695898cce1fcc89fde0b1a404966161eb";
    };
  };
  source = sources.${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "sfcompute";
  inherit version;

  # What https://sfcompute.com/install downloads.
  src = fetchurl {
    url = "https://cli.sfcc.xyz/v${version}/sf-v${version}-${source.target}.tar.gz";
    inherit (source) sha256;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  # Preserve the code signature from the release
  dontFixup = true;

  installPhase = ''
    install -Dm755 sf $out/bin/sf
    installManPage share/man/man1/*.1
    installShellCompletion --cmd sf \
      --bash <($out/bin/sf completion bash) \
      --fish <($out/bin/sf completion fish) \
      --zsh <($out/bin/sf completion zsh)
  '';

  meta = {
    description = "CLI for SF Compute";
    homepage = "https://sfcompute.com";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "sf";
    platforms = builtins.attrNames sources;
  };
}
