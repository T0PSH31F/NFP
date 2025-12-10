{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      format = ''
        [╭─](bold green)$username[@](bold yellow)$hostname [in ](bold white)$directory$git_branch$git_status$cmd_duration
        [╰─](bold green)$character
      '';

      character = {
        success_symbol = "[ ](bold blue)";
        error_symbol = "[ ](bold red)";
      };

      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
      };

      git_branch = {
        style = "bold purple";
        symbol = " ";
      };

      git_status = {
        style = "bold red";
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
      };

      cmd_duration = {
        min_time = 500;
        format = " took [$duration](bold yellow)";
      };

      nix_shell = {
        symbol = "❄️ ";
      };
    };
  };
}
