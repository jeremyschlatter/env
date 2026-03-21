{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "entire";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-Vg0ktRsLooLBqixTyWtAwOnt7lO6RMNcnrOAwtE6U78=";
  };

  postPatch = ''
    sed -i 's/go 1.25.6/go 1.25.5/' go.mod
  '';

  vendorHash = "sha256-bzSJfN77v2huchYZwD8ftBRffVLP4OiZqO++KXj3onI=";

  subPackages = [ "cmd/entire" ];

  ldflags = [ "-s" ];

  meta = with lib; {
    description = "CLI tool that captures AI agent sessions in Git workflows";
    homepage = "https://github.com/entireio/cli";
    license = licenses.mit;
    mainProgram = "entire";
  };
}
