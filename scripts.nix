# Scripting!
#
# This is the most elaborate part of my nix config. Basically, this
# converts my scripts/ directory into a bunch of nix packages, one per
# script.
#
# It knows how to package a few different languages, and two different
# styles of Go programs (with and without Go module dependencies).
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
naersk: pkgs: scriptsPath:
  with builtins;
  let
    builders = with pkgs;
      let
        wrapPath = name: deps:
          if deps == []
          then ""
          else ''
            . ${makeWrapper}/nix-support/setup-hook
            wrapProgram $out/bin/${name} --prefix PATH : ${
              buildEnv {
                name = "${name}-runtime-deps";
                paths = deps;
              }
            }/bin
            '';
        build = cmd: {deps}: file: name:
          runCommandLocal name { buildInputs = deps;} ''
            mkdir -p $out/bin
            file=${file}
            dest=$out/bin/${name}
            ${cmd}
            chmod +x $dest
            ${wrapPath name deps}
            '';
        interp = interpreter: build "echo '#!'${interpreter} | cat - $file > $dest";
      in {
        sh = interp "${bash}/bin/sh";
        go = build ''
          mkdir build
          cd build
          GOCACHE=$TMPDIR ${go}/bin/go mod init `basename $dest`
          GOCACHE=$TMPDIR GOPATH=$TMPDIR CGO_ENABLED=0 ${go}/bin/go build -o $dest $file
        '';
        goDir = src: name: deps: vendorSha256:
          buildGoModule {
            inherit name src vendorSha256;
            postInstall = "${wrapPath name deps}";
          };
        hs = build "${ghc}/bin/ghc -XLambdaCase -o $dest -outputdir $TMPDIR/$file $file";
        py = { deps, requirements ? [], darwinRequirements ? [] }:
          interp ''${
            python3.withPackages (pyPkgs:
              map (x: getAttr x pyPkgs) requirements ++ (if pkgs.stdenv.isDarwin then map (x: getAttr x pyPkgs) darwinRequirements else [])
            )
          }/bin/python'' { inherit deps; };
        rs = { deps }: file: name: naersk.buildPackage { root = scriptsPath; };
      };
    inherit (pkgs.lib) strings attrsets sources lists warn;
  in lists.forEach (attrNames (readDir scriptsPath)) (f:
    let fullPath = scriptsPath + "/${f}";
    in if sources.pathIsDirectory fullPath
       then
         if f == ".mypy_cache" || f == "src" then [] else
         let build = { deps = []; } // import (fullPath + "/build.nix") pkgs;
         in builders.goDir fullPath f build.deps build.sha256
       else
         let ext = elemAt (tail (split "\\." f)) 1;
             name = strings.removeSuffix ".${ext}" f;
             firstLine = head (split "\n" (strings.fileContents fullPath));
             buildInfo = let x = strings.removeSuffix "#nix" firstLine; in
               if x == firstLine then {} else fromJSON (elemAt (split "^[^ ]+" x) 2);
             deps = map
               (x: attrsets.getAttrFromPath (strings.splitString "." x) pkgs)
               (buildInfo.deps or []);
         in if hasAttr ext builders
            then getAttr ext builders (buildInfo // { inherit deps; }) fullPath name
            else null
            # else info "not a recognized type of script: ${f}" []
    )
