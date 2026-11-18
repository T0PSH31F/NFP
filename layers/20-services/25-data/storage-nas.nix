# Tier: 20-services / 25-data
# Module: storage-nas.nix
# Purpose: Tailnet-wide /Storage SMB3 NAS mount, file-manager access, and gocryptfs encrypted Private Vault.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.data.storage-nas;
  user = config.layers.meta.primaryUser or "t0psh31f";
  homeDir = "/home/${user}";
  cipherDir =
    if cfg.mode == "server" then
      "${cfg.storageRoot}/.Private.enc"
    else
      "${cfg.mountPoint}/.Private.enc";
  vaultMount = "${homeDir}/Private";

  vaultUnlock = pkgs.writeShellScriptBin "private-vault-unlock" ''
    set -euo pipefail
    CIPHER="${cipherDir}"
    MNT="${vaultMount}"
    mkdir -p "$MNT"
    chmod 700 "$MNT"

    if ${pkgs.util-linux}/bin/mountpoint -q "$MNT"; then
      echo "Private Vault is already unlocked at $MNT"
      exit 0
    fi

    # Trigger systemd automount on CIFS clients before checking cipher directory
    ls "$CIPHER" >/dev/null 2>&1 || true
    if [ ! -f "$CIPHER/gocryptfs.conf" ]; then
      echo "Encrypted vault not reachable or not initialized at $CIPHER" >&2
      exit 1
    fi

    IDLE_ARG="-idle 60m"
    if [ "''${1:-}" = "--no-idle" ]; then
      IDLE_ARG=""
    fi

    PASS_FILE="${config.sops.secrets.luffy_private_vault_password.path}"
    if [ -r "$PASS_FILE" ]; then
      ${pkgs.gocryptfs}/bin/gocryptfs -q $IDLE_ARG -passfile "$PASS_FILE" "$CIPHER" "$MNT"
    else
      ${pkgs.gocryptfs}/bin/gocryptfs $IDLE_ARG "$CIPHER" "$MNT"
    fi
    echo "Private Vault unlocked at $MNT (auto-locks after 60m idle unless --no-idle)."
  '';

  vaultLock = pkgs.writeShellScriptBin "private-vault-lock" ''
    set -euo pipefail
    MNT="${vaultMount}"
    if ! ${pkgs.util-linux}/bin/mountpoint -q "$MNT"; then
      echo "Private Vault is already locked."
      exit 0
    fi
    /run/wrappers/bin/fusermount3 -u "$MNT" 2>/dev/null || ${pkgs.fuse3}/bin/fusermount3 -u "$MNT"
    echo "Private Vault locked ($MNT unmounted)."
  '';

  vaultStatus = pkgs.writeShellScriptBin "private-vault-status" ''
    set -euo pipefail
    MNT="${vaultMount}"
    CIPHER="${cipherDir}"
    if ${pkgs.util-linux}/bin/mountpoint -q "${cfg.mountPoint}"; then
      echo "NAS Mount : MOUNTED (${cfg.mountPoint})"
    elif [ -L "${cfg.mountPoint}" ] && [ -d "${cfg.mountPoint}" ]; then
      echo "NAS Mount : LOCAL SYMLINK (${cfg.mountPoint} -> ${cfg.storageRoot})"
    else
      echo "NAS Mount : AUTOMOUNT READY (${cfg.mountPoint} -> //${cfg.serverIp}/${cfg.shareName})"
    fi

    if ${pkgs.util-linux}/bin/mountpoint -q "$MNT"; then
      echo "Vault     : UNLOCKED at $MNT"
    else
      echo "Vault     : LOCKED (cipher: $CIPHER)"
    fi
  '';
