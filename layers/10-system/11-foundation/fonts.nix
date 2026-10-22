# flake-parts/system/fonts.nix
{ pkgs, lib, ... }:
{
  fonts = {
    enableDefaultPackages = lib.mkForce false;

    packages = with pkgs; [
      # ── Nerd Font patched monospace families ──
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      # nerd-fonts.iosevka
      # nerd-fonts.iosevka-term
      nerd-fonts.hack
      nerd-fonts.meslo-lg
      nerd-fonts.departure-mono # Pixel-style nerd font
      nerd-fonts.proggy-clean-tt # Pixel/bitmap nerd font
      nerd-fonts.gohufont # Bitmap nerd font
      # nerd-fonts.terminess-ttf # Terminus nerd font
      nerd-fonts.symbols-only # Pure symbol/icon glyphs

      # ── Pixel / bitmap fonts ──
      cozette # Bitmap font with great unicode coverage
      tamzen # Clean bitmap font
      # scientifica # Tall bitmap font
      # zpix-pixel-font # CJK pixel font
      pixel-code
      creep
      # ark-pixel-font  # Slow to build, large CJK font — uncomment if needed
      departure-mono

      # ── Sans-serif / UI fonts ──
      inter
      nerd-fonts.noto # Nerd-patched Noto (massive unicode coverage)

      # ── Symbols & emoji ──
      font-awesome
      material-design-icons
      material-symbols
      twitter-color-emoji
      noto-fonts-cjk-sans # CJK characters
      noto-fonts-color-emoji # Google emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "FiraCode Nerd Font"
          "Iosevka Nerd Font"
          "Cozette"
          "Symbols Nerd Font"
        ];
        sansSerif = [
          "Inter"
          "Noto Sans Nerd Font"
          "Noto Sans CJK"
        ];
        serif = [
          "Noto Serif Nerd Font"
        ];
        emoji = [
          "Twitter Color Emoji"
          "Noto Color Emoji"
        ];
      };
    };
  };
}
