# flake-parts/features/home/documents/default.nix
# Documentation, office, and publishing tools
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-config.documents;
in
{
  options.home-config.documents = {
    enable = lib.mkEnableOption "Documents & Publishing tools";

    office = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable LibreOffice suite";
      };
      full = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to install the full LibreOffice suite (fresh) instead of the standard bin";
      };
    };

    publishing = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable publishing tools (Pandoc, LaTeX, Scribus, Sigil)";
      };
    };

    notes = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable note-taking tools (Obsidian)";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.flatten [
      (lib.optional cfg.office.enable (
        if cfg.office.full then pkgs.libreoffice-fresh else pkgs.libreoffice
      ))

      (lib.optionals cfg.publishing.enable [
        pkgs.pandoc
        pkgs.texliveFull
        pkgs.scribus
        pkgs.sigil
      ])

      (lib.optional cfg.notes.enable pkgs.obsidian)

      # Essential for icon display across many apps
      pkgs.hicolor-icon-theme
    ];
  };
}
