{ bootstrapLib, ... }:
let
  lib = bootstrapLib;
  self =
    (import ./mkFlake.nix { inherit bootstrapLib; }) //
    {
      recursiveMerge =
        let
          f = attrPath:
            with lib; with builtins;
            zipAttrsWith (n: values:
              if tail values == [ ]
              then head values
              else if all isList values
              then unique (concatLists values)
              else if all isAttrs values
              then f (attrPath ++ [ n ]) values
              else last values
            );
        in
        f [ ];
      setIf = flag: set: if flag then set else { };
      patchPackages = nixpkgs: system: patches: (if (patches == [ ]) then nixpkgs else
      nixpkgs.legacyPackages.${system}.applyPatches {
        inherit patches;
        src = nixpkgs;
        name = "nixpkgs-patched";
      });
      mkPkgs = pkgs: system: patches: config:
        let outPath = self.patchPackages pkgs system patches; in
        (import outPath config) // { outPath = "${outPath}"; };
      filterPrefix = prefix: lib.filterAttrs (name: _value: (lib.hasPrefix prefix name));
      readExportedModules = path: lib.mapAttrs'
        (key: _value:
          lib.nameValuePair
            (lib.removeSuffix ".nix" key)
            ({ pkgs, ... }@args: import (path + "/${key}") (args // {
              pkgs = args.pkgs // { xameer = args.pkgs.xameer or (self.localPackagesForPkgs args.pkgs); };
            })))
        (builtins.readDir path);
    };
in
self
