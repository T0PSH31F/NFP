{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:

let
  cfg =
    if
      (osConfig ? layers)
      && (osConfig.layers ? layer-79)
      && (osConfig.layers.layer-79 ? skills)
      && (osConfig.layers.layer-79.skills ? todo-system)
    then
      osConfig.layers.layer-79.skills.todo-system
    else
      { enable = false; };
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
  userHome = "/home/${user}";
  todoBackend = ../../70-agents/75-mcp/nfp-todo-mcp.py;
  pythonBin = "${pkgs.python3}/bin/python3";

  # Rofi multi-agent to-do launcher & quick-add popup
  rofi-todo = pkgs.writeShellScriptBin "rofi-todo" ''
    # rofi-todo — Interactive Shared Multi-Agent Todo List via Rofi
    # Keybinds:
    #   - Super+Period       : Open full interactive Todo popup (toggle, filter, or type directly to add)
    #   - Super+Shift+Period : Instant 1-line Quick-Add prompt (`rofi-todo --quick-add`)
    #
    # Canonical file: ~/Notes/EverOS/todo.md (symlinked to ~/Notes/todo.md)
    # Section tags supported when adding tasks:
    #   @erik / @me, @hermes, @pi, @opencode, @claude, @gemini, @idea

    set -euo pipefail

    TODO_FILE="''${TODO_FILE:-$HOME/Notes/EverOS/todo.md}"
    EDITOR_CMD="''${EDITOR:-nvim}"

    "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" init >/dev/null

    quick_add_prompt() {
      local default_tag="''${1:-}"
      local new_task
      new_task=$(rofi -dmenu -i -p "Quick Add (@hermes/@pi/@opencode/@me):" -filter "$default_tag" -theme-str 'window {width: 48%; listview {lines: 0;}}') || true
      if [ -n "''${new_task:-}" ]; then
        "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" --agent erik add "$new_task" >/dev/null
      fi
    }

    if [ "''${1:-}" = "--quick-add" ] || [ "''${1:-}" = "-a" ]; then
      shift
      quick_add_prompt "''${*:-}"
      exit 0
    fi

    SECTION_FILTER=""

    while true; do
      tasks_output=$("${pythonBin}" "${todoBackend}" --file "$TODO_FILE" list --rofi ''${SECTION_FILTER:+--section "$SECTION_FILTER"})

      menu_items=()
      if [ -n "$tasks_output" ]; then
        while IFS= read -r line; do
          [ -n "$line" ] && menu_items+=("$line")
        done <<< "$tasks_output"
      fi

      menu_items+=("➕ Quick Add Task (@hermes / @pi / @opencode / @me)")
      if [ -n "$SECTION_FILTER" ]; then
        menu_items+=("🔎 Show All Sections (current: $SECTION_FILTER)")
      else
        menu_items+=("🔎 Filter by Agent / Section...")
      fi
      menu_items+=("📝 Open Shared Todo in Editor")
      menu_items+=("❌ Quit")

      prompt_label="Todo (type task or @agent to add):"
      if [ -n "$SECTION_FILTER" ]; then
        prompt_label="Todo [$SECTION_FILTER]:"
      fi

      choice=$(printf '%s\n' "''${menu_items[@]}" | rofi -dmenu -i -p "$prompt_label" -theme-str 'window {width: 52%;}') || true

      [ -z "''${choice:-}" ] && exit 0

      case "$choice" in
        "➕ Quick Add Task"*)
          quick_add_prompt ""
          ;;
        "🔎 Show All Sections"*)
          SECTION_FILTER=""
          ;;
        "🔎 Filter by Agent / Section...")
          sec_choice=$(printf '%s\n' "all" "erik" "hermes" "pi" "opencode" "claude" "gemini" "ideas" | rofi -dmenu -i -p "Section:" -theme-str 'window {width: 30%;}') || true
          if [ -z "''${sec_choice:-}" ] || [ "$sec_choice" = "all" ]; then
            SECTION_FILTER=""
          else
            SECTION_FILTER="$sec_choice"
          fi
          ;;
        "📝 Open Shared Todo in Editor")
          if command -v ghostty >/dev/null 2>&1; then
            exec ghostty -e "$EDITOR_CMD" "$TODO_FILE"
          else
            exec "$EDITOR_CMD" "$TODO_FILE"
          fi
          ;;
        "❌ Quit")
          exit 0
          ;;
        "✓ ["*|"☐ ["*|"▶ ["*)
          # Extract [Section] and task description
          sec_raw=$(echo "$choice" | sed -E 's/^[✓☐▶] \[([^]]+)\].*$/\1/' | tr '[:upper:]' '[:lower:]')
          desc=$(echo "$choice" | sed -E 's/^[✓☐▶] \[[^]]+\][[:space:]]+//')
          if [ -n "$desc" ]; then
            "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" --agent erik toggle --section "$sec_raw" "$desc" >/dev/null || true
          fi
          ;;
        *)
          # User typed a brand-new task directly in the Rofi bar!
          "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" --agent erik add "$choice" >/dev/null || true
          ;;
      esac
    done
  '';

  # Hermes hook
  todo-hermes-hook = pkgs.writeShellScriptBin "todo-hermes-hook" ''
    set -euo pipefail

    TODO_FILE="''${TODO_FILE:-$HOME/Notes/EverOS/todo.md}"
    BREAKDOWN_FILE="''${BREAKDOWN_FILE:-$HOME/Notes/EverOS/todo-breakdown.md}"
    STATE_FILE="''${STATE_FILE:-$HOME/.local/share/todo-hook-state.txt}"
    LOG_FILE="''${LOG_FILE:-$HOME/.local/share/todo-hook.log}"
    LOCK_FILE="/tmp/todo-hermes-hook.lock"

    mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATE_FILE")"

    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

    exec 200>"$LOCK_FILE"
    flock -n 200 || { log "Hook already running, skipping"; exit 0; }

    "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" init >/dev/null

    if [ ! -f "$BREAKDOWN_FILE" ]; then
      printf '# Task Breakdowns\n\n' > "$BREAKDOWN_FILE"
    fi
    [ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

    open_tasks=$("${pythonBin}" "${todoBackend}" --file "$TODO_FILE" list --section erik --status open --rofi | sed -E 's/^[✓☐▶] \[[^]]+\][[:space:]]+//' || true)
    if [ -z "$open_tasks" ]; then
      exit 0
    fi

    new_tasks=()
    while IFS= read -r t; do
      [ -z "$t" ] && continue
      if ! grep -Fxq "$t" "$STATE_FILE" 2>/dev/null; then
        new_tasks+=("$t")
      fi
    done <<< "$open_tasks"

    if [ ''${#new_tasks[@]} -eq 0 ]; then
      exit 0
    fi

    for task in "''${new_tasks[@]}"; do
      echo "$task" >> "$STATE_FILE"
      if [[ "$task" =~ @hermes ]]; then
        "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" --agent hermes claim "$task" >/dev/null 2>&1 || true
      elif [[ "$task" =~ @pi ]]; then
        "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" --agent pi claim "$task" >/dev/null 2>&1 || true
      elif [[ "$task" =~ @opencode ]]; then
        "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" --agent opencode claim "$task" >/dev/null 2>&1 || true
      fi
    done
  '';

  # Morning roundup
  todo-morning-roundup = pkgs.writeShellScriptBin "todo-morning-roundup" ''
    set -euo pipefail

    TODO_FILE="''${TODO_FILE:-$HOME/Notes/EverOS/todo.md}"
    LOG_FILE="''${LOG_FILE:-$HOME/.local/share/todo-hook.log}"
    mkdir -p "$(dirname "$LOG_FILE")"

    "${pythonBin}" "${todoBackend}" --file "$TODO_FILE" init >/dev/null
    count=$("${pythonBin}" "${todoBackend}" --file "$TODO_FILE" list --status open --json | ${pkgs.jq}/bin/jq '.count')

    if [ "$count" -eq 0 ]; then
      summary="Good morning, Subject. Your shared todo queue is unexpectedly empty."
    else
      summary="Good morning, Subject. There are $count open tasks across your shared agent todo queue."
    fi

    if [ -x /home/t0psh31f/.local/bin/glados-tts-cli ]; then
      /home/t0psh31f/.local/bin/glados-tts-cli "$summary" >/dev/null 2>&1 || true
    elif command -v espeak-ng >/dev/null 2>&1; then
      espeak-ng "$summary" >/dev/null 2>&1 || true
    fi
  '';

  todoTemplate = ''
    # NFP Shared Todo List

    > Shared between Erik and NFP AI Agents. Tag tasks with `@hermes`, `@pi`, `@opencode`, `@claude`, or `@gemini`.

    ## Erik
    - [ ] Review agent progress and daily priorities

    ## Hermes

    ## Pi

    ## OpenCode

    ## Claude

    ## Gemini

    ## Ideas
  '';

in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      rofi-todo
      todo-hermes-hook
      todo-morning-roundup
    ];

    # ── Systemd user units (NixOS level) ───────────────────────────
    systemd.user = {
      paths.todo-hermes-hook = {
        description = "Hermes Shared To-Do Hook Watcher";
        pathConfig = {
          PathModified = "%h/Notes/EverOS/todo.md";
          Unit = "todo-hermes-hook.service";
        };
        wantedBy = [ "default.target" ];
      };

      services = {
        todo-hermes-hook = {
          description = "Hermes Shared To-Do Auto-Claim & Breakdown Hook";
          script = "${todo-hermes-hook}/bin/todo-hermes-hook";
          serviceConfig = {
            Type = "oneshot";
            Environment = "TODO_FILE=%h/Notes/EverOS/todo.md";
          };
        };

        todo-morning-roundup = {
          description = "To-Do Morning Roundup with GLaDOS TTS";
          script = "${todo-morning-roundup}/bin/todo-morning-roundup";
          serviceConfig = {
            Type = "oneshot";
            Environment = "TODO_FILE=%h/Notes/EverOS/todo.md";
          };
        };
      };

      timers.todo-morning-roundup = {
        description = "Daily 9:00 AM To-Do Morning Roundup";
        timerConfig = {
          OnCalendar = "09:00";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };
    };

    home-manager.users.${user} = _: {
      config = {
        xdg.dataFile."todo-template.md".text = todoTemplate;

        wayland.windowManager.hyprland = {
          enable = true;
          configType = "hyprlang";
          settings = {
            bind = [
              "$mod, period, exec, ${rofi-todo}/bin/rofi-todo"
              "$mod SHIFT, period, exec, ${rofi-todo}/bin/rofi-todo --quick-add"
            ];
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${userHome}/Notes 0755 ${user} users -"
      "d ${userHome}/Notes/EverOS 0775 ${user} users -"
    ];
  };
}
