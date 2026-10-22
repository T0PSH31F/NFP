# Desktop Experience Selector — single mutually-exclusive enum for the entire
# visual environment.  Every experience adapter reads `exp` from here; nothing
# else in the tree should check compositor directly.
{
  config,
  lib,
  osConfig ? config,
  ...
}:
let
  hasDesktopTag = builtins.elem "desktop" (osConfig.machine.tags or [ ]);
  hasServerTag = builtins.elem "server" (osConfig.machine.tags or [ ]);
  exp = config.layers.desktop.experience;

  # Derive compositor from experience — experiences own their compositor choice.
  derivedCompositor =
    {
      "noctalia-hyprland" = "hyprland";
      "noctalia-niri" = "niri";
      "noctalia-umbriel" = "umbriel";
      "nixarchy-rise" = "hyprland";
      "custom-vibe-quickshell" = "hyprland";
      "micro-smol-ai" = "dwl";
      "headless-console" = "none";
      "none" = "none";
    }
    .${exp} or "none";

  # Derive the default greeter from the experience:
  #   - noctalia-*         → noctalia-greeter   (native Noctalia login screen)
  #   - nixarchy-rise      → nixarchy-greeter   (Omarchy's own DM)
  #   - headless-console   → tuigreet           (zero GUI dependency)
  #   - everything else    → sddm-astronaut     (eye-candy Qt6 fallback)
  derivedGreeter =
    if lib.hasPrefix "noctalia-" exp then
      "noctalia-greeter"
    else if exp == "nixarchy-rise" then
      "nixarchy-greeter"
    else if exp == "headless-console" then
      "tuigreet"
    else if exp == "none" then
      "tuigreet"
    else
      "sddm-astronaut";
in
{
  options.layers.desktop = {
    enable = lib.mkEnableOption "Desktop subsystem";

    experience = lib.mkOption {
      type = lib.types.enum [
        "noctalia-hyprland" # Noctalia Shell v5 on Hyprland
        "noctalia-niri" # Noctalia Shell v5 on Niri
        "noctalia-umbriel" # Noctalia Shell v5 on Umbriel compositor
        "nixarchy-rise" # Nixarchy (Omarchy 4.x) + HANCORE Quickshell Rise
        "custom-vibe-quickshell" # Live QML hot-reload lab (any compositor)
        "micro-smol-ai" # Ultra-lightweight dwl/cage for low-power AI laptops
        "headless-console" # TUI-only / server profile
        "none"
      ];
      default = "none";
      description = ''
        Single active desktop experience preset.  Only ONE value is active at
        a time; switching to a different value and rebuilding produces a clean
        environment with zero bleed from the previous experience.
      '';
    };

    compositor = lib.mkOption {
      type = lib.types.enum [
        "none"
        "hyprland"
        "niri"
        "umbriel"
        "dwl"
      ];
      default = "none";
      readOnly = false;
      description = "Compositor engine derived from the selected experience. Override only when you need to decouple.";
    };

    # Propagated to greeter.nix — each experience owns its default login screen.
    derivedGreeter = lib.mkOption {
      type = lib.types.str;
      default = "tuigreet";
      internal = true;
      description = "Greeter type automatically derived from the selected experience. Not meant to be set by the user.";
    };
  };

  config = {
    layers.desktop.compositor = lib.mkDefault derivedCompositor;
    layers.desktop.derivedGreeter = lib.mkDefault derivedGreeter;

    assertions = [
      {
        assertion = !(hasServerTag && !hasDesktopTag && exp != "none" && exp != "headless-console");
        message = ''
          Server-tagged machines must set
            layers.desktop.experience = "none";
          or "headless-console". Got: "${exp}".
        '';
      }
    ];
  };
}
