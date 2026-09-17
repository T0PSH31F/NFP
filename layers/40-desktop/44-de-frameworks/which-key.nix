# ⌨️ wlr-which-key — Visual Wayland Keybinding Overlay
# Generates wlr-which-key YAML from action-registry.nix
{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:
let
  cfg =
    osConfig.layers.layer-40.desktop.frameworks.which-key
      or config.layers.layer-40.desktop.frameworks.which-key or { };
  hasDesktopTag = builtins.elem "desktop" (osConfig.machine.tags or config.machine.tags or [ ]);

  actionRegistry = import ./action-registry.nix { inherit lib; };
  inherit (actionRegistry) groups;
in
{
  config = lib.mkIf (cfg.enable or hasDesktopTag) {
    home.packages = [ pkgs.wlr-which-key ];

    xdg.configFile."wlr-which-key/config.yaml".text = ''
            # wlr-which-key Configuration (NFP Action Registry)
            font: "Inter 12"
            background: "#1e1e2e"
            color: "#cdd6f4"
            border: "#89b4fa"
            border_width: 2
            corner_radius: 12
            anchor: "center"
            margin_right: 0
            margin_bottom: 0

            menu:
              d:
                name: "${groups.desktop.name}"
                submenu:
      ${lib.concatMapStringsSep "\n" (a: ''
        ${lib.toLower a.chord}:
          name: "${a.desc}"
          cmd: "${a.cmd}"'') groups.desktop.actions}

              w:
                name: "${groups.window.name}"
                submenu:
      ${lib.concatMapStringsSep "\n" (a: ''
        ${lib.toLower a.chord}:
          name: "${a.desc}"
          cmd: "${a.cmd}"'') groups.window.actions}

              f:
                name: "${groups.fleet.name}"
                submenu:
      ${lib.concatMapStringsSep "\n" (a: ''
        ${lib.toLower a.chord}:
          name: "${a.desc}"
          cmd: "${a.cmd}"'') groups.fleet.actions}

              a:
                name: "${groups.agents.name}"
                submenu:
      ${lib.concatMapStringsSep "\n" (a: ''
        ${lib.toLower a.chord}:
          name: "${a.desc}"
          cmd: "${a.cmd}"'') groups.agents.actions}

              m:
                name: "${groups.media.name}"
                submenu:
      ${lib.concatMapStringsSep "\n" (a: ''
        ${lib.toLower a.chord}:
          name: "${a.desc}"
          cmd: "${a.cmd}"'') groups.media.actions}

              s:
                name: "${groups.system.name}"
                submenu:
      ${lib.concatMapStringsSep "\n" (a: ''
        ${lib.toLower a.chord}:
          name: "${a.desc}"
          cmd: "${a.cmd}"'') groups.system.actions}

              g:
                name: "${groups.git.name}"
                submenu:
      ${lib.concatMapStringsSep "\n" (a: ''
        ${lib.toLower a.chord}:
          name: "${a.desc}"
          cmd: "${a.cmd}"'') groups.git.actions}
    '';
  };
}
