{
  pkgs,
  ...
}:

let
  # Shared rofi theme setup — sources Noctalia Material You colors at runtime
  # Uses $primary for accents, $surface for bg, $secondary for highlights
  # Falls back to dark neon palette if noctalia-colors.conf is missing
  rofiTheme = ''
    NOCTALIA_COLORS="$HOME/.config/hypr/noctalia/noctalia-colors.conf"
    if [ -f "$NOCTALIA_COLORS" ]; then
      eval "$(sed -n 's/^\$\([a-z_][a-z_]*\) = rgb(\([0-9a-fA-F]\{6,\}\))$/\1=\2/p' "$NOCTALIA_COLORS")"
    fi
    ROFI_PRIMARY="''${primary:-eab4f4}"
    ROFI_SECONDARY="''${secondary:-d9beda}"
    ROFI_SURFACE="''${surface:-161216}"
    ROFI_TEXT="''${on_surface:-e0e0ff}"
    rofi_with_theme() {
      ${pkgs.rofi}/bin/rofi "$@" \
        -theme-str "window {width: 62%; height: 82%; background-color: #''${ROFI_SURFACE}f2; border: 2px solid; border-color: #''${ROFI_PRIMARY}; border-radius: 18px; padding: 20px;}" \
        -theme-str "mainbox {background-color: transparent; children: [inputbar, listview];}" \
        -theme-str "inputbar {background-color: #''${ROFI_SURFACE}; border: 1.5px solid; border-color: #''${ROFI_PRIMARY}bb; border-radius: 24px; padding: 10px 18px; margin: 0 0 14px 0; children: [prompt, entry];}" \
        -theme-str "prompt {background-color: transparent; text-color: #''${ROFI_PRIMARY}; font: \"JetBrainsMono Nerd Font Bold 12\"; margin: 0 10px 0 0;}" \
        -theme-str "entry {background-color: transparent; text-color: #''${ROFI_TEXT}; font: \"JetBrainsMono Nerd Font 11\"; placeholder-color: #''${ROFI_TEXT}77;}" \
        -theme-str "listview {background-color: transparent; columns: 1; spacing: 8px; lines: 0; fixed-height: false; scrollbar: false;}" \
        -theme-str "element {background-color: #''${ROFI_SURFACE}aa; text-color: #''${ROFI_TEXT}; border: 1.5px solid; border-color: #''${ROFI_SECONDARY}44; padding: 10px 16px; border-radius: 24px; font: \"JetBrainsMono Nerd Font 10.5\";}" \
        -theme-str "element normal normal {background-color: #''${ROFI_SURFACE}88; text-color: #''${ROFI_TEXT}; border-color: #''${ROFI_SECONDARY}44;}" \
        -theme-str "element alternate normal {background-color: #''${ROFI_SURFACE}cc; text-color: #''${ROFI_TEXT}; border-color: #''${ROFI_SECONDARY}44;}" \
        -theme-str "element selected normal {background-color: #''${ROFI_PRIMARY}; text-color: #''${ROFI_SURFACE}; border: 1.5px solid; border-color: #ffffff; border-radius: 24px; font: \"JetBrainsMono Nerd Font Bold 10.5\";}" \
        -theme-str "element selected active {background-color: #''${ROFI_PRIMARY}; text-color: #''${ROFI_SURFACE}; border: 1.5px solid; border-color: #ffffff; border-radius: 24px; font: \"JetBrainsMono Nerd Font Bold 10.5\";}" \
        -theme-str "element-text {background-color: transparent; text-color: inherit; highlight: bold #''${ROFI_PRIMARY};}" \
        -theme-str "element-icon {background-color: transparent; size: 1.2em;}"
    }
  '';

  alphabetical_cheatsheet = pkgs.writeShellScriptBin "alphabetical-cheatsheet" ''
      ${rofiTheme}
      ACTIONS="
    Super+A                 | Noctalia launcher               | Noctalia-specific launcher experience   | noctalia.nix       | local
    Super+D -> B            | Brave Browser                   | Web browser                             | action-registry    | local
    Super+D -> C            | Discord / Vesktop               | Communications                          | action-registry    | local
    Super+D -> E            | Helix / Neovim                  | Editor selector                         | action-registry    | local
    Super+D -> F            | Dolphin                         | File manager                            | action-registry    | local
    Super+D -> M            | Spotify                         | Music application                       | action-registry    | local
    Super+D -> N            | Obsidian                        | PKM Notes                               | action-registry    | local
    Super+D -> O            | Screenshot Region               | Hypr-screenshot tool                    | action-registry    | local
    Super+D -> S            | Settings                        | Nwg-look system settings                | action-registry    | local
    Super+Enter             | wlr-which-key                   | All-map visual keybinding index         | which-key.nix      | local
    Super+F -> A            | AdGuard Home                    | Fleet DNS shield                        | action-registry    | fleet-remote
    Super+F -> C            | Clan Command Menu               | Safe Clan machines list                 | action-registry    | local
    Super+F -> G            | Grafana                         | Observability dashboard                 | action-registry    | fleet-remote
    Super+F -> H            | Homepage                        | NFP Homepage dashboard                  | action-registry    | fleet-remote
    Super+F -> L            | Fleet Logs                      | Systemd journal log tail                | action-registry    | local
    Super+F -> S            | SSH Fleet Host Selector         | SSH to fleet host                       | action-registry    | fleet-remote
    Super+F -> T            | Tailscale Status                | Network mesh status                     | action-registry    | local
    Super+G -> G            | Lazygit                         | Git TUI interface                       | action-registry    | local
    Super+G -> H            | Herdr Sessions                  | Persistent terminal sessions            | action-registry    | local
    Super+G -> S            | Git Status                      | Check git status in Ghostty             | action-registry    | local
    Super+M -> D            | Downloads Queue                 | Usenet & Torrent downloads              | action-registry    | fleet-remote
    Super+M -> J            | Jellyfin                        | Media server                            | action-registry    | fleet-remote
    Super+M -> K            | Kodi                            | Media center                            | action-registry    | local
    Super+M -> M            | Strawberry                      | Local music player                      | action-registry    | local
    Super+M -> R            | Media Requests                  | Jellyseerr requests                     | action-registry    | fleet-remote
    Super+M -> S            | Spotify                         | Spotify desktop                         | action-registry    | local
    Super+S -> A            | Pavucontrol                     | Audio volume control                    | action-registry    | local
    Super+S -> B            | Blueman                         | Bluetooth manager                       | action-registry    | local
    Super+S -> C            | Theme Selector                  | Matugen / Nwg-look theme control        | action-registry    | local
    Super+S -> L            | Lock Screen                     | Hyprlock lock screen                    | action-registry    | local
    Super+S -> P            | Power Menu                      | Wlogout power menu                      | action-registry    | local
    Super+S -> R            | Reload Compositor               | Reload Hyprland configuration           | action-registry    | local
    Super+S -> W            | Nmtui                           | Wi-Fi / network TUI                     | action-registry    | local
    Super+Shift+A           | Agents Map                      | Autonomous AI Agents map root           | action-registry    | local
    Super+Shift+A -> H      | Hermes Agent                    | Hermes CLI                              | action-registry    | local
    Super+Shift+A -> L      | Agent Logs                      | Hermes service log tail                 | action-registry    | local
    Super+Shift+A -> M      | Btop                            | System & Agent monitoring               | action-registry    | local
    Super+Shift+A -> O      | OpenCode Desktop                | AI coding workspace                     | action-registry    | local
    Super+Shift+A -> P      | Gemini Chat Panel               | Toggle right Gemini panel               | action-registry    | local
    Super+Shift+A -> R      | Polyfloor Router                | AI Model Router status                  | action-registry    | fleet-remote
    Super+Shift+T           | Kitty                           | Fast terminal companion                 | action-registry    | local
    Super+Space             | Vicinae Launcher                | Primary Vicinae application launcher     | action-registry    | local
    Super+T                 | Ghostty                         | Primary terminal                        | action-registry    | local
    Super+W -> F            | Fullscreen                      | Toggle window fullscreen                | action-registry    | local
    Super+W -> P            | Pin Window                      | Pin window always-on-top                | action-registry    | local
    Super+W -> Q            | Close Window                    | Close focused window                    | action-registry    | local
    Super+W -> S            | Toggle Split                    | Toggle split orientation                | action-registry    | local
    Super+W -> V            | Toggle Floating                 | Toggle floating layout                  | action-registry    | local
    Super+/                 | Rofi Cheatsheet                 | Alphabetical cheat sheet index          | cheatsheets.nix    | local
    Alt+G                   | Gemini Chat Panel               | Toggle right Gemini chat panel          | hyprland/pyprland  | local
    Alt+N                   | Gedit Notepad                   | Toggle right Gedit notepad panel        | hyprland/pyprland  | local
    Alt+T                   | Ghostty Dropdown                | Toggle top Ghostty dropdown terminal    | hyprland/pyprland  | local
      "
      echo "$ACTIONS" | rofi_with_theme -dmenu -i -p "Alphabetical Index"
  '';

  cheatsheet_picker = pkgs.writeShellScriptBin "cheatsheet" ''
        ${rofiTheme}
        while true; do
          SELECTED=$(cat <<CHOICES | rofi_with_theme -dmenu -p "Cheatsheets"
        🔤 Alphabetical Action Index
        🤠 Herdr AI Harness
        👻 Ghostty Splits & Terminal Shortcuts
        🧰 z0r0 App & Tool Catalog
        🐚 Nushell
        ⚡ Zellij (Legacy / Migration)
        📝 Neovim
        ✦ Helix
        📂 Yazi
        🐚 Zsh / Ghostty
        🔍 Fzf / TV / Ripgrep
        🔧 Grep / Sed / Awk
        🐳 Docker / Podman
        💻 VMs / MicroVMs
        🚀 CLI Power Tools
        🖥️ Hyprland
        🤖 OpenCode
        🧠 Hermes Agent
        📋 Shell Aliases
        ⚡ Carapace
        🛠️ CLI Tools
        🏷️ Tag Groups
    CHOICES
          )
          [ -z "$SELECTED" ] && break
          # Trim leading/trailing whitespace from rofi output (rofi 2.0 adds padding)
          SELECTED="$(echo "$SELECTED" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
          [ -z "$SELECTED" ] && break
          case "$SELECTED" in
            "🔤 Alphabetical Action Index") ${alphabetical_cheatsheet}/bin/alphabetical-cheatsheet ;;
            "🤠 Herdr AI Harness")     ${herdr_cheatsheet}/bin/herdr-cheatsheet ;;
            "👻 Ghostty Splits & Terminal Shortcuts") ${zsh_cheatsheet}/bin/zsh-cheatsheet ;;
            "🧰 z0r0 App & Tool Catalog") ${z0r0_catalog_cheatsheet}/bin/z0r0-catalog-cheatsheet ;;
            "🐚 Nushell")           ${nushell_cheatsheet}/bin/nushell-cheatsheet ;;
            "⚡ Zellij (Legacy / Migration)") ${zellij_cheatsheet}/bin/zellij-cheatsheet ;;
            "📝 Neovim")            ${nvim_cheatsheet}/bin/nvim-cheatsheet ;;
            "✦ Helix")             ${helix_cheatsheet}/bin/helix-cheatsheet ;;
            "📂 Yazi")             ${yazi_cheatsheet}/bin/yazi-cheatsheet ;;
            "🐚 Zsh / Ghostty")    ${zsh_cheatsheet}/bin/zsh-cheatsheet ;;
            "🔍 Fzf / TV / Ripgrep") ${fzf_cheatsheet}/bin/fzf-cheatsheet ;;
            "🔧 Grep / Sed / Awk") ${grep_sed_awk_cheatsheet}/bin/grep-sed-awk-cheatsheet ;;
            "🐳 Docker / Podman")  ${docker_cheatsheet}/bin/docker-cheatsheet ;;
            "💻 VMs / MicroVMs")   ${vm_cheatsheet}/bin/vm-cheatsheet ;;
            "🚀 CLI Power Tools")  ${cli_power_cheatsheet}/bin/cli-power-cheatsheet ;;
            "🖥️ Hyprland")         hypr-keybind-cheatsheet 2>/dev/null || echo "Hyprland cheatsheet not yet ported — see Hyprland wiki" | rofi_with_theme -dmenu -p "Hyprland" ;;
            "🤖 OpenCode")          ${opencode_cheatsheet}/bin/opencode-cheatsheet ;;
            "🧠 Hermes Agent")      ${hermes_cheatsheet}/bin/hermes-cheatsheet ;;
            "📋 Shell Aliases")     ${aliases_cheatsheet}/bin/aliases-cheatsheet ;;
            "⚡ Carapace")          ${carapace_cheatsheet}/bin/carapace-cheatsheet ;;
            "🛠️ CLI Tools")       ${cli_tools_cheatsheet}/bin/cli-tools-cheatsheet ;;
            "🏷️ Tag Groups")      ${tag_groups_cheatsheet}/bin/tag-groups-cheatsheet ;;
          esac
        done
  '';

  zellij_cheatsheet = pkgs.writeShellScriptBin "zellij-cheatsheet" ''
        CHEATSHEET="
    ⚡ ZELLIJ KEYBINDS
    ═══════════════════════════════════════════

    🎯 NORMAL MODE
    ─────────────────────────────────────────
    Ctrl + G                    Lock / Unlock Interface
    🖱  Mouse                    Scroll, Select panes, Resize
    Ctrl + Q                    Quit Zellij

    📦 PANE MODE  (Ctrl + P)
    ─────────────────────────────────────────
    H / J / K / L               Move Focus (vim keys)
    N                           New Pane
    X / D                       Close Pane
    F                           Toggle Fullscreen
    \\                           Horizontal Split
    -                           Vertical Split
    Z                           Toggle Pane Frames

    📑 TAB MODE  (Ctrl + T)
    ─────────────────────────────────────────
    N                           New Tab
    X                           Close Tab
    H / L / 1-9                 Switch Tabs
    [ / ]                       Prev / Next Tab

    📏 RESIZE MODE  (Ctrl + N)
    ─────────────────────────────────────────
    H / J / K / L               Resize (vim keys)
    + / -                       Increase / Decrease

    📜 SCROLL MODE  (Ctrl + S)
    ─────────────────────────────────────────
    J / K / D / U               Scroll
    PgUp / PgDn                 Page
    Y                           Copy Selection
    Esc / q                     Exit Scroll Mode

    🔧 SESSION MODE  (Ctrl + O)
    ─────────────────────────────────────────
    D                           Detach Session
    W                           Toggle between sessions

    🎨 YAZELIX INTEGRATION
    ─────────────────────────────────────────
    Alt + Y                     Toggle Yazi Sidebar
    Alt + G                     Toggle Yazi Popup
    Ctrl + Shift + P            OpenCode Command Palette

    📊 BAR WIDGETS
    ─────────────────────────────────────────
    Top Bar:    Session · Mode · Tabs · Git · Hostname · DateTime
    Bottom Bar: CPU Usage · RAM Usage

    🖱  MOUSE
    ─────────────────────────────────────────
    Scroll                      Scroll in panes & logs
    Drag edges                  Resize panes

    🌐 PERSISTENT WEBSHELL (LAN/TS)
    ─────────────────────────────────────────
    zellij -s webshell          Create named session
    zellij ls                   List active sessions
    zellij attach webshell      Reattach to session
    ssh z0r0 -t zellij a web    Attach via LAN/Tailscale
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Zellij Keybinds"
  '';

  nvim_cheatsheet = pkgs.writeShellScriptBin "nvim-cheatsheet" ''
        CHEATSHEET="
    📝 NEOVIM KEYBINDS
    ─────────────────────────────────────────
    LEADER (Space)

    🔍 NAVIGATION
    ─────────────────────────────────────────
    Space + f                  Find Files (Telescope)
    Space + /                  Live Grep
    Space + b                  Buffer List
    Space + h                  Help Tags
    Ctrl + h/j/k/l             Navigate Splits
    [ + b / ] + b              Prev/Next Buffer

    🛠️ EDITING
    ─────────────────────────────────────────
    g + d                      Go to Definition
    g + r                      Find References
    Space + w                  Save File
    Space + q                  Quit
    Space + e                  File Explorer (nvim-tree)
    Space + g                  Git Status (lazygit)

    🎨 SELECTION & VISUAL
    ─────────────────────────────────────────
    v                          Visual Mode
    V                          Line Visual
    Ctrl + v                   Block Visual
    y                          Yank
    d                          Delete
    p / P                      Paste after/before

    💡 WHICH-KEY
    ─────────────────────────────────────────
    Space (hold)               Show keybind menu
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Neovim Keybinds"
  '';

  yazi_cheatsheet = pkgs.writeShellScriptBin "yazi-cheatsheet" ''
        CHEATSHEET="
    📂 YAZI KEYBINDS
    ─────────────────────────────────────────

    🔍 NAVIGATION
    ─────────────────────────────────────────
    h / l                     Go to Parent / Enter Dir
    j / k                     Move Down / Up
    g + g / G                 Go to Top / Bottom
    /                         Search Files
    n / N                     Next / Prev Match

    🛠️ FILE OPERATIONS
    ─────────────────────────────────────────
    y                         Yank (Copy)
    p                         Paste
    d                         Cut
    a                         Rename
    Space                     Select / Toggle
    X                         Delete

    📋 MISC
    ─────────────────────────────────────────
    ~                         Go to Home
    t                         Go to Trash
    .                         Toggle Hidden
    z                         Filter by Type
    o                         Open with
    :                         Shell Command
    ?                         Help
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Yazi Keybinds"
  '';

  helix_cheatsheet = pkgs.writeShellScriptBin "helix-cheatsheet" ''
        CHEATSHEET="
    ✦ HELIX KEYBINDS
    ─────────────────────────────────────────

    ⚡ MODES
    ─────────────────────────────────────────
    Esc / Ctrl + C           Normal Mode
    i / a                    Insert / Append
    v / V / Ctrl + v         Select / Line / Block
    :                        Command Mode
    Space                    Space Mode

    🚀 NORMAL MODE
    ─────────────────────────────────────────
    h / j / k / l            Move Cursor
    w / b                    Next / Prev Word
    x                        Select (extend)
    y                        Yank
    p / P                    Paste After / Before
    d                        Delete
    c                        Change
    u / Ctrl + r             Undo / Redo
    /                        Search
    n / N                    Next / Prev Match

    🌌 SPACE MODE
    ─────────────────────────────────────────
    Space + f                File Picker
    Space + /                Global Search
    Space + g                Git
    Space + w                Save
    Space + q                Close
    Space + k                Show Keybinds (helix default)
    Space + ?                LSP Diagnostics
    Space + R                Rename Symbol

    🔧 SELECTION MODE (v)
    ─────────────────────────────────────────
    h/j/k/l                 Extend selection
    i + w                   Inside word
    a + w                   Around word
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Helix Keybinds"
  '';

  zsh_cheatsheet = pkgs.writeShellScriptBin "zsh-cheatsheet" ''
        CHEATSHEET="
    🐚 ZSH KEYBINDS & GLOBALS
    ─────────────────────────────────────────

    ⌨️ LINE EDITING
    ─────────────────────────────────────────
    Ctrl + a/e              Beginning/End of line
    Ctrl + u/k              Cut to start/end of line
    Ctrl + w                Cut previous word
    Alt + d                 Cut next word
    Ctrl + y                Paste cut text
    Ctrl + l                Clear screen
    Alt + b/f               Back/forward one word
    Ctrl + x + e            Edit line in \$EDITOR

    📜 HISTORY
    ─────────────────────────────────────────
    Ctrl + r                Reverse history search
    Ctrl + s                Forward history search (if enabled)
    !!                      Repeat last command
    !\$                      Last arg of last command
    !:0                     Last command name
    !?string                Repeat last cmd containing string
    history | grep pat      Search history
    fc -l                   List recent history

    🔧 EXPANSIONS & GLOBALS
    ─────────────────────────────────────────
    echo ~-                 Previous directory
    echo ~+                 Current directory
    {1..10}                 Brace expansion
    **/*.js                 Recursive glob (zsh)
    *.{jpg,png}             Multiple extensions
    <1-100>                 Numeric range glob
    !pattern                Negate glob
    ls *(.)                 Files only
    ls *(/)                 Directories only
    ls *(@)                 Symlinks only
    ls *(m0)                Modified today
    ls *(Lk+1m)             Larger than 1MB

    🛠️ JOB CONTROL
    ─────────────────────────────────────────
    Ctrl + z                Suspend foreground process
    fg                      Resume suspended job
    bg                      Run suspended job in bg
    jobs                    List jobs
    disown                  Remove job from shell
    nohup cmd &             Run immune to hup

    💡 ZSH MODIFIERS
    ─────────────────────────────────────────
    :r               Remove extension
    :e               Extension only
    :h               Head (dirname)
    :t               Tail (basename)
    :s/old/new       Substitute
    :u               Uppercase
    :l               Lowercase

    🪟 GHOSTTY TERMINAL
    ─────────────────────────────────────────
    Ctrl + Shift + c        Copy
    Ctrl + Shift + v        Paste
    Ctrl + Shift + =/-      Zoom in/out
    Ctrl + Shift + 0        Reset zoom
    Ctrl + Shift + t        New tab
    Ctrl + Shift + w        Close tab
    Ctrl + Tab / Shift      Next/prev tab
    Ctrl + Shift + l        Toggle ligatures
    Ctrl + Shift + f        Fullscreen
    Ctrl + Shift + up/dn    Scroll page up/down
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Zsh / Ghostty"
  '';

  fzf_cheatsheet = pkgs.writeShellScriptBin "fzf-cheatsheet" ''
        CHEATSHEET="
    🔍 FZF & TELEVISION
    ─────────────────────────────────────────

    🔎 FZF (FUZZY FINDER)
    ─────────────────────────────────────────
    Ctrl + t                Insert selected path
    Ctrl + r                Reverse search history
    Alt + c                 cd into selected dir
    Enter                   Select / Open
    Tab / Shift + Tab       Multi-select
    Ctrl + /                Toggle preview pane
    Ctrl + f/b              Page down/up
    Ctrl + u/d              Half page down/up
    Alt + j/k               Scroll preview down/up
    fzf --preview 'cmd {}'  Preview file content
    fzf --multi             Enable multi-select
    fzf -q 'query'          Start with query
    fzf --filter 'pat'      Non-interactive filter
    fzf --height 40%        Dropdown (not fullscreen)

    📺 TELEVISION (tv)
    ─────────────────────────────────────────
    tv                      Open in current dir
    tv /path                Open in specific dir
    Enter                   Open selection
    Tab                     Multi-select
    Ctrl + /                Toggle preview
    Ctrl + f/b              Page down/up
    Ctrl + u/d              Half page down/up
    Ctrl + r                Reverse sort
    Ctrl + s                Save selection
    Esc / Ctrl + c          Exit

    🐾 RIPGREP (rg) — faster grep
    ─────────────────────────────────────────
    rg pattern              Recursive search
    rg -i pattern           Case-insensitive
    rg -l pattern           List files only
    rg -g '*.js' pattern    Filter by filetype
    rg -C3 pattern          Context lines
    rg -o pattern           Only matching text
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Fzf / TV / Ripgrep"
  '';

  grep_sed_awk_cheatsheet = pkgs.writeShellScriptBin "grep-sed-awk-cheatsheet" ''
        CHEATSHEET="
    🔧 GREP / SED / AWK
    ─────────────────────────────────────────

    🔎 GREP
    ─────────────────────────────────────────
    grep pattern file       Basic search
    grep -ri pattern dir    Recursive + case-insensitive
    grep -l pattern *       List filenames only
    grep -c pattern file    Count matches
    grep -v pattern file    Invert match (exclude)
    grep -w pattern file    Whole word match
    grep -C3 pattern file   3 lines context
    grep -E 'a|b' file     Extended regex (OR)
    grep -o pattern file    Only matching text
    rg pattern              ripgrep (faster, respects .gitignore)

    📝 SED
    ─────────────────────────────────────────
    sed 's/old/new/' f      Replace first per line
    sed 's/old/new/g' f     Replace all (global)
    sed -i 's/old/new/g' f  In-place edit
    sed 's/old/new/gI' f    Case-insensitive replace
    sed '/pat/d' f          Delete matching lines
    sed '5,10d' f           Delete line range
    sed -n '10,20p' f       Print lines 10-20
    sed 's/^/pre/' f        Prefix each line
    sed 's/\$/suf/' f        Suffix each line
    sed 's/ *\$//' f         Trim trailing whitespace
    sed 's/  */ /g' f       Collapse spaces
    sed -n '/pat/,/end/p' f Print between two patterns

    📊 AWK
    ─────────────────────────────────────────
    awk '{print \\\$1}' f       Print first column
    awk '{print \\\$NF}' f      Print last column
    awk '\\\$3 > 10' f           Filter column > 10
    awk '{sum+=\\\$1} END{print sum}' f  Sum column
    awk 'NR>1' f              Skip header row
    awk -F, '{print \\\$1}' f    CSV: print first field
    awk '!seen[\\\$0]++' f       Deduplicate lines
    awk 'length>80' f         Lines longer than 80
    awk '{print \\\$1, \\\$2}' f    Print multiple columns
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Grep / Sed / Awk"
  '';

  cli_power_cheatsheet = pkgs.writeShellScriptBin "cli-power-cheatsheet" ''
        CHEATSHEET="
    🚀 CLI POWER TOOLS
    ─────────────────────────────────────────

    📦 JSON (jq)
    ─────────────────────────────────────────
    jq '.key' file.json         Extract key
    jq '.[] | .name' json       Extract from array
    jq -r '.key' json           Raw output (no quotes)
    jq '. | select(.x > 5)'     Filter objects
    jq 'group_by(.k) | length'  Count per group
    jq -s 'add' *.json          Merge arrays

    🌐 HTTP (curl)
    ─────────────────────────────────────────
    curl -s URL                 Silent GET
    curl -o file URL            Download to file
    curl -L URL                 Follow redirects
    curl -H 'K: v' URL          Custom header
    curl -d 'data' URL          POST request
    curl -X PUT URL             Custom method
    curl 'http://a' -H '...'    Full control

    🔁 STREAM PROCESSING
    ─────────────────────────────────────────
    xargs -I{} cmd {}           Substitute stdin
    xargs -n1                   One arg at a time
    xargs -P4                   Parallel (4 procs)
    parallel cmd ::: a b c      GNU Parallel

    📂 FILES & ARCHIVES
    ─────────────────────────────────────────
    tar -xzf file.tar.gz        Extract .tar.gz
    tar -czf out.tgz dir/       Create .tar.gz
    tar -xf file.tar            Extract .tar
    unzip file.zip              Extract .zip
    zip -r out.zip dir/         Create .zip
    rsync -av src/ dst/         Sync directories
    rsync -avz src/ host:dst    Remote sync

    💾 DISK & MEMORY
    ─────────────────────────────────────────
    du -sh dir/                 Directory total size
    du -h --max-depth=1 .       Per-subdir breakdown
    df -h                       Disk free space
    free -h                     Memory usage
    lsblk                       Block devices
    mount | column -t           Mounted filesystems

    ⚡ PROCESSES
    ─────────────────────────────────────────
    ps auxf                    Full process tree
    pstree                     Tree view
    top / htop                 Interactive monitor
    kill -9 PID                Force kill
    kill -15 PID               Graceful kill
    pgrep pattern              Find PID by name
    pkill pattern              Kill by name
    lsof -i :PORT              What's listening on port

    🔧 SYSTEM
    ─────────────────────────────────────────
    ss -tulpn                  Listening ports
    systemctl status svc       Service status
    journalctl -fu svc         Follow service logs
    dmesg -w                   Kernel log follow
    uptime                     System uptime
    hostnamectl                System info

    📋 COMPARE & DIFF
    ─────────────────────────────────────────
    diff -u file1 file2        Unified diff
    diff -r dir1 dir2          Recursive diff
    colordiff file1 file2      Colorized diff
    git diff --no-index a b    Git-based diff
    cmp -l file1 file2         Byte-by-byte comparison
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "CLI Power Tools"
  '';

  docker_cheatsheet = pkgs.writeShellScriptBin "docker-cheatsheet" ''
        CHEATSHEET="
    🐳 DOCKER / PODMAN
    ─────────────────────────────────────────

    🛠️ CONTAINER LIFECYCLE
    ─────────────────────────────────────────
    docker run -it image cmd     Run interactive
    docker run -d --name n image  Run detached
    docker run --rm image         Auto-remove on exit
    docker run -p 8080:80 image   Port forward
    docker run -v /host:/ctr img  Mount volume
    docker start/stop/restart id  Lifecycle
    docker rm / kill cont         Remove / kill
    docker ps / ps -a             List running / all
    docker logs -f cont           Follow logs
    docker exec -it cont bash     Shell into container

    📦 IMAGES
    ─────────────────────────────────────────
    docker pull image:tag         Pull image
    docker build -t name .        Build from Dockerfile
    docker images                 List images
    docker rmi image              Remove image
    docker prune                  Clean unused
    docker tag src tgt            Tag image
    docker push repo/img:tag      Push to registry

    🔧 DOCKERFILE
    ─────────────────────────────────────────
    FROM node:20-alpine           Base image
    COPY . /app                   Copy files
    RUN npm install               Build step
    CMD [\"node\", \"app.js\"]      Default command
    ENTRYPOINT [\"npm\"]            Fixed entrypoint
    EXPOSE 8080                   Document port
    WORKDIR /app                  Working directory
    ENV NODE_ENV=prod             Environment vars
    HEALTHCHECK CMD curl ...      Health check

    🔄 DOCKER COMPOSE
    ─────────────────────────────────────────
    docker compose up -d          Start all services
    docker compose down           Stop all
    docker compose logs -f        Follow all logs
    docker compose ps             List services
    docker compose exec svc bash  Shell into service
    docker compose build          Rebuild services
    docker compose pull           Pull all images

    🔁 PODMAN (drop-in for Docker)
    ─────────────────────────────────────────
    podman run/pull/build ...     Same commands as docker
    podman machine init           Init VM (macOS/Windows)
    podman machine start          Start podman VM
    podman compose up -d          Compose works too
    alias docker=podman           Use podman everywhere

    🪶 DISTROBOX (podman-based)
    ─────────────────────────────────────────
    distrobox create --name ubuntu --image ubuntu:24.04
    distrobox enter ubuntu        Enter container
    distrobox list                List containers
    distrobox stop / rm ubuntu    Stop / remove
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "Docker / Podman"
  '';

  vm_cheatsheet = pkgs.writeShellScriptBin "vm-cheatsheet" ''
        CHEATSHEET="
    💻 VMs / MicroVMs / CONTAINERS
    ─────────────────────────────────────────

    🏗️ NIXOS CONTAINERS (native systemd)
    ─────────────────────────────────────────
    containers.NAME = {
      autoStart = true;
      config = { ... };       # NixOS config
      privateNetwork = true;  # Separate net ns
      hostAddress = \"10.0.1.1\";  # Host-facing IP
      localAddress = \"10.0.1.2\"; # Container IP
    };

    Manage:
    → nixos-rebuild switch     Apply container config
    → machinectl list          List all containers
    → machinectl shell NAME    Enter container shell
    → machinectl poweroff NAME  Stop container
    → journalctl -u container-NAME  Logs

    ⚡ MICROVMS (spectrum/microvm.nix)
    ─────────────────────────────────────────
    { ... }: {
      imports = [ microvm.nix ];
      microvm = {
        enable = true;
        hypervisor = \"cloud-hypervisor\"; # or qemu
        vcpu = 2;
        mem = 2048;
        interfaces = [{
          type = \"tap\";
          id = \"vm0\";
          mac = \"02:00:00:01:01:01\";
        }];
        shares = [{
          source = \"/persist/data\";
          mountPoint = \"/data\";
        }];
      };
    }

    Manage:
    → microvm-run               Boot the microvm
    → microvm-ssh               SSH in
    → systemctl restart mvm-NAME NixOS restart

    🖥️ QEMU/KVM VMs (libvirt)
    ─────────────────────────────────────────
    virsh list --all            List VMs
    virsh start NAME            Start VM
    virsh shutdown NAME         Graceful stop
    virsh destroy NAME          Force stop
    virsh edit NAME             Edit XML config
    virsh console NAME          Serial console
    virt-manager                GUI manager
    virt-viewer NAME            SPICE/VNC viewer

    📦 NIXOS CONTAINER CHEATSHEET
    ─────────────────────────────────────────
    nix-shell -p busybox        Ephemeral env
    nix shell nixpkgs#pkg       Ad-hoc shell
    nix run nixpkgs#tool        Run without install
    nix bundle pkg              Single binary bundle
    bunx / npx tool             Run JS tool (ephemeral)
    distrobox create --name x --image fedora:39
    docker run --rm -it archlinux  Ephemeral Arch
        "
        ${rofiTheme}
        echo "$CHEATSHEET" | rofi_with_theme -dmenu -p "VMs / MicroVMs / Containers"
  '';

  opencode_cheatsheet = pkgs.writeShellScriptBin "opencode-cheatsheet" ''
        ${rofiTheme}
        ${pkgs.coreutils}/bin/cat <<'CHEATSHEET_EOF' | rofi_with_theme -dmenu -p "OpenCode"
    🤖 OPENCODE — AI Coding Agent
    ─────────────────────────────────────────
    BASIC USAGE
      opencode run 'prompt'           One-shot task (no pty needed)
      opencode                        Launch interactive TUI
      opencode -c                     Continue last session
      opencode -s <id>               Resume specific session
      opencode pr 42                 Review PR #42

    ONE-SHOT EXAMPLES
      opencode run 'Add retry logic to API calls'
      opencode run 'Fix failing tests' --thinking
      opencode run 'Refactor auth' --model anthropic/claude-sonnet-4
      opencode run 'Review security' -f config.yaml -f .env.example

    INTERACTIVE TUI KEYBINDS
      Enter                          Submit message
      Tab                            Switch agents (build/plan)
      Ctrl+Shift+P                   Command palette
      Ctrl+X L                       Switch session
      Ctrl+X M                       Switch model
      Ctrl+X N                       New session
      Ctrl+C                         Exit (NOT /exit!)

    FLAGS
      --thinking                     Show model reasoning
      --variant high|minimal         Reasoning effort
      --model provider/model         Force specific model
      --format json                  Machine-readable output
      --file / -f                    Attach context files
      --title name                   Name the session
      --agent build|plan             Choose agent

    OUR SETUP (NFP)
      Plugin: oh-my-opencode-slim (z0r0)
      Config: layers/70-agents/71-coding/opencode.nix
      MCP servers: context-mode, github, himalaya, mcp-nixos

    TIPS
      Use opencode run for automation — no pty needed
      Interactive sessions need pty=true in terminal tool
      /exit opens agent selector — use Ctrl+C to quit
      Check costs: opencode stats --days 7
    CHEATSHEET_EOF
  '';

  hermes_cheatsheet = pkgs.writeShellScriptBin "hermes-cheatsheet" ''
        ${rofiTheme}
        ${pkgs.coreutils}/bin/cat <<'CHEATSHEET_EOF' | rofi_with_theme -dmenu -p "Hermes Agent"
    🧠 HERMES AGENT — Autonomous AI Worker
    ─────────────────────────────────────────
    BASIC USAGE
      hermes                         Launch TUI
      hermes setup                   First-time setup
      hermes config                  Show current config
      hermes version                 Check version

    GATEWAY (always running)
      http://127.0.0.1:8085          MCP gateway
      http://127.0.0.1:9119          Dashboard (REST API)

    PERSONALITY AND VOICE
      Default: GLaDOS (dry, sarcastic)
      TTS: glados-local (ONNX model)
      STT: Whisper (local)
      20 personalities available

    TOOLS AVAILABLE (from gateway)
      browser_*                      Camofox browser control
      terminal                       Shell commands
      file ops (read/write/patch)    File manipulation
      web_search / web_extract       Internet research
      image_generate                 FAL image generation
      text_to_speech                 GLaDOS TTS
      himalaya (MCP)                 Email (IMAP/SMTP)
      send_message                   Telegram/Discord/Signal
      delegate_task                  Spawn subagents
      cronjob                        Scheduled tasks
      memory                         Persistent memory
      skill_manage/view              Skill CRUD
      todo                           Task lists
      session_search                 Past session recall

    CREDENTIALS (via authsome)
      authsome run -- curl <url>     Auto-inject credentials
      14 connections: GitHub, Google (9), Cloudflare, Stripe
      Daemon: http://127.0.0.1:7998

    BROWSER (Camofox)
      http://127.0.0.1:9377          Browser server
      http://127.0.0.1:6080          VNC (manual start)
      Sessions persist via cookies
      Cookie import: POST /sessions/hermes/cookies

    CONFIG LOCATIONS
      ~/.hermes/config.yaml          Local CLI config
      layers/70-agents/76-hermes-agent/hermes.nix  NixOS module
      ~/.hermes/skills/              Custom skills
      ~/.hermes/profiles/            Per-profile state

    OUR STACK (NFP)
      z0r0: Laptop (i7-1260P, 16GB)
      luffy: Server (i5-9th gen, down)
      Deploy: clan machines update z0r0
      Secrets: SOPS + age keys at /persist/

    PROJECT: Streaming Liberation
      ~/Streaming_Liberation/        Book + modules
      ~/Projects/autonovel/          NousResearch pipeline
      GitHub: T0PSH31F/streaming-liberation
      Live: t0psh31f.github.io/streaming-liberation
    CHEATSHEET_EOF
  '';

  aliases_cheatsheet = pkgs.writeShellScriptBin "aliases-cheatsheet" ''
    ${rofiTheme}
    # Dynamically list all zsh aliases
    # Filter: only lines matching 'name=value' pattern (excludes ASCII art, prompts)
    ALIASES=$(zsh -ic 'alias' 2>/dev/null | \
      grep -E '^[a-zA-Z_-][a-zA-Z0-9_-]*=' | \
      sed 's/^alias //' | \
      sed "s/^\([^=]*\)='\(.*\)'$/\1 → \2/" | \
      sed 's/^\([^=]*\)="\(.*\)"$/\1 → \2/' | \
      sed 's/^\([^=]*\)=\(.*\)$/\1 → \2/' | \
      sort | \
      awk -F' → ' '{printf "  %-28s %s\n", $1, $2}')
    if [ -z "$ALIASES" ]; then
      ALIASES="  (no aliases found)"
    fi
    echo "📋 SHELL ALIASES
    ─────────────────────────────────────────
    $ALIASES" | rofi_with_theme -dmenu -p "Shell Aliases" -filter ""
  '';

  cli_tools_cheatsheet = pkgs.writeShellScriptBin "cli-tools-cheatsheet" ''
        ${rofiTheme}
        TOOLS="
    📁 FILES
      eza         Modern ls (icons, colors, tree)
      fd          Fast find replacement
      bat         Cat with syntax highlighting
      ripgrep/rg  Ultra-fast grep
      fzf         Fuzzy finder
      zoxide/z    Smart cd
      duf         Better df
      dust        Better du
      broot       Interactive tree
      trash-cli   Safer rm

    🔧 SYSTEM
      htop        Interactive process viewer
      btop        Resource monitor
      ncdu        Disk usage analyzer
      lsof        List open files
      journalctl  Systemd log viewer
      systemctl   Service manager
      loginctl    Session/login manager

    🌐 NETWORK
      curl        HTTP / API tester
      wget        File downloader
      nmap        Port scanner
      nc/netcat   TCP/UDP tool
      dig         DNS lookup
      ping        Network reachability
      mtr         Traceroute + ping
      ssh         Secure shell
      nmcli       NetworkManager CLI

    💻 DEV
      git         Version control
      gh          GitHub CLI
      nix         Package manager
      nix-shell   Temporary dev env
      home-manager Dotfile management
      just        Command runner
      lazygit     Git TUI

    🤖 AI
      ollama      Local LLM runner
      aider       AI pair programming
      opencode    AI coding agent
      hermes      AI agent (Nous)

    📦 NIX / NFP
      nixos-rebuild Build + switch
      nix flake   Flake management
      nix-collect-garbage Free space
      clan        Fleet manager
      nh          Nix helper
      nix-index   Locate by file

    📝 TEXT
      helix/hx   Modal editor
      nvim       Neovim
      sed        Stream editor
      awk        Text processing
      jq         JSON processor
      yq         YAML processor
      pandoc     Document converter

    🎨 MEDIA
      ffmpeg     Video/audio
      yt-dlp     YouTube downloader

    🎮 FUN / TOYS
      pipes.sh    Animated pipes screensaver
      asciiquarium Sea creatures swimming
      nyancat     Rainbow poptart cat
      cmatrix     Matrix-style green rain
      neo         Matrix rain (smaller)
      unimatrix   Matrix rain by a Unicorn
      cbonsai     Animated bonsai tree
      genact      Fake activity generator
      lavat       Lava lamp in your terminal
      tty-clock   Terminal clock
      cpufetch    CPU art in terminal
      sl          Steam Locomotive (typo ls)
      terminal-parrot Animated dancing parrot
      terminaltexteffects Text animation engine
      terminal-toys All-in-one screensaver
      figlet      ASCII art text banners
      toilet      Fancy ASCII text (more fonts)
      banner      Large banner text
      ascii       ASCII character table
      cfonts      Colored fonts in terminal
      boxes       ASCII boxes around text
      cowsay      Talking cow (any animal)
      neo-cowsay  Cow with character files
      ponysay     My Little Pony says things
      charasay    Anime characters say things
      fortune     Random fortune cookie
      lolcat      Rainbow-colored output
      chafa       Image to terminal art
      catimg      Image to terminal (fast)
      timg        Terminal image viewer
      fastfetch   System info (neofetch alt)
      blahaj      BLÅHAJ shark in terminal
    "
        TOOL=$(echo "$TOOLS" | rofi_with_theme -dmenu -p "CLI Tool" -filter "" -i | awk '{print $1}')
        [ -z "$TOOL" ] && exit 0
        # Try tldr first, fall back to --help if no tldr page exists
        if command -v tldr > /dev/null 2>&1; then
          PAGE=$(tldr "$TOOL" 2>/dev/null)
        fi
        if [ -z "$PAGE" ] && command -v "$TOOL" > /dev/null 2>&1; then
          PAGE=$("$TOOL" --help 2>&1 | head -60)
        fi
        echo "''${PAGE:-No help available for $TOOL}" | \
          rofi_with_theme -dmenu -p "$TOOL" -filter ""
  '';

  tag_groups_cheatsheet = pkgs.writeShellScriptBin "tag-groups-cheatsheet" ''
        ${rofiTheme}
        TAGS="
    🏷️ ENABLED TAGS — z0r0
    ─────────────────────────────────────────
      workstation   Base tools, themes, network
      desktop       GUI environment (Hyprland)
      development   Dev tools (git, nix, editors)
      gaming        Steam, Lutris, emulators
      laptop        Power management, backlight
      media         Jellyfin, *arr stack
      ai-server     LLM backends, AI services
      ai-agent      Hermes, OpenCode, MCP
      intel-12th-gen CPU microcode, i915

    🏷️ ENABLED TAGS — luffy
    ─────────────────────────────────────────
      workstation   Base tools, themes, network
      desktop       GUI (headless + cage)
      gaming        GPU drivers (NVIDIA)
      server        Server hardening, sshd
      homelab       HA, SearXNG, Vaultwarden
      cache-server  Nix binary cache
      ai-server     AI backends + homepage
      ai-agent      Full agent stack
      development   Dev tools
      media         Media services
      intel-9th-gen CPU microcode

    🏷️ AVAILABLE TAGS (idle)
    ─────────────────────────────────────────
      gpu-compute   CUDA, ROCm, OpenCL
      media-server  Jellyfin server mode
      dev           Lightweight dev

    📊 WHAT EACH TAG ENABLES
    ─────────────────────────────────────────
      ai-agent     Hermes, OpenCode, MCP, herm, Claude Code, Gemini CLI
      ai-server    Ollama, Open WebUI, ChromaDB, SillyTavern
      workstation  Tailscale, avahi, SSH, firewall
      desktop      Hyprland, Noctalia, rofi, Wayland
      development  git, nix, helix, zellij, LSPs
      gaming       Steam, Lutris, MangoHud
      media        Jellyfin, Sonarr, Radarr, Prowlarr
      homelab      Home Assistant, SearXNG, Headscale
      server       sshd hardening, firewall
      laptop       TLP, backlight, battery
    "
        echo "$TAGS" | rofi_with_theme -dmenu -p "Tag Groups" -filter ""
  '';
  herdr_cheatsheet = pkgs.writeShellScriptBin "herdr-cheatsheet" ''
        ${rofiTheme}
        HERDR="
    🤠 HERDR AI HARNESS KEYBINDS & WORKSPACES
    ═════════════════════════════════════════════════════════════════

    🎯 PREFIX KEY
    ─────────────────────────────────────────────────────────────────
    Ctrl + b                    Master Prefix Key (Tmux Style)

    🧭 DIRECT NAVIGATION (NO PREFIX)
    ─────────────────────────────────────────────────────────────────
    Alt + h / j / k / l         Focus Pane (Left / Down / Up / Right)
    Alt + Shift + Left / Right  Switch Previous / Next Tab
    Ctrl + Shift + Left / Right Move Tab Left / Right
    Ctrl + Alt + Arrows         Direct Resize Pane

    ⌨️ PREFIX SHORTCUTS
    ─────────────────────────────────────────────────────────────────
    Ctrl + b  r                 Enter Modal Resize Mode (Esc to Exit)
    Ctrl + b  c                 Create New Tab / Workspace
    Ctrl + b  x                 Close Current Pane
    Ctrl + b  z                 Toggle Pane Zoom / Fullscreen
    Ctrl + b  d                 Detach Herdr Session

    🤖 WORKSPACE PROVISIONING & AGENTS
    ─────────────────────────────────────────────────────────────────
    herdr-setup-workspaces      Auto-create opencode, hermes & agy workspaces
    herdr workspace list        List running agent workspaces
    herdr status server         Check Herdr background daemon status
    "
        echo "$HERDR" | rofi_with_theme -dmenu -p "Herdr Keybinds" -filter ""
  '';

  z0r0_catalog_cheatsheet = pkgs.writeShellScriptBin "z0r0-catalog-cheatsheet" ''
        ${rofiTheme}
        CATALOG="
    🧰 Z0R0 COMPLETE APP & TOOL CATALOG (NFP WORKSTATION)
    ═════════════════════════════════════════════════════════════════

    🌐 INTERNET, COMMUNICATION & BROWSERS
    ─────────────────────────────────────────────────────────────────
    Zen Browser / Firefox       Primary Web Browsers (Gecko Engine)
    Brave Browser               Chromium Privacy Browser
    Camofox Browser             Anti-Detection Headless/VNC Browser Server
    Element Desktop             Matrix Encrypted Chat Client
    Discord Desktop             Community Voice & Text Chat
    Telegram Desktop            Messaging & Agent Bot Channel
    Signal Desktop              Private E2EE Messaging
    Thunderbird                 Email Client & RSS Reader
    RustDesk                    High-Performance Remote Desktop Access

    🎨 MULTIMEDIA, AUDIO & VIDEO
    ─────────────────────────────────────────────────────────────────
    Feishin                     Subsonic/Navidrome Music Streaming Client
    MPV                         Hardware-Accelerated Video Player
    VLC Media Player            Universal Media Playback
    Amberol                     Minimalist GTK Music Player
    OBS Studio                  Screen Recording & Live Streaming
    Audacity                    Multi-track Audio Editor
    Mopidy                      Background Music Server & MPD Daemon

    💻 DEVELOPMENT, EDITORS & AGENTS
    ─────────────────────────────────────────────────────────────────
    VSCode (Visual Studio Code) IDE & Extension Ecosystem
    Zed Editor                  High-Performance Rust Text Editor
    Neovim (nvim)               Extensible Lua/Vim IDE & Terminal Editor
    Helix (hx)                  Modal Post-Modern Terminal Editor
    Ghostty / Kitty / Alacritty GPU-Accelerated Terminal Emulators
    OpenCode & Slim Harness     AI Coding Assistant & Slim Tool Harness
    Hermes Agent                Autonomous Multi-Platform AI Agent
    Antigravity CLI (agy)       Google DeepMind Pair-Programming AI CLI
    Herdr                       Agent Terminal Workspace Manager
    DBeaver / Postman / Insomnia DB GUI Manager & API Testing Suites
    Git & LazyGit               Source Control & Terminal TUI

    🕹️ GAMING, PROTON & EMULATORS
    ─────────────────────────────────────────────────────────────────
    Steam                       PC Gaming Platform (Proton GE Enabled)
    GameMode                    Linux Performance Optimizer Daemon
    Gamescope                   Valve Micro-Compositor & Upscaler
    MangoHud                    Real-time Performance & FPS Overlay
    Lutris / Bottles            Windows Game & Wine Bottling Managers
    RetroArch                   All-in-One Multi-System Emulator
    Dolphin / PCSX2 / RPCS3     GameCube/Wii, PS2 & PS3 Emulators
    Ryubing (Switch) / Cemu     Nintendo Switch & Wii U Emulators
    AntiMicroX / Vintage Story  Gamepad Mapper & Open-World Survival Sandbox

    🛠️ SYSTEM, UTILITIES & POWER TOOLS
    ─────────────────────────────────────────────────────────────────
    Rofi                        App Launcher, Cheatsheet & Todo Picker
    Yazi / Btop                 TUI File Manager & Process System Monitor
    Eza / Zoxide / Fzf / TV     Modern ls, cd, Fuzzy Finder & TUI Viewer
    Bat / Jq / Ripgrep / Fd     Syntax Cat, JSON Parser, Search & Find
    Direnv                      Per-Directory Environment Loader
    Fastfetch / Glances         System Info & Fleet Metrics Exporter
    Restic / Sops               Encrypted Backup & Secret Management

    🧸 CLI TOYS & DESKTOP EXTRAS
    ─────────────────────────────────────────────────────────────────
    Wl_shimeji                  Wayland Animated Desktop Companion Pets
    Jerry                       Anime Streaming TUI Script (Rofi/MPV)
    Cmatrix / CBonsai / Pipes   Matrix Rain, ASCII Bonsai & Screen Saver
    Noctalia                    Material You Dynamic Color System
    "
        echo "$CATALOG" | rofi_with_theme -dmenu -p "z0r0 App Catalog" -filter ""
  '';

  nushell_cheatsheet = pkgs.writeShellScriptBin "nushell-cheatsheet" ''
        ${rofiTheme}
        NUSHELL="
    🐚 NUSHELL CHEATSHEET & COMPLETE GUIDE
    ═════════════════════════════════════════════════════════════════

    💡 CONCEPTS & STRUCTURED PIPELINES
    ─────────────────────────────────────────────────────────────────
    Pipelines vs Commands       Data streams as structured tables, not plain text
    open file.json | get key    Load structured JSON/YAML/CSV into table record
    sys | where cpu > 50        Filter structured data stream by column condition
    ls | sort-by size           Sort table rows by column
    ls | select name size       Project specific table columns
    each { |it| print $it }     Iterate structured rows
    reduce { |it, acc| ... }    Fold structured table data into accumulator

    🛠️ BUILT-IN DATA CONVERTERS & HELP
    ─────────────────────────────────────────────────────────────────
    from json / to json         Parse or serialize JSON data
    from yaml / to yaml         Parse or serialize YAML documents
    from csv / to csv           Parse or serialize CSV spreadsheets
    str contains \"pattern\"      String pattern testing inside pipeline
    split row \",\"              Split string into list stream
    help find <term>            Search Nushell built-in help documentation
    config nu                   Edit main Nushell config
    config env                  Edit Nushell environment variables

     NFP FLEET & CLAN ALIASES
    ─────────────────────────────────────────────────────────────────
    cuw <machine>               clan-update-watch wrapper script
    cupdate                     clan machines update
    cbuild                      clan machines build
    nfp                         clan CLI gateway
    "
        echo "$NUSHELL" | rofi_with_theme -dmenu -p "Nushell Guide" -filter ""
  '';

  carapace_cheatsheet = pkgs.writeShellScriptBin "carapace-cheatsheet" ''
        ${rofiTheme}
        CARAPACE="
    ⚡ CARAPACE COMPLETION ENGINE
    ═══════════════════════════════════════════

    💡 CONCEPTS
    ─────────────────────────────────────────
    Engine                      Multi-shell polyglot completion generator
    Bridging                    Reuses zsh/bash/fish completion specs transparently
    Composition                 Composes seamlessly with Nushell native completions

    🛠️ COMMANDS & USAGE
    ─────────────────────────────────────────
    carapace --list             List registered command completion specs
    carapace <cmd> nushell      Generate Nushell completion code
    carapace <cmd> zsh          Generate Zsh completion code
    "
        echo "$CARAPACE" | rofi_with_theme -dmenu -p "Carapace Guide" -filter ""
  '';

in
{
  environment.systemPackages = [
    cheatsheet_picker
    herdr_cheatsheet
    z0r0_catalog_cheatsheet
    zellij_cheatsheet
    nvim_cheatsheet
    yazi_cheatsheet
    helix_cheatsheet
    zsh_cheatsheet
    fzf_cheatsheet
    grep_sed_awk_cheatsheet
    docker_cheatsheet
    vm_cheatsheet
    cli_power_cheatsheet
    opencode_cheatsheet
    hermes_cheatsheet
    aliases_cheatsheet
    nushell_cheatsheet
    carapace_cheatsheet
    cli_tools_cheatsheet
    tag_groups_cheatsheet
  ];
}
