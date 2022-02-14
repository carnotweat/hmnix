{ system, pkgs, flake-args }:
let
  lib = pkgs.lib;
  lutris-unwrapped = (pkgs.lutris-unwrapped.override {
    # TODO wine build with wayland and GE patches?
    # wine = pkgs.wineWowPackages.wayland;
    wine = pkgs.emptyDirectory; # don't use system wine with lutris
  }).overrideAttrs (old: {
    patches = old.patches ++ [ ];
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ pkgs.wineWowPackages.fonts ];
  });
  xdg-open-with-portal = pkgs.callPackage ./xdg-open-with-portal { };
  wrapScripts = path:
    let
      scripts = map (lib.removeSuffix ".sh") (builtins.attrNames (builtins.readDir path));
    in
    builtins.listToAttrs (map (x: lib.nameValuePair x (pkgs.writeScriptBin x (builtins.readFile "${path}/${x}.sh"))) scripts);
  powercord = pkgs.callPackage ./powercord {
    plugins = { };
    themes = { };
  };
  lun-scripts = wrapScripts ./lun-scripts;
  lun-scripts-path = pkgs.symlinkJoin { name = "lun-scripts"; paths = lib.attrValues lun-scripts; };
in
{
  inherit powercord xdg-open-with-portal;
  input-remapper = pkgs.python3Packages.callPackage ./input-remapper { };
  discord-electron-update = pkgs.callPackage ./discord-electron-update rec {
    ffmpeg = pkgs.ffmpeg-full;
    electron = pkgs.electron_15;
    src = pkgs.discord-canary.src;
    version = pkgs.discord-canary.version;
    meta = pkgs.discord-canary.meta;
    pname = "discord-canary";
    binaryName = "DiscordCanary";
    desktopName = "Discord Canary";
  };
  discord-plugged = pkgs.callPackage ./discord-plugged {
    inherit powercord;
    powercord-overlay = flake-args.powercord-overlay;
    discord-canary = pkgs.lun.discord-electron-update;
  };
  kwinft = pkgs.lib.recurseIntoAttrs (pkgs.callPackage ./kwinft { });
  lutris = pkgs.lutris.override {
    inherit lutris-unwrapped;
    extraLibraries = pkgs: [ (pkgs.hiPrio xdg-open-with-portal) ];
  };
  spawn = pkgs.callPackage ./spawn { };
  swaysome = pkgs.callPackage ./swaysome { };
  sworkstyle = pkgs.callPackage ./sworkstyle { };
  lun = pkgs.writeShellScriptBin "lun" ''
    exec "${lun-scripts-path}/bin/$1" "''${@:1}"
  '';
}
