{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "daylight";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "jbreckmckye";
    repo = "daylight";
    rev = "v${version}";
    hash = "sha256-vvWbA1yWzvcMAQz5lpTmwkwWmv5KoPppSKMzNm5dEdU=";
  };

  vendorHash = "sha256-a/Kn9eAl7duijc8dzv2FfW7Ss0T9gjh0vJ8qqFJvt1A=";

  ldflags = [ "-s" ];

  meta = with lib; {
    description = "Command line tool that reports natural light times for your location";
    homepage = "https://github.com/jbreckmckye/daylight";
    license = licenses.gpl3;
    mainProgram = "daylight";
  };
}
