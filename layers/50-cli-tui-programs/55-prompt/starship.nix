{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
  stellarRaw = inputs.stellar.packages.${pkgs.stdenv.hostPlatform.system}.default or null;
  stellarPkg =
    if stellarRaw != null && stellarRaw ? overrideAttrs then
      stellarRaw.overrideAttrs (_old: {
        vendorHash = "sha256-nhoKZpOlzYhZGaccVlozpNczUJeKkKC1C52VDxpQ8L0=";
        proxyVendor = true;
      })
    else
      stellarRaw;
in
{
  home = lib.mkIf cfg.enable {
    home.packages = lib.optional (stellarPkg != null) stellarPkg;

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;

      settings = {
        "$schema" = "https://starship.rs/config-schema.json";
        add_newline = true;
        format = "[](fg:color_orange)[](bg:color_yellow fg:color_orange)$directory[](bg:color_green fg:color_yellow)[](bg:color_aqua fg:color_green)$c$cpp$rust$golang$nodejs$python[](bg:color_purple fg:color_aqua)[ ](fg:color_purple)$fill[](fg:color_aqua)$cmd_duration[](bg:color_aqua fg:color_purple)$memory_usage[](bg:color_purple fg:color_bg1)$time[](fg:color_bg1)\n$character";
        # format = "[](fg:color_orange)$os$username[](bg:color_yellow fg:color_orange)$directory[](bg:color_green fg:color_yellow)$git_branch$git_status[](bg:color_aqua fg:color_green)$c$cpp$rust$golang$nodejs$python[](bg:color_purple fg:color_aqua)$docker_context[ ](fg:color_purple)$fill[](fg:color_aqua)$cmd_duration[](bg:color_aqua fg:color_purple)$memory_usage[](bg:color_purple fg:color_bg1)$time[](fg:color_bg1)\n$character";
        palette = "matugen";

        palettes.matugen = lib.mkMerge [
          {
            color_fg0 = lib.mkDefault "#fbf1c7";
            color_bg1 = lib.mkDefault "#3c3836";
            color_bg3 = lib.mkDefault "#665c54";
            color_blue = lib.mkDefault "#458588";
            color_aqua = lib.mkDefault "#689d6a";
            color_green = lib.mkDefault "#98971a";
            color_orange = lib.mkDefault "#d65d0e";
            color_purple = lib.mkDefault "#b16286";
            color_red = lib.mkDefault "#cc241d";
            color_yellow = lib.mkDefault "#d79921";
          }
          (lib.mkIf cfg.headless (
            let
              allThemes = import ../58-theming/_themes.nix { inherit lib; };
              selectedThemeName = cfg.theming.theme or "tokyo-night";
              themeColors = allThemes.${selectedThemeName} or allThemes."tokyo-night";
            in
            {
              color_fg0 = themeColors.onSurface;
              color_bg1 = themeColors.terminal.black;
              color_bg3 = themeColors.terminal.black;
              color_blue = themeColors.terminal.blue;
              color_aqua = themeColors.terminal.cyan;
              color_green = themeColors.terminal.green;
              color_orange = themeColors.secondary;
              color_purple = themeColors.terminal.magenta;
              color_red = themeColors.error;
              color_yellow = themeColors.terminal.yellow;
            }
          ))
        ];

        fill = {
          symbol = "·";
          disabled = false;
        };
        character = {
          success_symbol = "[ ](bold blue)";
          error_symbol = "[ ](bold red)";
          vimcmd_symbol = "[ ](bold yellow)";
        };
        os = {
          disabled = false;
          style = "bg:color_orange fg:color_bg1";
          symbols = {
            Ubuntu = "🐧";
            NixOS = "[ ](bg:color_orange fg:cyan)";
            Windows = "󰍲";
            SUSE = "";
            Raspbian = "󰐿";
            Mint = "󰣭";
            Macos = "󰀵";
            Manjaro = "";
            Linux = "󰌽";
            Gentoo = "󰣨";
            Fedora = "󰣛";
            Alpine = "";
            Amazon = "";
            Android = "";
            AOSC = "";
            Arch = "󰣇";
            Artix = "󰣇";
            EndeavourOS = "";
            CentOS = "";
            Debian = "󰣚";
            Redhat = "󱄛";
            RedHatEnterprise = "󱄛";
            Pop = "";
          };
        };
        username = {
          show_always = true;
          style_user = "bg:color_orange fg:color_fg0";
          style_root = "bg:color_orange fg:color_fg0";
          format = "[  $user]($style)";
        };
        directory = {
          style = "fg:color_fg0 bg:color_yellow";
          format = "[ 📂 $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
          substitutions = {
            "Documents" = " ";
            "Downloads" = "󱃩 ";
            "Music" = " ";
            "Notes" = " ";
            "Pictures" = "   ";
            "Projects" = "  ";
            "Videos" = " ";
            "Agents" = " ";
            "Games" = "  ";
            "Clan" = " ";
            ".config" = " ";
            ".local" = " ";
            ".nix" = "󱄅 ";
            ".ssh" = "󰣀 ";
            ".gemini" = "󰪁 ";
            ".mozilla" = " ";
            ".npm" = " ";
            ".pnpm" = " ";
            ".yarn" = " ";
            ".rustup" = "󱘗 ";
            ".cargo" = "󱣘 ";
            ".git" = " ";
          };
        };
        env_var.USER = {
          format = "[   $env_value  ](bg:color_bg3 fg:color_fg0)";
          disabled = false;
        };
        git_branch = {
          symbol = "";
          style = "bg:color_green";
          format = "[[ $symbol $branch ](fg:color_fg0 bg:color_green)]($style)";
        };
        git_status = {
          style = "bg:color_green";
          format = "[[($all_status$ahead_behind )](fg:color_bg1 bg:color_green)]($style)";
          stashed = "💾";
          ahead = "📥";
          behind = "📤";
          conflicted = "⁉️";
          deleted = "🗑️";
          renamed = "🎭";
          modified = "🚧";
          staged = "🏗️";
          untracked = "❓";
        };
        memory_usage = {
          disabled = false;
          threshold = -1;
          symbol = "🐏";
          style = "bg:color_purple fg:color_bg1";
          format = "[[ $symbol$ram ](fg:color_bg1 bg:color_purple)]($style)";
        };
        nodejs = {
          symbol = "";
          style = "bg:color_aqua";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_aqua)]($style)";
        };
        c = {
          symbol = " ";
          style = "bg:color_aqua";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_aqua)]($style)";
        };
        cpp = {
          symbol = " ";
          style = "bg:color_aqua";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_aqua)]($style)";
        };
        rust = {
          symbol = "";
          style = "bg:color_aqua";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_aqua)]($style)";
        };
        golang = {
          symbol = "";
          style = "bg:color_aqua";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_aqua)]($style)";
        };
        python = {
          symbol = "";
          style = "bg:color_aqua";
          format = "[[ $symbol( $version) ](fg:color_fg0 bg:color_aqua)]($style)";
        };
        docker_context = {
          symbol = "";
          style = "bg:color_bg3";
          format = "[[ $symbol( $context) ](fg:#83a598 bg:color_bg3)]($style)";
        };
        cmd_duration = {
          min_time = 500;
          style = "bg:color_aqua fg:color_bg1";
          format = "[  🏁$duration ]($style)";
        };
        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:color_bg1 fg:color_fg0";
          format = "[[ ∞ $time ]($style)]($style)";
        };
        line_break.disabled = false;
        sudo = {
          disabled = false;
          symbol = "  ";
          format = "[$symbol]($style)";
          style = "bold yellow";
        };
      };
    };
  };
}
