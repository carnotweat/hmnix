{ config, lib, ... }:
{
  options.xameer.profiles.gaming = lib.mkEnableOption "Enable gaming profile";
  config = lib.mkIf config.xameer.profiles.gaming {
    programs.steam.enable = true;
    services.input-remapper.enable = true;
  };
}
