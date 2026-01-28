{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.ssh-agent;
in
{
  options.services.ssh-agent = {
    enable = mkEnableOption "SSH Agent service for desktop environments";

    package = mkOption {
      type = types.package;
      default = pkgs.openssh;
      description = "SSH package to use";
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      startAgent = true;
      agentTimeout = "1h";
      extraConfig = ''
        AddKeysToAgent yes
      '';
    };

    # Ensure ssh-agent is available in user sessions
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
