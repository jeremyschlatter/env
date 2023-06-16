# Scripting!
#
# This is the most elaborate part of my nix config. Basically, this
# converts my scripts/ directory into a bunch of nix packages, one per
# script.
#
# It knows how to package a few different languages.
#
# Scripts can declare in a comment at the top of the file that they depend
# on other programs at runtime, and the packaging logic here will do the
# appropriate bundling to ensure they have access to those programs.
#
# Python scripts can declare their pypi dependencies in a comment at the
# top of file, too.
#
# All of this packaging works in sandbox mode, as well. This is important
# to me because my work machine is in sandbox mode and I don't want to turn
# that off.
crane: pkgs: src:
  with builtins;
  with pkgs;
  let
    wrapPath = name: deps: pkg:
      pkg.overrideAttrs (final: prev:
        let attr = if (hasAttr "buildCommand" prev) then "buildCommand" else "postInstall"; in
        lib.optionalAttrs (deps != [])
        {
          ${attr} = getAttr attr ({${attr} = "";} // prev) + ''
            . ${makeWrapper}/nix-support/setup-hook
            wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath deps}
          '';
        });
    builders =
      with writers;
      {
        sh = _: writeBashBin;
        py = { requirements ? [], ... }: name:
          writePython3Bin name { libraries = map (p: getAttr p python3Packages) requirements; };
        rs = _: name: _: crane.buildPackage {
          src = lib.sources.sourceFilesBySuffices src [".rs" "bin" ".toml" ".lock"];
          buildInputs = lib.optional stdenv.isDarwin libiconv;
          cargoExtraArgs = "--bin ${name}";
        };
        go = _: name: f: buildGoModule {
          inherit name src;
          vendorSha256 = import "${src}/go.nix";
          preBuild = "rm *.go && cp ${f} ${name}.go && go mod edit -module ${name}";
        };
      };
    scripts = listToAttrs (filter (x: x != null) (lib.attrsets.mapAttrsToList script (readDir src)));
    script = f: kind:
      let
        inherit (lib) strings;
        fullPath = src + "/${f}";
        ext = elemAt (tail (split "\\." f)) 1;
        name = strings.removeSuffix ".${ext}" f;
        firstLine = head (split "\n" (strings.fileContents fullPath));
        buildInfo = let x = strings.removeSuffix "#nix" firstLine; in
          if x == firstLine then {} else fromJSON (elemAt (split "^[^ ]+" x) 2);
        deps = map
          (x: lib.attrsets.getAttrFromPath (strings.splitString "." x)
            (pkgs // { inherit scripts; }))
          (buildInfo.deps or []);
      in if (kind == "regular" && hasAttr ext builders) then {
        inherit name;
        value = wrapPath name deps (getAttr ext builders buildInfo name fullPath);
      } else null;
  in attrValues scripts
