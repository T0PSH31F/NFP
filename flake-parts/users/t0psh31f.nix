# flake-parts/users/t0psh31f.nix
{
  pkgs,
  inputs,
  config,
  ...
}:
{
  # System-level user settings not managed by Clan
  users.users.t0psh31f = {
    isNormalUser = true;
    description = "t0psh31f";
    shell = pkgs.zsh;
    # Authorized keys are also managed by clan-inventory.nix (admin-access),
    # but we keep them here for local login consistency.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJrQr8qxQTw45PNpsDNahVE23tpV3Zap+IKr6eVkL75Z t0psh31f@grandlix.gang"
    ];
  };

  # Home Manager configuration for t0psh31f
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.users.t0psh31f =
    { config, ... }:
    {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
        ../features/home
      ];

      sops.age.keyFile = "/home/t0psh31f/.config/sops/age/keys.txt";

      sops.secrets.git_name = {
        sopsFile = ../../secrets/git.yaml;
        format = "yaml";
        # key = "git_name"; # defaults to attribute name
      };
      sops.secrets.git_email = {
        sopsFile = ../../secrets/git.yaml;
        format = "yaml";
      };

      # Vicinae secrets (API keys, tokens, etc.)
      sops.secrets."vicinae.json" = {
        sopsFile = ../../secrets/vicinae.yaml;
        format = "yaml";
      };

      # AI/LLM API Keys
      sops.secrets.gemini_api_key = {
        sopsFile = ../../secrets/vicinae.yaml;
        format = "yaml";
      };
      sops.secrets.openrouter_api_key = {
        sopsFile = ../../secrets/vicinae.yaml;
        format = "yaml";
      };

      sops.templates."git-config".content = ''
        [user]
          name = ${config.sops.secrets.git_name.path}
          email = ${config.sops.secrets.git_email.path}
      '';

      # Export API keys as environment variables
      home.sessionVariables = {
        GEMINI_API_KEY = "$(cat ${config.sops.secrets.gemini_api_key.path})";
        OPENROUTER_API_KEY = "$(cat ${config.sops.secrets.openrouter_api_key.path})";
      };

      home.stateVersion = "25.05";
      home.username = "t0psh31f";
      home.homeDirectory = "/home/t0psh31f";

      # Enable the new CLI environment
      programs.cli-environment.enable = true;
    };

}
