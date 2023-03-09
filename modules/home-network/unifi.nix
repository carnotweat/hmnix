{ lib, config, pkgs, ... }:
let cfg = config.xameer.unifi; in
{
  options.xameer.unifi.enable = lib.mkEnableOption "Enable unifi controller";

  config = {
    services.unifi = lib.mkIf cfg.enable {
      enable = true;
      unifiPackage = pkgs.unifi;
      openFirewall = true;
      jrePackage = pkgs.jre8_headless;
    };
  };
}
