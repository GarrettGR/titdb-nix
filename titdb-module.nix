{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.titdb;

  trackpad-is-too-damn-big = pkgs.callPackage ./trackpad-is-too-damn-big.nix {};

  modeOptions = {
    "print" = "p";
    "strict" = "s";
    "flex" = "f";
  };
in {
  options.services.titdb = {
    enable = mkEnableOption "titdb (trackpad-is-too-damn-big) daemon";

    device = mkOption {
      type = types.str;
      example = "/dev/input/event0";
      description = ''
        The trackpad device file to monitor.
        You can find your trackpad device by running:
        `sudo libinput list-devices` or checking `/proc/bus/input/devices`
      '';
    };

    mode = mkOption {
      type = types.enum ["print" "strict" "flex"];
      default = "flex";
      description = ''
        Running mode:
        - print: Print device properties and events without modifying them
        - strict: Completely disable designated areas of the trackpad
        - flex: Disable initial input from designated areas while allowing re-entry and multitouch gestures
      '';
    };

    margins = {
      left = mkOption {
        type = types.ints.between 0 100;
        default = 10;
        description = "Left margin percentage to disable";
      };

      right = mkOption {
        type = types.ints.between 0 100;
        default = 10;
        description = "Right margin percentage to disable";
      };

      top = mkOption {
        type = types.ints.between 0 100;
        default = 0;
        description = "Top margin percentage to disable";
      };

      bottom = mkOption {
        type = types.ints.between 0 100;
        default = 15;
        description = "Bottom margin percentage to disable";
      };
    };

    user = mkOption {
      type = types.str;
      default = "root";
      description = ''
        User to run the service as. Note that the service needs access to input devices,
        so the user must be in the 'input' group or be root.
      '';
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional arguments to pass to titdb";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = mkIf (cfg.user != "root") {
      extraGroups = ["input"];
    };

    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660"
      SUBSYSTEM=="input", GROUP="input", MODE="0660"
    '';

    systemd.services.titdb = {
      description = "Trackpad Is Too Damn Big - Virtual Trackpad Resizer";
      documentation = ["https://github.com/tascvh/trackpad-is-too-damn-big"];

      wantedBy = ["multi-user.target"];
      after = ["systemd-udev-settle.service"];
      wants = ["systemd-udev-settle.service"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "input";
        Restart = "always";
        RestartSec = "5s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectClock = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;

        DeviceAllow = [
          "/dev/uinput rw"
          "${cfg.device} r"
          "/dev/input r"
        ];
        DevicePolicy = "strict";

        CapabilityBoundingSet = ["CAP_DAC_OVERRIDE"];
        AmbientCapabilities = ["CAP_DAC_OVERRIDE"];
      };

      script = let
        args =
          [
            "-d"
            cfg.device
            "-m"
            (modeOptions.${cfg.mode})
            "-l"
            (toString cfg.margins.left)
            "-r"
            (toString cfg.margins.right)
            "-t"
            (toString cfg.margins.top)
            "-b"
            (toString cfg.margins.bottom)
          ]
          ++ cfg.extraArgs;
      in ''
        while [ ! -e "${cfg.device}" ]; do
          echo "Waiting for device ${cfg.device} to become available..."
          sleep 1
        done

        echo "Starting titdb with device ${cfg.device}"
        exec ${trackpad-is-too-damn-big}/bin/titdb ${escapeShellArgs args}
      '';

      preStop = ''
        echo "Stopping titdb..."
      '';
    };

    system.activationScripts.titdb = ''
      echo "titdb service configured for device: ${cfg.device}"
      echo "Mode: ${cfg.mode}, Margins: L${toString cfg.margins.left}% R${toString cfg.margins.right}% T${toString cfg.margins.top}% B${toString cfg.margins.bottom}%"
    '';
  };
}
