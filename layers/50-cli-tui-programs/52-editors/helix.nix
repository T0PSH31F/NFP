{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.layers.layer-50.cli;
in
{
  home = lib.mkIf cfg.enable {
    programs.helix = {
      enable = true;
      defaultEditor = false;
      settings = {
        theme = lib.mkIf cfg.theming.enable "matugen";
        editor = {
          completion-trigger-len = 1;
          true-color = true;
          rulers = [
            80
            120
          ];
          end-of-line-diagnostics = "hint";
          inline-diagnostics = {
            cursor-line = "warning";
            other-lines = "hint";
          };
          auto-save = {
            focus-lost = true;
            after-delay = {
              enable = true;
              timeout = 500;
            };
          };
          bufferline = "multiple";
          color-modes = true;
          line-number = "absolute";
          indent-guides = {
            render = true;
            character = "┊";
          };
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          cursorline = true;
          cursorcolumn = true;
          soft-wrap.enable = true;
          text-width = 110;
          statusline = {
            left = [
              "mode"
              "spinner"
              "version-control"
              "file-name"
              "read-only-indicator"
              "file-modification-indicator"
            ];
            center = [ ];
            right = [
              "diagnostics"
              "selections"
              "register"
              "position-percentage"
              "position"
              "file-encoding"
            ];
          };
        };

        keys = {
          normal = {
            "C-y" =
              let
                yazi = lib.getExe pkgs.yazi;
              in
              [
                ":sh rm -f /tmp/unique-file"
                ":insert-output ${yazi} %{buffer_name} --chooser-file=/tmp/unique-file"
                '':insert-output echo "\x1b[?1049h" > /dev/tty''
                ":open %sh{cat /tmp/unique-file}"
                ":redraw"
                ":set mouse false"
                ":set mouse true"
              ];
            "C-left" = ":buffer-previous";
            "C-right" = ":buffer-next";
            "C-down" = "goto_next_diag";
            "C-up" = "goto_prev_diag";
            "C-s" = ":w";
            "C-q" = ":q";
            "C-h" = ":bp";
            "C-l" = ":bn";
            "!" = "no_op";
            "ret" = "goto_word";
            backspace = {
              r.r = [
                ":sh bash -c 'file=\"%{buffer_name}\"; while [ \"$file\" != \"/\" ] && [ ! -f \"$file/Cargo.toml\" ]; do file=$(dirname \"$file\"); done; if [ -f \"$file/Cargo.toml\" ]; then cd \"$file\" && cargo run; else echo \"No Cargo.toml found\"; fi'"
              ];
              v = {
                n = "@i- [ ] ";
                d = ":insert-output ${lib.getExe' pkgs.coreutils "date"} +'## %%H:%%M:%%S'";
                D = [
                  '':insert-output echo "# $(${lib.getExe' pkgs.coreutils "date"} +'%%A, %%d %%B %%Y' | ${lib.getExe pkgs.gnused} -e 's/./\u&/')"''
                  "open_below"
                  ":insert-output ${lib.getExe' pkgs.coreutils "date"} +'## %%H:%%M:%%S'"
                ];
                r = [
                  ":insert-output vault-tasks --vault-path ./ fix"
                  ":reload"
                ];
              };
              y = ":yank-diagnostic";
            };
            x = [ "extend_line_below" ];
            X = [ "extend_line_above" ];
          };
          select = {
            x = [ "extend_line_below" ];
            X = [ "extend_line_above" ];
          };
        };
      };
      languages = {
        language = [
          {
            name = "bash";
            language-servers = [
              "bash-language-server"
              "typos"
              "wakatime"
            ];
            formatter = {
              command = "${pkgs.shfmt}/bin/shfmt";
              args = [
                "-i"
                "2"
                "-"
              ];
            };
          }
          {
            name = "c";
            language-servers = [
              "clangd"
              "typos"
              "wakatime"
            ];
            formatter = {
              command = lib.getExe' pkgs.clang-tools "clang-format";
              args = [ "-" ];
            };
          }
          {
            name = "fish";
            language-servers = [
              "fish"
              "typos"
              "wakatime"
            ];
          }
          {
            name = "java";
            language-servers = [
              "jdtls"
              "typos"
              "wakatime"
            ];
            auto-format = true;
          }
          {
            name = "javascript";
            language-servers = [
              "typescript-language-server"
              "typos"
              "wakatime"
            ];
            auto-format = true;
          }
          {
            name = "markdown";
            language-servers = [
              "ltex-ls"
              "markdown-oxide"
              "typos"
              "wakatime"
            ];
            formatter = {
              command = lib.getExe pkgs.prettier;
              args = [
                "--stdin-filepath"
                "file.md"
              ];
            };
            auto-format = true;
          }
          {
            name = "nix";
            language-servers = [
              "nixd"
              "typos"
              "wakatime"
            ];
            formatter.command = lib.getExe pkgs.nixfmt;
            auto-format = true;
          }
          {
            name = "hyprland";
            scope = "source.hyprland";
            file-types = [
              "hl"
              "hypr"
              "hyprland.conf"
            ];
            language-servers = [
              "hyprls"
              "typos"
              "wakatime"
            ];
          }
          {
            name = "ocaml";
            file-types = [
              "ml"
              "mli"
            ];
            language-servers = [
              "ocaml-lsp"
              "typos"
              "wakatime"
            ];
            formatter = {
              command = lib.getExe pkgs.ocamlPackages.ocamlformat;
              args = [
                "-"
                "--impl"
                "--enable-outside-detected-project"
              ];
            };
            auto-format = true;
          }
          {
            name = "python";
            auto-format = true;
            formatter = {
              command = "ruff";
              args = [
                "format"
                "--line-length=80"
                "-"
              ];
            };
            language-servers = [
              "ty"
              "basedpyright"
              "ruff"
            ];
          }
          {
            name = "rust";
            language-servers = [
              "rust-analyzer"
              "typos"
              "wakatime"
            ];
          }
          {
            name = "toml";
            language-servers = [
              "taplo"
              "typos"
              "wakatime"
            ];
          }
          {
            name = "typst";
            language-servers = [
              "tinymist"
              "typos"
              "wakatime"
            ];
            formatter.command = lib.getExe pkgs.typstyle;
            auto-format = true;
          }
        ];

        language-server = {
          basedpyright = {
            command = lib.getExe' pkgs.basedpyright "basedpyright-langserver";
            config.python.analysis.typeCheckingMode = "basic";
          };
          ruff.command = lib.getExe pkgs.ruff;
          ty.command = lib.getExe pkgs.ty;
          bash-language-server = {
            command = lib.getExe pkgs.bash-language-server;
            args = [ "start" ];
          };
          jdtls = {
            command = "${pkgs.jdt-language-server}/bin/${
              if lib.versionOlder pkgs.jdt-language-server.version "1.31.0" then
                "jdt-language-server"
              else
                "jdtls"
            }";
            args = [ "--jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar" ];
          };
          ltex-ls = {
            command = lib.getExe' pkgs.ltex-ls "ltex-ls";
            config.ltex = {
              disabledRules.en = [ "ARROWS" ];
              disabledRules.fr = [ "FLECHES" ];
              additionnalRules.enablePickyRules = true;
              language = "auto";
            };
          };
          markdown-oxide.command = lib.getExe pkgs.markdown-oxide;
          nixd = {
            command = lib.getExe pkgs.nixd;
            config = {
              nixpkgs.expr = "import <nixpkgs> { }";
              options.nixos.expr = ''(builtins.getFlake "/home/t0psh31f/Clan/NFP/").nixosConfigurations.z0r0.options'';
            };
          };
          hyprls.command = lib.getExe' pkgs.hyprls "hyprls";
          clangd = {
            command = lib.getExe' pkgs.clang-tools "clangd";
            config.clangd.fallbackFlags = [ "-std=c++20" ];
          };
          ocaml-lsp.command = lib.getExe pkgs.ocamlPackages.ocaml-lsp;
          # Use default python3 package set (tracks nixpkgs' cached interpreter).
          # Pinning python312Packages forces an entire uncached py3.12 tree
          # (scipy source build + 39min test suite that fails on a 2e-09
          # floating-point tolerance — see 2026-08-07 progress log).
          python-lsp.command = lib.getExe pkgs.python3Packages.python-lsp-server;
          rust-analyzer = {
            command = lib.getExe pkgs.rust-analyzer;
            config.check = {
              checkOnSave = true;
              command = "clippy";
              extraArgs = [
                "--"
                "-W"
                "clippy::perf"
                "-W"
                "clippy::pedantic"
                "-A"
                "clippy::pedantic::missing_errors_doc"
                "-A"
                "clippy::needless_pass_by_value"
              ];
            };
          };
          taplo.command = lib.getExe pkgs.taplo;
          tinymist = {
            command = lib.getExe pkgs.tinymist;
            config.exportPdf = "onType";
          };
          typescript-language-server.command = lib.getExe pkgs.typescript-language-server;
          typos = {
            command = lib.getExe pkgs.typos-lsp;
            config.config = pkgs.writeText "typos.toml" ''
              [default.extend-identifiers]
              ratatui = "ratatui"
            '';
          };
          wakatime.command =
            lib.getExe
              inputs.wakatime-lsp.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
      };
    };
  };
}
