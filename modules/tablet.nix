{ pkgs, config, lib, ... }:
{
  options.xameer.tablet.enable = lib.mkEnableOption "drawing tablet support";

  config = lib.mkIf config.xameer.tablet.enable {
    services.xserver.wacom.enable = true;
    environment.systemPackages = [
      pkgs.wacomtablet # KDE settings panel for wacom tablets
    ];
  };
}
