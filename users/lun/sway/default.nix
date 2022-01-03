{ pkgs, lib, config, ... }:
let
  execSpawn = cmd: "exec ${pkgs.lun.spawn}/bin/spawn ${cmd}";
  bar = "${config.programs.waybar.package}/bin/waybar";
  drun = execSpawn "${pkgs.wofi}/bin/wofi --show drun";
  menu = execSpawn "${pkgs.wofi}/bin/wofi --show dmenu";
  screenshot = execSpawn "${pkgs.sway-contrib.grimshot}/bin/grimshot";
in
{
  imports = [
    ./waybar.nix
  ];

  /*
    testing launch for multigpu nvidia&amd - needs more up to date sway/wlroots
    env \
    WLR_RENDERER=vulkan \
    GBM_BACKEND=nvidia-drm \
    __GLX_VENDOR_LIBRARY_NAME=nvidia \
    WLR_NO_HARDWARE_CURSORS=1 \
    WLR_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1 \
    sway --unsupported-gpu 2> ~/dev/swaylog
  */

  # Borrowed significantly from https://github.com/lovesegfault/nix-config
  home.packages = [ pkgs.lun.spawn ];

  programs.mako = {
    enable = true;
    sort = "+time";
    maxVisible = 10;
    layer = "overlay";
    borderRadius = 5;
  };

  wayland.windowManager.sway = {
    enable = true;
    # Use system sway
    package = null;
    config = {
      inherit menu;
      modifier = "Mod4";
      bars = [{ command = bar; }];

      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
          terminal = config.wayland.windowManager.sway.config.terminal;
          pactl = "${pkgs.pulseaudio}/bin/pactl";
          pamixer = "${pkgs.pamixer}/bin/pamixer";
        in
        lib.mkOptionDefault {
          "${modifier}+Return" = execSpawn terminal;
          "${modifier}+space" = drun;
          # "${modifier}+m" = execSpawn "${pkgs.emojimenu-wayland}/bin/emojimenu";
          # "${modifier}+o" = execSpawn "${pkgs.screenocr}/bin/screenocr";
          # "${modifier}+t" = execSpawn "${pkgs.otpmenu-wayland}/bin/otpmenu";
          # "${modifier}+p" = execSpawn "${pkgs.passmenu-wayland}/bin/passmenu";
          "${modifier}+q" = execSpawn "swaylock -f";
          "Print" = screenshot;
          "XF86AudioMute" = execSpawn "${pamixer} -t";
          "XF86AudioLowerVolume" = execSpawn "${pamixer} -d 5";
          "XF86AudioRaiseVolume" = execSpawn "${pamixer} -i 5";
          "Shift+XF86AudioRaiseVolume" = execSpawn "${pamixer} -i 5 --allow-boost";
          "XF86AudioMicMute" = execSpawn "${pactl} set-source-mute @DEFAULT_SOURCE@ toggle";
        };

      output = {
        "*" = {
          scale = "1";
          bg = "${config.xdg.dataHome}/wall.png fill #0a0a0a";
        };
      };

      terminal = "${config.programs.foot.package}/bin/foot";

      window.commands = [
        { command = "floating enable"; criteria.app_id = "imv"; }
      ];
    };

    extraConfig = ''
      include /etc/sway/config.d/*

      input type:touchpad {
        tap disabled
        natural_scroll disabled
      }
      input type:pointer {
        accel_profile flat
      }
    '';

    # export FREETYPE_PROPERTIES=truetype:interpreter-version=35
    extraSessionCommands = ''
      export ECORE_EVAS_ENGINE=wayland_egl
      export ELM_ENGINE=wayland_egl
      export MOZ_ENABLE_WAYLAND=1
      export GDK_BACKEND=wayland
      export QT_QPA_PLATFORM=xcb
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export QT_WAYLAND_FORCE_DPI=physical
      export SDL_VIDEODRIVER=wayland
      export XDG_CURRENT_DESKTOP="sway"
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

    systemdIntegration = true;
    wrapperFeatures.gtk = false;
  };

  # systemd.user.services.sway-inactive-windows-transparency =
  #   let
  #     inherit (pkgs.sway-contrib) inactive-windows-transparency; in
  #   {
  #     Unit = {
  #       Description = "Set opacity of onfocused windows in SwayWM";
  #       PartOf = "graphical-session.target";
  #       StartLimitIntervalSec = "0";
  #     };
  #     Service = {
  #       Type = "simple";
  #       ExecStart = ''
  #         ${inactive-windows-transparency}/bin/inactive-windows-transparency.py -o 0.9
  #       '';
  #       Restart = "on-failure";
  #       RestartSec = "1";
  #     };
  #     Install = { WantedBy = [ "sway-session.target" ]; };
  #   };

  systemd.user.services = {
    mako = {
      Unit = {
        Description = "A lightweight Wayland notification daemon";
        Documentation = "man:mako(1)";
        PartOf = "graphical-session.target";
      };
      Service = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${pkgs.mako}/bin/mako";
      };
      Install = { WantedBy = [ "sway-session.target" ]; };
    };
  };

  # home.file.".config/sway/config".text = ''
  #   set $mod Mod4
  #   set $menu dmenu_path | wofi --dmenu | xargs swaymsg exec --
  #   bindsym $mod+Space exec $menu
  # '';
}