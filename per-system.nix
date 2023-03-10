{ flakeArgs }:
system:
let
  pkgsPatches = [
    # add .patch to a github PR URL to get a patch quickly
    ./nixpkgs-patches/lutris-xdg-data-dirs.patch
    ./nixpkgs-patches/xdg-open-test.patch
  ];
  defaultPkgsConfig = {
    config.allowUnfree = true;
    overlays = [
      # (final: prev: {
      #   some-package = ...
      # })
      flakeArgs.self.overlay
      flakeArgs.emacs-overlay.overlay
    ];
  };
  readModules = path: builtins.map (x: path + "/${x}") (builtins.filter (str: (builtins.match "^[^.]*(\.nix)?$" str) != null) (builtins.attrNames (builtins.readDir path)));
  lib = perSystemSelf.nixpkgsLib;
  perSystemSelf = {
    # hack: only patch for x86_64 so nix flake check doesn't fall over for other platforms
    # eventually will get rid of this IFD
    # once there's patches support for flake inputs
    # https://github.com/NixOS/nix/pull/6530
    pkgs = flakeArgs.self.lib.mkPkgs flakeArgs.nixpkgs system (if system == "x86_64-linux" then pkgsPatches else [ ]) (defaultPkgsConfig // { inherit system; });
    pkgs-stable = flakeArgs.self.lib.mkPkgs flakeArgs.nixpkgs-stable system [ ] (defaultPkgsConfig // { inherit system; });
    nixpkgsLib = flakeArgs.nixpkgs.lib.extend (final: _prev: {
      nixosSystem = args:
        import "${flakeArgs.nixpkgs}/nixos/lib/eval-config.nix" (args // {
          modules = args.modules ++ [{
            system.nixos.versionSuffix = "";
            system.nixos.revision = "";
          }];
        });

    });
    makeHost = path: lib.nixosSystem {
      inherit (perSystemSelf.pkgs) system;

      specialArgs =
        {
          inherit flakeArgs;
          inherit (perSystemSelf) pkgs-stable;
          nixos-hardware-modules-path = "${flakeArgs.nixos-hardware}";
        };

      modules = [
        { nixpkgs.pkgs = perSystemSelf.pkgs; }
        flakeArgs.home-manager.nixosModules.home-manager
        flakeArgs.nix-gaming.nixosModules.pipewireLowLatency
        path
        ./users
        ({ config, ... }:
          {
            config = {
              home-manager.extraSpecialArgs = {
                inherit flakeArgs;
                inherit (perSystemSelf) pkgs-stable;
                xameer-profiles = config.xameer.profiles;
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            };
          })
      ]
      ++ (builtins.attrValues flakeArgs.self.nixosModules)
      ++ (readModules ./modules);
    };
    legacyPackages = flakeArgs.self.localPackagesForPkgs perSystemSelf.pkgs;
    packages = lib.filterAttrs (_k: pkg: lib.isDerivation pkg && !((pkg.meta or { }).broken or false) && (!(pkg ? meta && pkg.meta ? platforms) || builtins.elem system pkg.meta.platforms)) perSystemSelf.legacyPackages;
    devShell = flakeArgs.minimal-shell.lib.minimal-shell {
      inherit (perSystemSelf) pkgs;
      shellHooks = perSystemSelf.checks.pre-commit-check.shellHook;
      shellPackages = [ perSystemSelf.pkgs.nixpkgs-fmt ];
    };
    formatter = perSystemSelf.pkgs.nixpkgs-fmt;

    homeConfigurations =
      let
        makeUser = username:
          import "${flakeArgs.home-manager}/modules" {
            inherit (perSystemSelf) pkgs;
            check = true;
            extraSpecialArgs = {
              inherit flakeArgs;
              inherit (perSystemSelf) pkgs-stable;
              nixosConfig = null;
              xameer-profiles = {
                graphical = true;
                wine = false;
              };
            };
            configuration = {
              _module.args.pkgs = lib.mkForce perSystemSelf.pkgs;
              _module.args.pkgs_i686 = lib.mkForce { };
              imports = [ "${./users}/${username}" ];
              home.homeDirectory = "/home/${username}";
              home.username = "${username}";
            };
          };
      in
      {
        xameer = makeUser "xameer";
        pine = makeUser "pine";
      };
    slowChecks = rec {
      all-packages = perSystemSelf.pkgs.symlinkJoin {
        name = "xameer packages.${system}";
        paths = lib.attrValues perSystemSelf.packages;
      };
      all-systems = perSystemSelf.pkgs.symlinkJoin {
        name = "xameer nixosConfigurations for system ${system}";
        paths = lib.filter (x: x.system == system) (map (cfg: flakeArgs.self.nixosConfigurations.${cfg}.config.system.build.toplevel) (builtins.attrNames flakeArgs.self.nixosConfigurations));
      };
      all-users = perSystemSelf.pkgs.symlinkJoin {
        name = "xameer homeConfigurations for system ${system}";
        paths = map (x: x.activationPackage) (lib.attrValues perSystemSelf.homeConfigurations);
      };
      all = perSystemSelf.pkgs.symlinkJoin {
        name = "xameer all";
        paths = [ all-packages all-systems all-users ];
      };
    };
    checks = {
      pre-commit-check = flakeArgs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          statix.enable = true;
          nixpkgs-fmt.enable = true;
          shellcheck = {
            enable = true;
            files = "\\.sh$";
            types_or = lib.mkForce [ ];
          };
          shfmt = {
            enable = true;
            files = "\\.sh$";
          };
        };
      };
    } // flakeArgs.deploy-rs.lib.${system}.deployChecks flakeArgs.self.deploy;
  };
in
perSystemSelf
