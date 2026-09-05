{
  config,
  lib,
  pkgs,
  osConfig ? config,
  ...
}:

let
  cfg = config.layers.layer-79.skills.todo-system;
  user = osConfig.layers.meta.primaryUser or "t0psh31f";
  userHome = "/home/${user}";

  # Rofi to-do launcher
  rofi-todo = pkgs.writeShellScriptBin "rofi-todo" ''
        # rofi-todo.sh — Interactive to-do list via Rofi
        # Bound to Super+Period in Hyprland.
        #
        # Reads ~/Notes/todo.md, shows tasks in a rofi menu.
        # Actions:
        #   - Select a task to toggle completion
        #   - Type "add:" to add a new task
        #   - Type "edit" to open the file in $EDITOR
        #
        # Assumptions:
        #   - rofi is installed
        #   - todo.md exists at ~/Notes/todo.md
        #   - $EDITOR is set (defaults to nano)

        set -euo pipefail

        TODO_FILE="''${TODO_FILE:-$HOME/Notes/todo.md}"
        EDITOR="''${EDITOR:-nano}"
        LOCK_FILE="/tmp/rofi-todo.lock"

        # Prevent concurrent invocations
        exec 200>"$LOCK_FILE"
        flock -n 200 || exit 0

        # Ensure file exists
        if [ ! -f "$TODO_FILE" ]; then
          mkdir -p "$(dirname "$TODO_FILE")"
          cat > "$TODO_FILE" <<'EOF'
    # Tasks

    # Ideas

    EOF
        fi

        # Parse tasks from the Tasks section
        parse_tasks() {
          local in_tasks=0
          while IFS= read -r line; do
            if [[ "$line" =~ ^#\ *Ideas ]]; then
              in_tasks=0
              continue
            fi
            if [[ "$line" =~ ^#\ *Tasks ]]; then
              in_tasks=1
              continue
            fi
            if [[ "$in_tasks" -eq 1 ]]; then
              if [[ "$line" =~ ^-\ \[([ xX])\]\ (.+)$ ]]; then
                local status="''${BASH_REMATCH[1]}"
                local desc="''${BASH_REMATCH[2]}"
                if [[ "$status" == "x" || "$status" == "X" ]]; then
                  echo "✓ $desc"
                else
                  echo "  $desc"
                fi
              fi
            fi
          done < "$TODO_FILE"
        }

        toggle_task() {
          local desc="$1"
          local found=0
          local tmp_file=$(mktemp)

          while IFS= read -r line; do
            if [[ "$line" =~ ^-\ \[([ xX])\]\ (.+)$ ]]; then
              local status="''${BASH_REMATCH[1]}"
              local task_desc="''${BASH_REMATCH[2]}"
              if [[ "$task_desc" == "$desc" ]]; then
                found=1
                if [[ "$status" == "x" || "$status" == "X" ]]; then
                  echo "- [ ] $task_desc"
                else
                  echo "- [x] $task_desc"
                fi
              else
                echo "$line"
              fi
            else
              echo "$line"
            fi
          done < "$TODO_FILE" > "$tmp_file"

          if [ "$found" -eq 1 ]; then
            mv "$tmp_file" "$TODO_FILE"
          else
            rm -f "$tmp_file"
          fi
        }

        add_task() {
          local desc="$1"
          local tmp_file=$(mktemp)
          local in_tasks=0
          local added=0

          while IFS= read -r line; do
            if [[ "$line" =~ ^#\ *Ideas ]]; then
              if [ "$added" -eq 0 ]; then
                echo "- [ ] $desc"
                added=1
              fi
              echo "$line"
            elif [[ "$line" =~ ^#\ *Tasks ]]; then
              in_tasks=1
              echo "$line"
            else
              echo "$line"
            fi
          done < "$TODO_FILE" > "$tmp_file"

          mv "$tmp_file" "$TODO_FILE"
        }

        while true; do
          local tasks
          tasks=$(parse_tasks)

          local menu_items=()
          if [ -n "$tasks" ]; then
            while IFS= read -r t; do
              menu_items+=("$t")
            done <<< "$tasks"
          fi
          menu_items+=("➕ Add new task")
          menu_items+=("📝 Edit file")
          menu_items+=("❌ Quit")

          local choice
          choice=$(printf '%s\n' "''${menu_items[@]}" | rofi -dmenu -i -p "Todo:" -theme-str 'window {width: 40%;}')

          [ -z "$choice" ] && exit 0

          case "$choice" in
            "➕ Add new task")
              local new_task
              new_task=$(rofi -dmenu -i -p "New task:" -theme-str 'window {width: 40%;}')
              [ -n "$new_task" ] && add_task "$new_task"
              ;;
            "📝 Edit file")
              exec "$EDITOR" "$TODO_FILE"
              ;;
            "❌ Quit")
              exit 0
              ;;
            *)
              local desc
              desc=$(echo "$choice" | sed 's/^✓ //; s/^  //')
              if [ -n "$desc" ]; then
                toggle_task "$desc"
              fi
              ;;
          esac
        done
  '';

  # Hermes hook
  todo-hermes-hook = pkgs.writeShellScriptBin "todo-hermes-hook" ''
        set -euo pipefail

        TODO_FILE="''${TODO_FILE:-$HOME/Notes/todo.md}"
        BREAKDOWN_FILE="''${BREAKDOWN_FILE:-$HOME/Notes/todo-breakdown.md}"
        STATE_FILE="''${STATE_FILE:-$HOME/.local/share/todo-hook-state.txt}"
        LOG_FILE="''${LOG_FILE:-$HOME/.local/share/todo-hook.log}"
        LOCK_FILE="/tmp/todo-hermes-hook.lock"

        mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATE_FILE")"

        log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

        exec 200>"$LOCK_FILE"
        flock -n 200 || { log "Hook already running, skipping"; exit 0; }

        log "=== Hook triggered ==="

        if [ ! -f "$TODO_FILE" ]; then
          log "todo.md not found, creating template"
          mkdir -p "$(dirname "$TODO_FILE")"
          cat > "$TODO_FILE" <<'EOF'
    # Tasks

    # Ideas

    EOF
        fi

        if [ ! -f "$BREAKDOWN_FILE" ]; then
          cat > "$BREAKDOWN_FILE" <<'EOF'
    # Task Breakdowns

    EOF
        fi

        if [ ! -f "$STATE_FILE" ]; then
          touch "$STATE_FILE"
        fi

        local new_tasks=()
        local in_tasks=0
        while IFS= read -r line; do
          if [[ "$line" =~ ^#\ *Ideas ]]; then
            in_tasks=0
            continue
          fi
          if [[ "$line" =~ ^#\ *Tasks ]]; then
            in_tasks=1
            continue
          fi
          if [[ "$in_tasks" -eq 1 ]]; then
            if [[ "$line" =~ ^-\ \[([ xX])\]\ (.+)$ ]]; then
              local status="''${BASH_REMATCH[1]}"
              local desc="''${BASH_REMATCH[2]}"
              if [[ "$status" != "x" && "$status" != "X" ]]; then
                new_tasks+=("$desc")
              fi
            fi
          fi
        done < "$TODO_FILE"

        if [ ''${#new_tasks[@]} -eq 0 ]; then
          log "No new tasks to process"
          exit 0
        fi

        log "Found ''${#new_tasks[@]} new task(s) to break down"

        local task_list
        task_list=$(printf '%s\n' "''${new_tasks[@]}")

        local prompt="Break down the following tasks into smaller actionable steps with rough time estimates (in minutes). Format the output as markdown with the task as a header and steps as a nested list. Only include the breakdown, no extra commentary.

    Tasks:
    $task_list"

        log "Sending to Hermes: $prompt"

        local hermes_output
        hermes_output=$(hermes-studio cli --prompt "$prompt" 2>&1) || {
          log "ERROR: Hermes CLI failed: $hermes_output"
          exit 1
        }

        log "Hermes response received"

        {
          echo ""
          echo "## Breakdown generated: $(date '+%Y-%m-%d %H:%M:%S')"
          echo ""
          echo "$hermes_output"
          echo ""
        } >> "$BREAKDOWN_FILE"

        for task in "''${new_tasks[@]}"; do
          echo "$task" >> "$STATE_FILE"
        done

        log "Breakdown written to $BREAKDOWN_FILE"
        log "=== Hook complete ==="
  '';

  # Morning roundup
  todo-morning-roundup = pkgs.writeShellScriptBin "todo-morning-roundup" ''
    set -euo pipefail

    TODO_FILE="''${TODO_FILE:-$HOME/Notes/todo.md}"
    BREAKDOWN_FILE="''${BREAKDOWN_FILE:-$HOME/Notes/todo-breakdown.md}"
    TTS_ENGINE="''${TTS_ENGINE:-espeak}"
    LOG_FILE="''${LOG_FILE:-$HOME/.local/share/todo-hook.log}"

    mkdir -p "$(dirname "$LOG_FILE")"

    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [roundup] $*" >> "$LOG_FILE"; }

    log "=== Morning roundup started ==="

    if [ ! -f "$TODO_FILE" ]; then
      log "todo.md not found"
      echo "No tasks found." | $TTS_ENGINE 2>/dev/null || echo "No tasks found."
      exit 0
    fi

    local tasks=()
    local in_tasks=0
    while IFS= read -r line; do
      if [[ "$line" =~ ^#\ *Ideas ]]; then
        in_tasks=0
        continue
      fi
      if [[ "$line" =~ ^#\ *Tasks ]]; then
        in_tasks=1
        continue
      fi
      if [[ "$in_tasks" -eq 1 ]]; then
        if [[ "$line" =~ ^-\ \[([ xX])\]\ (.+)$ ]]; then
          local status="''${BASH_REMATCH[1]}"
          local desc="''${BASH_REMATCH[2]}"
          if [[ "$status" != "x" && "$status" != "X" ]]; then
            tasks+=("$desc")
          fi
        fi
      fi
    done < "$TODO_FILE"

    local summary="Good morning. Here is your task summary for today."
    if [ ''${#tasks[@]} -eq 0 ]; then
      summary="$summary You have no pending tasks. Enjoy your day."
    else
      summary="$summary You have ''${#tasks[@]} pending task(s)."
      local i=1
      for task in "''${tasks[@]}"; do
        summary="$summary Task $i: $task."
        ((i++))
      done
      if [ -f "$BREAKDOWN_FILE" ]; then
        local estimates
        estimates=$(grep -oP '\d+\s*minutes?' "$BREAKDOWN_FILE" 2>/dev/null | tail -5 || true)
        if [ -n "$estimates" ]; then
          summary="$summary Estimated time for recent breakdowns: $estimates."
        fi
      fi
      summary="$summary Suggested schedule: Start with your most important task, take a 5 minute break between tasks, and review progress at noon."
    fi

    log "Summary: $summary"
    if command -v "$TTS_ENGINE" &>/dev/null; then
      echo "$summary" | $TTS_ENGINE 2>>"$LOG_FILE"
      log "TTS output completed"
    else
      log "WARNING: TTS engine '$TTS_ENGINE' not found, falling back to echo"
      echo "$summary"
    fi

    log "=== Morning roundup complete ==="
  '';

  todoTemplate = ''
    # Tasks

    # Ideas

  '';

in
{
  # Option definition moved to layers/20-services/22-ai/29-todo/default.nix
  # so it is always available (including headless servers) without importing
  # 40-desktop.

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      rofi-todo
      todo-hermes-hook
      todo-morning-roundup
    ];

    # ── Systemd user units (NixOS level) ───────────────────────────
    systemd.user.paths.todo-hermes-hook = {
      description = "Hermes To-Do Hook Watcher";
      pathConfig = {
        PathModified = "%h/Notes/todo.md";
        Unit = "todo-hermes-hook.service";
      };
      wantedBy = [ "default.target" ];
    };

    systemd.user.services.todo-hermes-hook = {
      description = "Hermes To-Do Hook";
      script = "${todo-hermes-hook}/bin/todo-hermes-hook";
      serviceConfig = {
        Type = "oneshot";
        Environment = "TODO_FILE=%h/Notes/todo.md";
      };
    };

    systemd.user.timers.todo-morning-roundup = {
      description = "Daily 9:00 AM To-Do Morning Roundup";
      timerConfig = {
        OnCalendar = "09:00";
        Persistent = true;
      };
      wantedBy = [ "timers.target" ];
    };

    systemd.user.services.todo-morning-roundup = {
      description = "To-Do Morning Roundup with TTS";
      script = "${todo-morning-roundup}/bin/todo-morning-roundup";
      serviceConfig = {
        Type = "oneshot";
        Environment = "TODO_FILE=%h/Notes/todo.md";
      };
    };

    home-manager.users.${user} = { pkgs, ... }: {
      config = {
        xdg.dataFile."todo-template.md".text = todoTemplate;

        wayland.windowManager.hyprland = {
          enable = true;
          configType = "hyprlang";
          settings = {
            bind = [
              "$mod, period, exec, ${rofi-todo}/bin/rofi-todo"
            ];
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${userHome}/Notes 0755 ${user} users -"
    ];
  };
}