in
{
  options.layers.layer-20.services.data.storage-nas = {
    enable = mkEnableOption "Tailnet /Storage NAS server/client mounts and encrypted Private Vault";

    mode = mkOption {
      type = types.enum [
        "server"
        "client"
      ];
      default = "client";
      description = "server shares /storage over SMB3 and hosts .Private.enc; client automounts /Storage.";
    };

    storageRoot = mkOption {
      type = types.str;
      default = "/storage";
      description = "Backing storage root on luffy.";
    };

    mountPoint = mkOption {
      type = types.str;
      default = "/Storage";
      description = "Uniform /Storage path across all fleet devices.";
    };

    serverIp = mkOption {
      type = types.str;
      default = "100.64.0.3";
      description = "Tailnet IP address of luffy storage NAS.";
    };

    shareName = mkOption {
      type = types.str;
      default = "Storage";
      description = "SMB share name exposed by luffy.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      sops.secrets.luffy_storage_smb_password = {
        sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
        mode = "0400";
      };

      sops.secrets.luffy_private_vault_password = {
        sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
        owner = user;
        mode = "0400";
      };

      environment.systemPackages = with pkgs; [
        gocryptfs
        vaultUnlock
        vaultLock
        vaultStatus
      ];
    }

    (mkIf (cfg.mode == "server") {
      systemd.tmpfiles.rules = [
        "L+ ${cfg.mountPoint} - - - - ${cfg.storageRoot}"
        "d ${cfg.storageRoot}/.Private.enc 0700 ${user} users -"
        "d ${vaultMount} 0700 ${user} users -"
      ];

      services.samba = {
        enable = true;
        nmbd.enable = false;
        winbindd.enable = false;
        openFirewall = false;
        settings = {
          global = {
            workgroup = "LOVELAIN";
            "server string" = "Luffy Central Storage NAS";
            "server role" = "standalone server";
            security = "user";
            "map to guest" = "Bad User";
            "server min protocol" = "SMB2";
            "smb encrypt" = "desired";
            "hosts allow" = "100.64.0.0/10 127.0.0.1 192.168.1.0/24";
            "hosts deny" = "0.0.0.0/0";
            "unix extensions" = "no";
            "mangled names" = "no";
          };
          "${cfg.shareName}" = {
            path = cfg.storageRoot;
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "valid users" = user;
            "force user" = user;
            "force group" = "users";
            "create mask" = "0664";
            "directory mask" = "0775";
            "veto files" = "/.syncing/.Trash-*/Private/";
          };
        };
      };

      systemd.services.samba-provision-users = {
        description = "Provision Samba credentials for ${user} from SOPS";
        after = [ "sops-nix.service" ];
        before = [ "samba-smbd.service" ];
        wantedBy = [
          "samba-smbd.service"
          "multi-user.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          PW_FILE="${config.sops.secrets.luffy_storage_smb_password.path}"
          if [ -s "$PW_FILE" ]; then
            PW="$(cat "$PW_FILE")"
            printf '%s\n%s\n' "$PW" "$PW" | ${pkgs.samba}/bin/smbpasswd -s -a ${user}
            ${pkgs.samba}/bin/smbpasswd -e ${user}
          fi
        '';
      };

      systemd.services.storage-private-vault-init = {
        description = "Initialize gocryptfs encrypted Private Vault at ${cfg.storageRoot}/.Private.enc";
        after = [
          "sops-nix.service"
          "local-fs.target"
          "systemd-tmpfiles-setup.service"
        ];
        unitConfig.RequiresMountsFor = [ cfg.storageRoot ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = user;
          Group = "users";
        };
        script = ''
                    set -euo pipefail
                    CIPHER="${cfg.storageRoot}/.Private.enc"
                    PASS_FILE="${config.sops.secrets.luffy_private_vault_password.path}"
                    if [ -f "$CIPHER/gocryptfs.conf" ] || [ ! -r "$PASS_FILE" ]; then
                      exit 0
                    fi
                    mkdir -p "$CIPHER"
                    chmod 700 "$CIPHER"
                    ${pkgs.gocryptfs}/bin/gocryptfs -init -q -passfile "$PASS_FILE" "$CIPHER"
                    TMP_MNT="$(mktemp -d)"
                    trap '${pkgs.fuse3}/bin/fusermount3 -u "$TMP_MNT" >/dev/null 2>&1 || true; rmdir "$TMP_MNT" >/dev/null 2>&1 || true' EXIT
                    ${pkgs.gocryptfs}/bin/gocryptfs -q -passfile "$PASS_FILE" "$CIPHER" "$TMP_MNT"
                    mkdir -p "$TMP_MNT/Passwords" "$TMP_MNT/Personal" "$TMP_MNT/Documents_Sensitive" "$TMP_MNT/Keys_and_Recovery"
                    chmod 700 "$TMP_MNT/Passwords" "$TMP_MNT/Personal" "$TMP_MNT/Documents_Sensitive" "$TMP_MNT/Keys_and_Recovery"
                    cat > "$TMP_MNT/README.txt" <<'EOF'
          NFP Encrypted Private Vault (gocryptfs AES-256-GCM)
          --------------------------------------------------
          Ciphertext lives encrypted at /Storage/.Private.enc on luffy.
          Use `private-vault-unlock` to open ~/Private and `private-vault-lock` to lock it.
          EOF
                    chmod 600 "$TMP_MNT/README.txt"
        '';
      };
    })

    (mkIf (cfg.mode == "client") {
      environment.systemPackages = [ pkgs.cifs-utils ];

      sops.templates."luffy-storage-smb.creds" = {
        content = ''
          username=${user}
          password=${config.sops.placeholder.luffy_storage_smb_password}
        '';
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.mountPoint} 0755 root root -"
        "d ${vaultMount} 0700 ${user} users -"
      ];

      fileSystems."${cfg.mountPoint}" = {
        device = "//${cfg.serverIp}/${cfg.shareName}";
        fsType = "cifs";
        options = [
          "credentials=${config.sops.templates."luffy-storage-smb.creds".path}"
          "uid=1000"
          "gid=100"
          "file_mode=0664"
          "dir_mode=0775"
          "vers=3.1.1"
          "soft"
          "nofail"
          "x-systemd.automount"
          "noauto"
          "x-systemd.idle-timeout=300"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
          "_netdev"
          "x-systemd.before=shutdown.target"
        ];
      };
    })
  ]);
}
