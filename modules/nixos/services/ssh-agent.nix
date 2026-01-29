{ config, lib, pkgs, ... }:

let
  cfg = config.services.ssh-agent;
in
{
  options.services.ssh-agent = {
    enable = lib.mkEnableOption "SSH Agent service for desktop sessions";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.openssh;
      description = "SSH package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure SSH client settings
    programs.ssh = {
      # Don't use the built-in startAgent to avoid conflicts
      # We define our own systemd service below for better control
      startAgent = false;
      agentTimeout = "1h";
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };

    # Custom ssh-agent systemd user service
    systemd.user.services.ssh-agent = {
      description = "SSH Agent";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
        ExecStart = "${cfg.package}/bin/ssh-agent -D -a $SSH_AUTH_SOCK";
        Restart = "on-failure";
      };
    };

    # Set SSH_AUTH_SOCK environment variable
    environment.sessionVariables = {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.socket";
    };
  };
}
