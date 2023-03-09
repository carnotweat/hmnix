{ config, lib, ... }:
{
  options.xameer.profiles.server = lib.mkEnableOption "Enable server profile";
  config = lib.mkIf config.xameer.profiles.server {
    sound.enable = false;
    hardware.opengl = lib.mkForce {
      enable = false;
    };
    boot.plymouth.enable = lib.mkForce false;
  };
}
