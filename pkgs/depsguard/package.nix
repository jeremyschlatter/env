{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "depsguard";
  version = "0.1.34";

  src = fetchFromGitHub {
    owner = "arnica";
    repo = "depsguard";
    tag = "v${version}";
    hash = "sha256-CVgKE1JrrEiOtv1vyweg0ufkk8Kp/C5FHMXeesoYIgc=";
  };

  cargoHash = "sha256-0GQRuHL5fo0zP52I0BLK+iyDE/ZC47pORynXTz8xMlU=";

  # The integration suites in tests/ shell out to the host's installed package
  # managers (npm, bun, uv, ...), none of which exist in the Nix build sandbox,
  # so run only the binary's own unit tests.
  cargoTestFlags = [ "--bins" ];
  # ...and this unit test writes to a non-writable home in the sandbox.
  checkFlags = [ "--skip=tests::apply_selected_applies_selected" ];

  meta = {
    description = "Harden package manager configs against supply chain attacks";
    homepage = "https://github.com/arnica/depsguard";
    license = lib.licenses.mit;
    mainProgram = "depsguard";
    platforms = lib.platforms.unix;
  };
}
