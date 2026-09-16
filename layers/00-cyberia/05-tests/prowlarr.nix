# NixOS VM test: Prowlarr service starts and listens on :9696.
# Regression test for the StateDirectory conflict (2026-09-16): systemd's
# StateDirectory= setup failed with "Device or resource busy" when
# /var/lib/prowlarr was an impermanence bind-mount. The fix removes
# StateDirectory from the service and relies on the nixarr data dir
# (/data/.state/nixarr/prowlarr) via the -data flag.
{
  name = "prowlarr-test";

  nodes.machine =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      # Mock options required by the media-stack modules in isolation
      options = {
        layers.layer-10.system.config.impermanence.enable = lib.mkEnableOption "impermanence";
        environment.persistence = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        layers.meta.primaryUser = lib.mkOption {
          type = lib.types.str;
          default = "t0psh31f";
        };
        layers.layer-20.services.config.media-stack = {
          user = lib.mkOption {
            type = lib.types.str;
            default = "media";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = "media";
          };
        };
      };

      config = {
        _module.args.inputs = { };

        # Group must exist for the media-stack tmpfiles rules
        users.groups.media = { };
        users.users.media = {
          isSystemUser = true;
          group = "media";
        };

        # Stand-in for the impermanence bind mount: a regular dir at
        # /var/lib/prowlarr owned by media:media (same as the real host).
        # This reproduces the StateDirectory conflict condition.
        system.activationScripts.prowlarr-state-dir = ''
          mkdir -p /var/lib/prowlarr
          chown media:media /var/lib/prowlarr
        '';

        services.prowlarr.enable = true;

        # The fix under test: no StateDirectory directive, static user
        systemd.services.prowlarr.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = lib.mkForce "media";
          Group = lib.mkForce "media";
          StateDirectory = lib.mkForce null;
        };

        system.stateVersion = "25.05";
      };
    };

  testScript = ''
    start_all()

    # Service starts without the StateDirectory conflict
    machine.wait_for_unit("prowlarr.service")
    machine.wait_for_open_port(9696)

    # Health endpoint responds OK
    machine.succeed("curl -s --max-time 5 http://127.0.0.1:9696/ping | grep -q OK")

    # No "Device or resource busy" in the journal (the original failure mode)
    machine.fail(
      "journalctl -u prowlarr | grep -q 'Device or resource busy'"
    )

    print("prowlarr-test: all assertions passed")
  '';
}
