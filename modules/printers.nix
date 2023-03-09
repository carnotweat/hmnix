{ pkgs, lib, config, ... }:
{
  options.xameer.print.enable = lib.mkEnableOption "Enable printing and scanning";
  config = lib.mkIf config.xameer.print.enable {
    services.printing.enable = true;
    hardware.sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };
}
