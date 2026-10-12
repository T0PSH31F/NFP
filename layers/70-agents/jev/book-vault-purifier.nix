# Tier: 70-agents / jev
# Module: book-vault-purifier.nix
# Purpose: E-Book and document library purification, metadata/cover standardization, and Brain-Service AI/Income RAG ingestion bridge.
# Option Path: services.book-vault-purifier
# Enabling Host Tags: homelab, storage, ai-agent
# RAM Footprint: low (<120MB)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.book-vault-purifier;
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pypdf
    ]
  );
  purifierScript = pkgs.writeShellScriptBin "book-vault-purifier" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.calibre
        pkgs.btrfs-progs
        pkgs.poppler_utils
        pkgs.coreutils
      ]
    }:$PATH"
    exec ${pythonEnv}/bin/python3 ${./book-vault-purifier.py} "$@"
  '';
in
{
  options.services.book-vault-purifier = {
    enable = lib.mkEnableOption "E-Book Library Purification and RAG Ingestion Pipeline";

    sourceDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/vault/raw-inbox";
      description = "Mangled raw inbox containing unprocessed documents and books";
    };

    libraryDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/vault/library";
      description = "Canonical Calibre/Kavita library destination directory";
    };

    quarantineDir = lib.mkOption {
      type = lib.types.str;
      default = "/data/vault/quarantine";
      description = "Quarantine directory for corrupted files and non-book pollutants";
    };

    brainInboxDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/brain-service/inbox";
      description = "Brain-Service RAG ingestion inbox directory";
    };

    brainServiceUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:8010";
      description = "Brain-Service REST API endpoint for PGVector document indexing";
    };

    jevEngineUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:20130";
      description = "Jev System-1 Decision Engine endpoint";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "Systemd timer schedule for periodic purification sweep";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      purifierScript
      pkgs.calibre
      pkgs.btrfs-progs
    ];

    systemd = {
      tmpfiles.rules = [
        "d ${cfg.sourceDir} 0775 root users -"
        "d ${cfg.libraryDir} 0775 root users -"
        "d ${cfg.quarantineDir} 0775 root users -"
        "d ${cfg.brainInboxDir} 0775 postgres users -"
      ];

      services.book-vault-purifier = {
        description = "Book Vault Purifier and RAG Ingestion Sweep";
        after = [
          "network.target"
          "jev-engine.service"
        ];
        environment = {
          JEV_ENGINE_URL = cfg.jevEngineUrl;
          BRAIN_SERVICE_URL = cfg.brainServiceUrl;
        };

        serviceConfig = {
          ExecStart = "${purifierScript}/bin/book-vault-purifier --source ${cfg.sourceDir} --library ${cfg.libraryDir} --quarantine ${cfg.quarantineDir} --brain-inbox ${cfg.brainInboxDir} --once";
          Type = "oneshot";
          User = "root";
          PrivateTmp = true;
        };
      };

      timers.book-vault-purifier = {
        description = "Periodic timer for Book Vault Purification sweep";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.schedule;
          Persistent = true;
        };
      };
    };
  };
}
