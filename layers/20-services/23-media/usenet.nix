{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.usenet;
  mediaCfg = config.layers.layer-20.services.config.media-stack;
in
{
  options.layers.layer-20.services.config.usenet = {
    enable = mkEnableOption "Usenet clients (NZBGet, SABnzbd, NZBHydra2, Pan)";

    nzbget = {
      enable = mkEnableOption "NZBGet usenet client";
      port = mkOption {
        type = types.port;
        default = 6789;
      };
    };

    sabnzbd = {
      enable = mkEnableOption "SABnzbd usenet client";
      port = mkOption {
        type = types.port;
        default = 8081;
      };
    };

    nzbhydra2 = {
      enable = mkEnableOption "NZBHydra2 indexer";
      port = mkOption {
        type = types.port;
        default = 5076;
      };
    };

    pan.enable = mkEnableOption "Pan GUI newsreader";
  };

  config = mkIf cfg.enable {
    # SABnzbd
    services.sabnzbd = mkIf cfg.sabnzbd.enable {
      enable = true;
      inherit (mediaCfg) user;
      inherit (mediaCfg) group;
    };

    # NZBGet
    services.nzbget = mkIf cfg.nzbget.enable {
      enable = true;
      inherit (mediaCfg) user;
      inherit (mediaCfg) group;
    };

    # NZBHydra2
    systemd.services.nzbhydra2 = mkIf cfg.nzbhydra2.enable {
      description = "NZBHydra2";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.nzbhydra2}/bin/nzbhydra2 --nobrowser --config /var/lib/nzbhydra2/nzbhydra.yml --database /var/lib/nzbhydra2/nzbhydra.db";
        User = mediaCfg.user;
        Group = mediaCfg.group;
        StateDirectory = "nzbhydra2";
        Restart = "on-failure";
      };
    };

    # Pan GUI
    environment.systemPackages = optional cfg.pan.enable pkgs.pan;

    # Directories
    systemd.tmpfiles.rules =
      (optional cfg.sabnzbd.enable "d /var/lib/sabnzbd 0750 ${mediaCfg.user} ${mediaCfg.group} -")
      ++ (optional cfg.nzbget.enable "d /var/lib/nzbget 0750 ${mediaCfg.user} ${mediaCfg.group} -")
      ++ (optional cfg.nzbhydra2.enable "d /var/lib/nzbhydra2 0750 ${mediaCfg.user} ${mediaCfg.group} -");

    # Firewall
    networking.firewall.allowedTCPPorts =
      (optional cfg.nzbget.enable cfg.nzbget.port)
      ++ (optional cfg.sabnzbd.enable cfg.sabnzbd.port)
      ++ (optional cfg.nzbhydra2.enable cfg.nzbhydra2.port);

    # Persistence
    environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
      directories =
        (optional cfg.nzbget.enable {
          directory = "/var/lib/nzbget";
          inherit (mediaCfg) user;
          inherit (mediaCfg) group;
          mode = "0750";
        })
        ++ (optional cfg.sabnzbd.enable {
          directory = "/var/lib/sabnzbd";
          inherit (mediaCfg) user;
          inherit (mediaCfg) group;
          mode = "0750";
        })
        ++ (optional cfg.nzbhydra2.enable {
          directory = "/var/lib/nzbhydra2";
          inherit (mediaCfg) user;
          inherit (mediaCfg) group;
          mode = "0750";
        });
    };
  };
}
