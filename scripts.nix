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
crane: pkgs: scriptsPath:
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
          src = scriptsPath;
          buildInputs = lib.optional stdenv.isDarwin libiconv;
          cargoExtraArgs = "--bin ${name}";
        };
      };
    inherit (lib) strings attrsets sources lists;
  scripts = listToAttrs (filter (x: x != null) (lists.forEach (attrNames (readDir scriptsPath)) (f:
    let fullPath = scriptsPath + "/${f}";
    in if sources.pathIsDirectory fullPath
       then
         if f == "src" then null else
         let build = { deps = []; } // import (fullPath + "/build.nix") pkgs;
         in {
           name = f;
           value = wrapPath f build.deps (buildGoModule { name = f; src = fullPath; vendorSha256 = build.sha256; });
         }
       else
         let ext = elemAt (tail (split "\\." f)) 1;
             name = strings.removeSuffix ".${ext}" f;
             firstLine = head (split "\n" (strings.fileContents fullPath));
             buildInfo = let x = strings.removeSuffix "#nix" firstLine; in
               if x == firstLine then {} else fromJSON (elemAt (split "^[^ ]+" x) 2);
             deps = map
               (x: attrsets.getAttrFromPath (strings.splitString "." x)
                 (pkgs // { inherit scripts; }))
               (buildInfo.deps or []);
         in if hasAttr ext builders
            then {
              inherit name;
              value = wrapPath name deps (getAttr ext builders buildInfo name fullPath);
            }
            else null
    )));
  in attrValues scripts
