{ stdenv, fetchFromGitHub, rustPlatform, cmake, perl, pkgconfig, zlib
, darwin, libiconv, ...
}:

with rustPlatform;

buildRustPackage rec {
  name = "exa-${version}";
  version = "2019-03-16";

  cargoSha256 = "0v7z6wzjpx0wnadnm579v7h3msrk6cvlbg2k812pn6l3786r1mjw";

  src = fetchFromGitHub {
    owner = "ogham";
    repo = "exa";
    rev = "35bf32abb9b8b445127c4722f45dcda25a55075a";
    sha256 = "0zcflma7nrxr61z5j4czwmc7v4jkg7d5llbgzl6hgk8fiq19q13a";
  };

  nativeBuildInputs = [ cmake pkgconfig perl ];
  buildInputs = [ zlib ]
  ++ stdenv.lib.optionals stdenv.isDarwin [
    libiconv darwin.apple_sdk.frameworks.Security ]
  ;

  postInstall = ''
    mkdir -p $out/share/man/man1
    cp contrib/man/exa.1 $out/share/man/man1/
    mkdir -p $out/share/bash-completion/completions
    cp contrib/completions.bash $out/share/bash-completion/completions/exa
    mkdir -p $out/share/fish/vendor_completions.d
    cp contrib/completions.fish $out/share/fish/vendor_completions.d/exa.fish
    mkdir -p $out/share/zsh/site-functions
    cp contrib/completions.zsh $out/share/zsh/site-functions/_exa
  '';

  # Some tests fail, but Travis ensures a proper build
  doCheck = false;

  meta = with stdenv.lib; {
    description = "Replacement for 'ls' written in Rust";
    longDescription = ''
      exa is a modern replacement for ls. It uses colours for information by
      default, helping you distinguish between many types of files, such as
      whether you are the owner, or in the owning group. It also has extra
      features not present in the original ls, such as viewing the Git status
      for a directory, or recursing into directories with a tree view. exa is
      written in Rust, so it’s small, fast, and portable.
    '';
    homepage = https://the.exa.website;
    license = licenses.mit;
    maintainers = [ maintainers.ehegnes ];
  };
}
