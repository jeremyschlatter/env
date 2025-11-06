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
    builders =
      with writers;
      {
        sh = _: writeBashBin;
        py = { requirements ? [], ... }: name:
          writePython3Bin name { libraries = map (p: getAttr p python3Packages) requirements; };
        rs = _: name: _: (crane.mkLib pkgs).buildPackage {
          src = lib.sources.sourceFilesBySuffices src ([".rs" "bin" ".toml" ".lock"]);
          buildInputs = lib.optional stdenv.isDarwin libiconv;
          cargoExtraArgs = "--bin ${name}";
        };
        js = _: name: path: writeJSBin name {} (lib.strings.fileContents path);
      };
    script = f: kind:
      let
        inherit (lib) strings;
        fullPath = src + "/${f}";
        ext = elemAt (tail (split "\\." f)) 1;
        name = strings.removeSuffix ".${ext}" f;
        buildInfo = let firstLine = head (split "\n" (strings.fileContents fullPath)); in
          let x = strings.removeSuffix "#nix" firstLine; in
          if x == firstLine then {} else fromJSON (elemAt (split "^[^ ]+" x) 2);
      in if (kind == "regular" && hasAttr ext builders) then {
        inherit name;
        value = (getAttr ext builders buildInfo name fullPath).overrideAttrs (final: prev:
          let attr = if (hasAttr "buildCommand" prev) then "buildCommand" else "postInstall"; in
          lib.optionalAttrs (hasAttr "deps" buildInfo)
          {
            ${attr} = getAttr attr ({${attr} = "";} // prev) + ''
              . ${makeWrapper}/nix-support/setup-hook
              wrapProgram $out/bin/${name} --prefix PATH : ${lib.makeBinPath (map
                  (x: lib.attrsets.getAttrFromPath (strings.splitString "." x)
                    (pkgs // { inherit scripts; }))
                  buildInfo.deps
              )}
            '';
            pname = name;
          } // (if (hasAttr "version" prev) then {} else { version = "0.0.0"; }));
      } else null;
    scripts = listToAttrs (filter (x: x != null) (lib.attrsets.mapAttrsToList script (readDir src)));
  in attrValues scripts
