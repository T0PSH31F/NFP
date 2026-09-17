{
  osConfig ? config,
  lib,
  config ? { },
  ...
}:
let
  isLuffy = osConfig.networking.hostName == "luffy";
in
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "center 1, match:title ^(Open File)(.*)$"
      "float 1, match:title ^(Open File)(.*)$"
      "center 1, match:title ^(Select a File)(.*)$"
      "float 1, match:title ^(Select a File)(.*)$"
      "center 1, match:title ^(Choose wallpaper)(.*)$"
      "float 1, match:title ^(Choose wallpaper)(.*)$"
      "size 60% 65%, match:title ^(Choose wallpaper)(.*)$"
      "center 1, match:title ^(Open Folder)(.*)$"
      "float 1, match:title ^(Open Folder)(.*)$"
      "center 1, match:title ^(Save As)(.*)$"
      "float 1, match:title ^(Save As)(.*)$"
      "center 1, match:title ^(Library)(.*)$"
      "float 1, match:title ^(Library)(.*)$"
      "center 1, match:title ^(File Upload)(.*)$"
      "float 1, match:title ^(File Upload)(.*)$"
      "center 1, match:title ^(.*)(wants to save)$"
      "float 1, match:title ^(.*)(wants to save)$"
      "center 1, match:title ^(.*)(wants to open)$"
      "float 1, match:title ^(.*)(wants to open)$"

      # Specific Apps
      "float 1, match:class ^(blueberry\\.py)$"
      "float 1, match:class ^(guifetch)$"
      "float 1, match:class ^(pavucontrol)$"
      "size 45% 45%, match:class ^(pavucontrol)$"
      "center 1, match:class ^(pavucontrol)$"
      "float 1, match:class ^(org\\.pulseaudio\\.pavucontrol)$"
      "size 45% 45%, match:class ^(org\\.pulseaudio\\.pavucontrol)$"
      "center 1, match:class ^(org\\.pulseaudio\\.pavucontrol)$"
      "float 1, match:class ^(nm-connection-editor)$"
      "size 45% 45%, match:class ^(nm-connection-editor)$"
      "center 1, match:class ^(nm-connection-editor)$"
      "float 1, match:class .*plasmawindowed.*"
      "float 1, match:class kcm_.*"
      "float 1, match:class .*bluedevilwizard"
      "float 1, match:title .*Welcome"
      "float 1, match:title .*Shell conflicts.*"
      "float 1, match:class org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde"
      "size 60% 65%, match:class org\\.freedesktop\\.impl\\.portal\\.desktop\\.kde"
      "float 1, match:class ^(Zotero)$"
      "size 45% 45%, match:class ^(Zotero)$"

      # Move / Focus
      "float 1, match:class ^(plasma-changeicons)$"
      "no_initial_focus 1, match:class ^(plasma-changeicons)$"
      "move 999999 999999, match:class ^(plasma-changeicons)$"
      "move 40 80, match:title ^(Copying — Dolphin)$"

      # Tiling
      "tile 1, match:class ^dev\\.warp\\.Warp$"

      # OMOS Companion — floating overlay
      "float 1, match:class ^(oh-my-opencode-slim-companion)$"
      "size 120px 120px, match:class ^(oh-my-opencode-slim-companion)$"
      "move 100%-140 100%-140, match:class ^(oh-my-opencode-slim-companion)$"
      "pin 1, match:class ^(oh-my-opencode-slim-companion)$"

      # Picture-in-Picture
      "float 1, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
      "keep_aspect_ratio 1, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
      "move 73% 72%, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
      "size 25% 25%, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"
      "pin 1, match:title ^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"

      # Tearing
      "immediate 1, match:title .*\\.exe"
      "immediate 1, match:title .*minecraft.*"
      "immediate 1, match:class ^(steam_app).*"
    ];

    # ######## Workspace rules ########
    workspace = [
      "special:special, gapsout:30"
    ];

    # ######## Layer rules ########
    layerrule =
      let
        baseRules = [
          "xray 1, match:namespace .*"
          "no_anim 1, match:namespace vicinae"
          "no_anim 1, match:namespace selection"
          "no_anim 1, match:namespace anyrun"
          "no_anim 1, match:namespace hyprpicker"
          "blur 1, match:namespace gtk-layer-shell"
          "blur 1, match:namespace launcher"
          "blur 1, match:namespace notifications"
          "blur 1, match:namespace logout_dialog"

          # Fast Launchers
          "no_anim 1, match:namespace gtk4-layer-shell"
        ];
      in
      if isLuffy then
        builtins.filter (rule: !(lib.strings.hasInfix "blur" rule)) baseRules
      else
        baseRules;
  };
}
