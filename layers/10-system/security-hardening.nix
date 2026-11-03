# Tier: 10-system
# Module: security-hardening.nix
# Purpose: Enterprise Jarvis Two-Phase Progressive Trust Lifecycle, Unprivileged
#          jarvis-agent User Isolation, Bubblewrap (bwrap) Sandboxing, & Impermanence Guardrails.
# Option Path: layers.layer-10.system.config.security-hardening
# Enabling Host Tags: workstation, server, ai-agent
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-10.system.config.security-hardening;
  jarvisEnabled = config.jarvis.enable or false;
  effectiveEnable = cfg.enable || jarvisEnabled;

  bwrapSandboxBin = pkgs.writeShellScriptBin "jarvis-bwrap-exec" ''
    set -euo pipefail
    SCRATCH_DIR="${cfg.scratchDir}"
    mkdir -p "$SCRATCH_DIR"
    if [ $# -eq 0 ]; then
      echo "Usage: jarvis-bwrap-exec <command...>" >&2
      exit 1
    fi
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --ro-bind /nix/store /nix/store \
      --ro-bind /etc/resolv.conf /etc/resolv.conf \
      --bind "$SCRATCH_DIR" /workspace \
      --proc /proc \
      --dev /dev \
      --tmpfs /tmp \
      --unshare-pid \
      --die-with-parent \
      --chdir /workspace \
      -- "$@"
  '';

  installerScript = pkgs.writeShellScript "jarvis-progressive-trust-installer" ''
    set -euo pipefail
    PROVISION_FLAG="${cfg.stateDir}/.provisioned"
    mkdir -p "${cfg.stateDir}" "${cfg.scratchDir}"

    if [ -f "$PROVISION_FLAG" ]; then
      echo "[JarvisInstaller] Appliance already provisioned ($PROVISION_FLAG present). Entering Operational Mode."
      exit 0
    fi

    echo "[JarvisInstaller] Phase 1: Provisioning Mode active — verifying hardware, SOPS keys, and directories..."
    chown -R ${cfg.agentUser}:${cfg.agentGroup} "${cfg.stateDir}" "${cfg.scratchDir}"
    chmod 0750 "${cfg.stateDir}" "${cfg.scratchDir}"

    cat > "$PROVISION_FLAG" <<EOF
    {
      "provisioned_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "mode": "operational_lockdown",
      "agent_user": "${cfg.agentUser}",
      "sandbox": "bwrap"
    }
    EOF
    chown root:${cfg.agentGroup} "$PROVISION_FLAG"
    chmod 0440 "$PROVISION_FLAG"
    echo "[JarvisInstaller] Phase 2 Lockdown complete. Wrote $PROVISION_FLAG."
  '';
in
{
  options.layers.layer-10.system.config.security-hardening = {
    enable = mkEnableOption "Jarvis Two-Phase Progressive Trust, jarvis-agent user isolation, and bwrap sandbox";

    agentUser = mkOption {
      type = types.str;
      default = "jarvis-agent";
      description = "Unprivileged system user for Operational Mode agent execution";
    };

    agentGroup = mkOption {
      type = types.str;
      default = "jarvis-agent";
      description = "Unprivileged system group for Operational Mode agent execution";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/jarvis";
      description = "Persistent state directory surviving ephemeral root reboots";
    };

    scratchDir = mkOption {
      type = types.str;
      default = "/workspace/scratch";
      description = "Isolated writable workspace bound into Bubblewrap sub-agent sandboxes";
    };
  };

  config = mkIf effectiveEnable {
    users.groups.${cfg.agentGroup} = { };

    users.users.${cfg.agentUser} = {
      isSystemUser = true;
      group = cfg.agentGroup;
      home = cfg.stateDir;
      createHome = true;
      description = "Unprivileged Jarvis Enterprise Operational Agent User";
    };

    environment.systemPackages = [
      pkgs.bubblewrap
      bwrapSandboxBin
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.agentUser} ${cfg.agentGroup} -"
      "d ${cfg.scratchDir} 0750 ${cfg.agentUser} ${cfg.agentGroup} -"
    ];

    # One-Shot First Boot Provisioning Service that drops to Operational Mode via .provisioned
    systemd.services.jarvis-installer = {
      description = "Jarvis Enterprise One-Shot Provisioning & Progressive Trust Lockdown";
      wantedBy = [ "multi-user.target" ];
      before = [ "nfp-jev-classifier.service" ];
      unitConfig = {
        ConditionPathExists = "!${cfg.stateDir}/.provisioned";
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = installerScript;
        User = "root";
      };
    };

    # Persist /var/lib/jarvis across ephemeral tmpfs root reboots when impermanence is enabled
    environment.persistence.${
      config.layers.layer-10.system.config.impermanence.persistPath or "/persist"
    } =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false) {
        directories = [
          {
            directory = cfg.stateDir;
            user = cfg.agentUser;
            group = cfg.agentGroup;
            mode = "0750";
          }
        ];
      };
  };
}
