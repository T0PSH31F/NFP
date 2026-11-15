{
  config,
  lib,
  pkgs,
  inputs ? null,
  ...
}:
let
  cfg = config.layers.layer-20.services.config.ci.github-runner;
in
{
  options.layers.layer-20.services.config.ci.github-runner = {
    enable = lib.mkEnableOption "GitHub Actions runner for deployment";

    url = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/T0PSH31F/NFP";
      description = "Repository URL to register runner against";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."github_token" = {
      sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
    };

    sops.secrets."ci_deploy_ssh_key" = {
      sopsFile = ../../../layers/00-cyberia/03-treasure/secrets/external_services.yaml;
    };

    services.github-runners.nfp-deployer = {
      enable = true;
      name = "nfp-deployer-${config.networking.hostName}";
      inherit (cfg) url;
      tokenFile = config.sops.secrets."github_token".path;
      extraPackages =
        (with pkgs; [
          git
          nix
          jq
          openssh
        ])
        ++ lib.optional (
          inputs != null && inputs ? clan-core
        ) inputs.clan-core.packages.${pkgs.stdenv.hostPlatform.system}.clan-cli;
      extraLabels = [
        "nixos"
        "deployer"
        "nfp"
        config.networking.hostName
      ];
      replace = true;
      serviceOverrides = {
        Restart = lib.mkForce "on-failure";
        RestartSec = "30s";
        OOMScoreAdjust = -200;
        LoadCredential = [
          "ci-deploy-ssh-key:${config.sops.secrets."ci_deploy_ssh_key".path}"
        ];
      };
    };
  };
}
