# Obsidian Note-Taking Client Module
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.layers.layer-60.gui.obsidian = {
    enable = lib.mkEnableOption "Obsidian note-taking tool";
  };

  home =
    let
      cfg = config.layers.layer-60.gui.obsidian;
    in
    lib.mkIf cfg.enable {
      home.packages = [ pkgs.obsidian ];
    };
}
