{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.layers.layer-50.cli.nixvim;
in
{
  options.layers.layer-50.cli.nixvim = {
    enable = lib.mkEnableOption "NixVim — declarative Neovim" // {
      default = true;
    };

    plugins = {
      blink-cmp = lib.mkEnableOption "blink.cmp completion engine" // {
        default = true;
      };
      neo-tree = lib.mkEnableOption "Neo-tree file explorer" // {
        default = true;
      };
      telescope = lib.mkEnableOption "Telescope fuzzy finder" // {
        default = true;
      };
      noice = lib.mkEnableOption "Noice command line UI" // {
        default = true;
      };
      neoscroll = lib.mkEnableOption "Neoscroll smooth scrolling animations" // {
        default = true;
      };
      smear-cursor = lib.mkEnableOption "Smear-cursor trailing effect" // {
        default = true;
      };
      lazygit = lib.mkEnableOption "LazyGit integration" // {
        default = true;
      };
      trouble = lib.mkEnableOption "Trouble diagnostics list" // {
        default = true;
      };
      which-key = lib.mkEnableOption "Which-key keybinding help" // {
        default = true;
      };
      opencode = lib.mkEnableOption "OpenCode AI assistant (Claude Code)" // {
        default = true;
      };
      ollama = lib.mkEnableOption "Ollama local LLM integration" // {
        default = true;
      };
      multicursors = lib.mkEnableOption "Multicursors.nvim — VS Code-style multi-cursor editing" // {
        default = true;
      };
    };
  };

  home = _: {
    imports = [
      inputs.nixvim.homeModules.nixvim
    ];

    config = lib.mkIf cfg.enable {
      home.sessionVariables = {
        EDITOR = lib.mkForce "nvim";
        VISUAL = lib.mkForce "nvim";
      };

      programs.nixvim = {
        enable = true;
        defaultEditor = true;
        vimAlias = false;
        viAlias = false;

        nixpkgs.source = lib.mkForce inputs.nixpkgs;
        version.enableNixpkgsReleaseCheck = false;

        # ── Core Options ────────────────────────────────────────────
        # Mouse-free foundation:
        #   relative line numbers → know row distance without counting
        #   cursorline → always see which line you're on
        #   hidden → keep buffers open without a visible window
        #   scrolloff=8 → keep context when scrolling with j/k
        #   undofile → persistent undo across sessions
        opts = {
          number = true;
          relativenumber = true;
          cursorline = true;
          hidden = true;
          scrolloff = 8;
          signcolumn = "yes";
          splitright = true;
          splitbelow = true;
          tabstop = 2;
          shiftwidth = 2;
          expandtab = true;
          wrap = false;
          undofile = true;
          updatetime = 300;
          timeoutlen = 500;
          mouse = "";
          termguicolors = true;
          clipboard = {
            providers.wl-copy.enable = true;
          };
        };

        globals.mapleader = " ";

        # ── Keymaps ─────────────────────────────────────────────────
        # h/j/k/l movement everywhere, never leave home row
        keymaps = [
          # Window navigation (matches Zellij pane movement)
          {
            mode = "n";
            key = "<C-h>";
            action = "<C-w>h";
            options.desc = "Window left";
          }
          {
            mode = "n";
            key = "<C-j>";
            action = "<C-w>j";
            options.desc = "Window down";
          }
          {
            mode = "n";
            key = "<C-k>";
            action = "<C-w>k";
            options.desc = "Window up";
          }
          {
            mode = "n";
            key = "<C-l>";
            action = "<C-w>l";
            options.desc = "Window right";
          }

          # Home row line movement
          {
            mode = "n";
            key = "H";
            action = "^";
            options.desc = "First non-whitespace";
          }
          {
            mode = "n";
            key = "L";
            action = "$";
            options.desc = "End of line";
          }

          # Clear search highlight
          {
            mode = "n";
            key = "<Esc>";
            action = "<cmd>nohlsearch<CR>";
            options.desc = "Clear search highlights";
          }

          # Keep visual selection when indenting
          {
            mode = "v";
            key = "<";
            action = "<gv";
            options.desc = "Indent left and reselect";
          }
          {
            mode = "v";
            key = ">";
            action = ">gv";
            options.desc = "Indent right and reselect";
          }

          # Move lines in visual mode
          {
            mode = "v";
            key = "J";
            action = ":m '>+1<CR>gv=gv";
            options.desc = "Move line down";
          }
          {
            mode = "v";
            key = "K";
            action = ":m '<-2<CR>gv=gv";
            options.desc = "Move line up";
          }

          # Format buffer with conform
          {
            mode = "n";
            key = "<leader>F";
            action = "<cmd>ConformFormat<CR>";
            options.desc = "Format buffer";
          }

          # Flash — jump to any visible character (/.\)
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "s";
            action.__raw = ''
              function() require("flash").jump() end
            '';
            options.desc = "Flash jump";
          }
          # Flash — jump to treesitter node
          {
            mode = [
              "n"
              "x"
              "o"
            ];
            key = "S";
            action.__raw = ''
              function() require("flash").treesitter() end
            '';
            options.desc = "Flash treesitter";
          }

          # Neo-tree — toggle file explorer sidebar
          {
            mode = "n";
            key = "<leader>e";
            action = "<cmd>Neotree toggle<CR>";
            options.desc = "Toggle file tree";
          }

          # LazyGit — open git TUI
          {
            mode = "n";
            key = "<leader>gg";
            action = "<cmd>LazyGit<CR>";
            options.desc = "Open LazyGit";
          }

          # Todo-comments — next/prev
          {
            mode = "n";
            key = "]t";
            action.__raw = ''
              function() require("todo-comments").jump_next() end
            '';
            options.desc = "Next todo comment";
          }
          {
            mode = "n";
            key = "[t";
            action.__raw = ''
              function() require("todo-comments").jump_prev() end
            '';
            options.desc = "Previous todo comment";
          }

          # Trouble — toggle diagnostics list
          {
            mode = "n";
            key = "<leader>xx";
            action = "<cmd>Trouble toggle<CR>";
            options.desc = "Toggle diagnostics list";
          }
          # Trouble — workspace diagnostics
          {
            mode = "n";
            key = "<leader>xw";
            action = "<cmd>Trouble workspace_diagnostics<CR>";
            options.desc = "Workspace diagnostics";
          }
          # Trouble — document diagnostics
          {
            mode = "n";
            key = "<leader>xd";
            action = "<cmd>Trouble document_diagnostics<CR>";
            options.desc = "Document diagnostics";
          }

          # Multi-cursor — start mode on current word or visual selection
          {
            mode = [
              "n"
              "v"
              "i"
            ];
            key = "<leader>m";
            action = "<cmd>MCstart<CR>";
            options.desc = "Start multi-cursor";
          }
          # Ctrl+Shift+Up/Down also start multi-cursor mode
          {
            mode = [
              "n"
              "v"
              "i"
            ];
            key = "<C-S-Up>";
            action = "<cmd>MCstart<CR>";
            options.desc = "Start multi-cursor";
          }
          {
            mode = [
              "n"
              "v"
              "i"
            ];
            key = "<C-S-Down>";
            action = "<cmd>MCstart<CR>";
            options.desc = "Start multi-cursor";
          }

          # Yazi — toggle file manager in-editor
          {
            mode = "n";
            key = "<leader>y";
            action.__raw = ''
              function() require("yazi").yazi() end
            '';
            options.desc = "Toggle Yazi file manager";
          }
        ];

        # ── Extra Plugins (manual / unmapped) ───────────────────────
        extraPlugins = [
          pkgs.vimPlugins.base16-nvim
        ]
        ++ lib.optional cfg.plugins.smear-cursor pkgs.vimPlugins.smear-cursor-nvim;

        # ── Plugins ─────────────────────────────────────────────────
        plugins = {
          # Telescope — fuzzy find files, grep, buffers, help.
          # The #1 plugin for mouse-free navigation.
          telescope = {
            enable = true;

            extensions.fzf-native.enable = true;

            keymaps = {
              "<leader>ff" = {
                action = "find_files";
                options.desc = "Find files";
              };
              "<leader>fg" = {
                action = "live_grep";
                options.desc = "Live grep";
              };
              "<leader>fb" = {
                action = "buffers";
                options.desc = "Find buffers";
              };
              "<leader>fh" = {
                action = "help_tags";
                options.desc = "Help tags";
              };
              "<leader>fr" = {
                action = "oldfiles";
                options.desc = "Recent files";
              };
              "<leader>f." = {
                action = "resume";
                options.desc = "Resume last picker";
              };
            };
          };

          # Neo-tree — file explorer sidebar, toggled with <leader>e
          neo-tree = lib.mkIf cfg.plugins.neo-tree {
            enable = true;

            settings = {
              close_if_last_window = true;
              popup_border_style = "rounded";
              enable_git_status = true;
              enable_diagnostics = true;

              window = {
                position = "left";
                width = 35;
                mappings."<space>" = "none";
              };

              filesystem = {
                filtered_items = {
                  hide_dotfiles = false;
                  hide_gitignored = false;
                };
                follow_current_file.enable = true;
              };
            };
            # keymap in main keymaps list
          };

          # Flash — jump to any visible character with 2 keystrokes.
          # s + two chars → teleport cursor. Essential mouse-free tool.
          flash = {
            enable = true;

            settings = {
              labels = "asdfghjklqwertyuiopzxcvbnm";
              pattern = "\\f\\f";
              highlight = {
                backdrop = true;
                matches = true;
                priority = 5000;
                groups = {
                  match = "FlashMatch";
                  current = "FlashCurrent";
                  backdrop = "FlashBackdrop";
                  label = "FlashLabel";
                };
              };
            };
          };

          # Which-key — shows available keybindings when you press <leader>
          which-key = lib.mkIf cfg.plugins.which-key {
            enable = true;

            settings.spec = [
              {
                __unkeyed-1 = "<leader>f";
                group = "  Find";
              }
              {
                __unkeyed-1 = "<leader>g";
                group = "  Git";
              }
              {
                __unkeyed-1 = "<leader>l";
                group = "  LSP";
              }
            ];
          };

          # LSP — language servers for all your languages
          lsp = {
            enable = true;

            servers = {
              nil_ls.enable = true;
              nixd.enable = true;
              # nixvim builds its own pkgs from `nixpkgs.source = inputs.nixpkgs`
              # (see above), which BYPASSES our overlays — so its default
              # typescript-language-server still carries nixpkgs' stale pnpmDeps
              # pin and aborts the whole build on a hash mismatch (cascading into
              # neovim → nixvim → home-manager → toplevel on both machines).
              # Point ts_ls at our overlaid copy, fixed in custom-packages.nix.
              ts_ls = {
                enable = true;
                package = pkgs.typescript-language-server;
              };
              eslint.enable = true;
              html.enable = true;
              cssls.enable = true;
              jsonls.enable = true;
              yamlls.enable = true;
              basedpyright.enable = true;
              ruff.enable = true;
              rust_analyzer = {
                enable = true;
                installCargo = true;
                installRustc = true;
              };
              gopls.enable = true;
              lua_ls.enable = true;
              marksman.enable = true;
              tinymist.enable = true;
            };

            onAttach = ''
              local map = vim.keymap.set
              local opts = { buffer = bufnr, silent = true }
              map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
              map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Find references" }))
              map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
              map("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
              map("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
              map("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
              map("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
            '';
          };

          # blink.cmp — modern auto-completion (Rust backend)
          blink-cmp = lib.mkIf cfg.plugins.blink-cmp {
            enable = true;

            settings = {
              completion = {
                list.selection = {
                  preselect = false;
                  auto_insert = true;
                };
                menu = {
                  border = "rounded";
                  draw.columns = [
                    { __unkeyed-1 = "label"; }
                    { __unkeyed-1 = "kind_icon"; }
                  ];
                };
                documentation.auto_show = true;
              };

              sources.default = [
                "lsp"
                "path"
                "snippets"
                "buffer"
                "markdown"
              ];

              keymap = {
                preset = "enter";
                "<Tab>" = [
                  "select_next"
                  "fallback"
                ];
                "<S-Tab>" = [
                  "select_prev"
                  "fallback"
                ];
                "<C-e>" = [ "hide" ];
                "<C-space>" = [ "show" ];
              };
            };
          };

          # LuaSnip + friendly snippets — code snippet engine
          luasnip = {
            enable = true;
            settings = {
              enable_autosnippets = true;
              store_selection_keys = "<Tab>";
            };
          };
          friendly-snippets.enable = true;

          # Treesitter — AST-based syntax highlighting and navigation
          treesitter = {
            enable = true;

            settings = {
              indent.enable = true;
              highlight.enable = true;
              incremental_selection.enable = true;
            };

            grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
              nix
              lua
              rust
              go
              python
              javascript
              typescript
              tsx
              html
              css
              json
              yaml
              toml
              markdown
              markdown-inline
              bash
              diff
              gitignore
              hcl
              dockerfile
              sql
              vim
              vimdoc
              typst
            ];
          };

          # Lualine — informative status line
          lualine = {
            enable = true;
            settings.options = {
              theme = "auto";
              component_separators = {
                left = "|";
                right = "|";
              };
              section_separators = {
                left = "";
                right = "";
              };
            };
            settings.sections = {
              lualine_a = [ "mode" ];
              lualine_b = [
                "branch"
                "diff"
                "diagnostics"
              ];
              lualine_c = [ "filename" ];
              lualine_x = [
                "filetype"
                "encoding"
              ];
              lualine_y = [ "progress" ];
              lualine_z = [ "location" ];
            };
          };

          # Bufferline — tab bar at top
          bufferline = {
            enable = true;
            settings.options = {
              numbers = "ordinal";
              close_command = "bdelete! %d";
              right_mouse_command = "bdelete! %d";
              indicator.style = "underline";
              buffer_close_icon = "×";
              modified_icon = "●";
              separator_style = "thin";
              always_show_bufferline = true;
            };
          };

          # Noice — modern command line UI
          noice = lib.mkIf cfg.plugins.noice {
            enable = true;
            settings = {
              cmdline.view = "cmdline_popup";
              messages.view = "mini";
              popupmenu.backend = "nui";
            };
          };

          # Neoscroll — smooth scrolling animations
          # Replaces jerky C-d/C-u/j/k/gg/G jumps with smooth animated scroll
          neoscroll = lib.mkIf cfg.plugins.neoscroll {
            enable = true;
            settings = {
              hide_cursor = false;
              stop_eof = true;
              respect_scrolloff = true;
              cursor_scrolls_alone = true;
              easing_function = "quadratic";
              pre_horizontal_scrolloff = 0;
            };
          };

          # Dressing — better vim.ui dialogs (telescope-style)
          dressing.enable = true;

          # Trouble — diagnostics sidebar
          trouble = lib.mkIf cfg.plugins.trouble {
            enable = true;
          };

          # Gitsigns — git signs in gutter + inline blame
          gitsigns = {
            enable = true;
            settings = {
              signs = {
                add.text = "+";
                change.text = "~";
                delete.text = "_";
                topdelete.text = "‾";
                changedelete.text = "~";
              };
              current_line_blame = true;
              current_line_blame_opts.delay = 500;
            };
          };

          # LazyGit — git GUI in a floating terminal
          lazygit = lib.mkIf cfg.plugins.lazygit {
            enable = true;
          };

          # Conform — auto-format on save
          conform-nvim = {
            enable = true;
            settings = {
              format_on_save = {
                timeout_ms = 500;
                lsp_fallback = true;
              };
              formatters_by_ft = {
                nix = [ "nixfmt" ];
                lua = [ "stylua" ];
                python = [ "ruff_format" ];
                rust = [ "rustfmt" ];
                go = [ "gofmt" ];
                javascript = [
                  "prettierd"
                  "prettier"
                ];
                typescript = [
                  "prettierd"
                  "prettier"
                ];
                html = [
                  "prettierd"
                  "prettier"
                ];
                css = [
                  "prettierd"
                  "prettier"
                ];
                json = [
                  "prettierd"
                  "prettier"
                ];
                yaml = [ "yamlfmt" ];
                markdown = [
                  "prettierd"
                  "prettier"
                ];
                "*" = [ "trim_whitespace" ];
              };
            };
          };

          # Autopairs — auto-close brackets
          nvim-autopairs.enable = true;

          # Surround — edit surround characters without mouse
          nvim-surround.enable = true;

          # Todo-comments — highlight TODO/FIXME/HACK
          todo-comments.enable = true;

          # Illuminate — auto-highlight word under cursor
          illuminate.enable = true;

          # Indent-blankline — vertical indent guides
          indent-blankline = {
            enable = true;
            settings = {
              indent = {
                char = "│";
                smart_indent_cap = true;
              };
              scope = {
                enabled = true;
                show_start = true;
                show_end = false;
              };
            };
          };

          # Rainbow-delimiters — colored bracket nesting
          rainbow-delimiters.enable = true;

          # Render-markdown — live Markdown preview
          render-markdown.enable = true;

          # Web-devicons — file-type icons everywhere
          web-devicons.enable = true;

          # Comment — easy commenting with gc
          comment.enable = true;

          # Yazi — file manager integration in-editor
          yazi.enable = true;

          # Zellij-nav — seamless Zellij/Neovim pane movement
          zellij-nav.enable = true;

          # Multicursors — VS Code-style multi-cursor editing
          # Within multicursor mode (both normal and insert):
          #   Ctrl+Shift+Up/Down    → add cursor above/below
          #   Ctrl+Shift+Left/Right → skip/subtract current cursor
          #   j/k  → add cursor below/above (defaults, also work)
          #   q    → skip current selection (default)
          #   ,    → keep only the main cursor (default)
          multicursors = lib.mkIf cfg.plugins.multicursors {
            enable = true;
            settings = {
              normal_keys = {
                "<C-S-Up>" = {
                  # method.__raw is a raw Lua function, not a nix value
                  method.__raw = ''
                    function() require("multicursors.normal_mode").add_cursor_above() end
                  '';
                  opts = {
                    desc = "Add cursor above";
                  };
                };
                "<C-S-Down>" = {
                  method.__raw = ''
                    function() require("multicursors.normal_mode").add_cursor_below() end
                  '';
                  opts = {
                    desc = "Add cursor below";
                  };
                };
                "<C-S-Left>" = {
                  method.__raw = ''
                    function() require("multicursors.normal_mode").skip() end
                  '';
                  opts = {
                    desc = "Skip/subtract cursor";
                  };
                };
                "<C-S-Right>" = {
                  method.__raw = ''
                    function() require("multicursors.normal_mode").skip() end
                  '';
                  opts = {
                    desc = "Skip/subtract cursor";
                  };
                };
              };
              insert_keys = {
                "<C-S-Up>" = {
                  method.__raw = ''
                    function() require("multicursors.normal_mode").add_cursor_above() end
                  '';
                  opts = {
                    desc = "Add cursor above";
                  };
                };
                "<C-S-Down>" = {
                  method.__raw = ''
                    function() require("multicursors.normal_mode").add_cursor_below() end
                  '';
                  opts = {
                    desc = "Add cursor below";
                  };
                };
                "<C-S-Left>" = {
                  method.__raw = ''
                    function() require("multicursors.normal_mode").skip() end
                  '';
                  opts = {
                    desc = "Skip/subtract cursor";
                  };
                };
                "<C-S-Right>" = {
                  method.__raw = ''
                    function() require("multicursors.normal_mode").skip() end
                  '';
                  opts = {
                    desc = "Skip/subtract cursor";
                  };
                };
              };
            };
          };

          # Snacks — QoL collection (required by opencode)
          snacks = lib.mkIf cfg.plugins.opencode {
            enable = true;
            settings.input.enabled = true;
          };

          # OpenCode — Claude Code AI assistant in-editor
          opencode = lib.mkIf cfg.plugins.opencode {
            enable = true;
            settings = {
              auto_reload = true;
            };
          };

          # Ollama — local LLM integration
          ollama = lib.mkIf cfg.plugins.ollama {
            enable = true;
            settings = {
              model = "llama3.2";
              url = "http://127.0.0.1:11434";
            };
          };
        };

        # ── Noctalia Theme Integration ───────────────────────────
        #
        # Noctalia generates Material You colors from wallpaper into:
        #   ~/.config/noctalia/templates/nvim-colors.lua
        #
        # This file is sourced at startup. If it doesn't exist yet
        # (e.g. first boot before Noctalia runs), falls back to tokyo-night.
        extraConfigLua = ''
          -- Smear-cursor trail effect (only if plugin loaded)
          ${lib.optionalString cfg.plugins.smear-cursor ''
            require("smear_cursor").setup({
              smear_between_neighbor_lines = true,
              stiffness = 0.9,
              trailing_length = 0.3,
            })
          ''}

          -- Noctalia theme integration
          local ok, matugen = pcall(require, "matugen")
          if ok and matugen then
            matugen.setup()
          else
            vim.cmd("colorscheme tokyo-night")
          end
        '';
      }; # programs.nixvim
    }; # config = lib.mkIf cfg.enable
  }; # home
}
