{ config, pkgs, lib, ... }:
let
  cfg = config.xameer.efi-tools;
  inherit (config.boot.loader) efi;
  copyTool = source: dest_filename:
    ''
      if [ -d "${efi.efiSysMountPoint}/EFI" ] && [ -e "${source}" ]; then
        in_package="${source}"
        esp_tool_folder="${efi.efiSysMountPoint}/EFI/tools/"
        in_esp="''${esp_tool_folder}${dest_filename}"
        >&2 echo "Ensuring ${dest_filename} in EFI System Partition"
        if ! ${pkgs.diffutils}/bin/cmp --silent "$in_package" "$in_esp"; then
          >&2 echo "Copying $in_package -> $in_esp"
          mkdir -p "$esp_tool_folder"
          cp "$in_package" "$in_esp"
          sync
        fi
      else
        >&2 echo "Skipping ${source} as EFI directory or source .efi missing"
      fi
    '';
in
{
  options.xameer.efi-tools = {
    enable = lib.mkEnableOption "Enable copying tools to EFI System Partition tools directory";
    tools = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.nullOr lib.types.path);
      description = "Set of .efi files";
    };
  };
  config = lib.mkIf cfg.enable {
    xameer.efi-tools.tools = {
      memtest86 = lib.mkDefault pkgs.memtest86plus.efi;
      shell = lib.mkDefault pkgs.edk2-uefi-shell.efi;
    };
    system.activationScripts.copy-efi-tools = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: copyTool value (name + ".efi")) cfg.tools);
  };
}
