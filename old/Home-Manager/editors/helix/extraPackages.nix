{ pkgs, ... }:

# Binaries for all the Language Servers, Linters and Formatters
with pkgs; [
  lldb
  clang-tools

  # Toml
  taplo

  # Yaml
  yaml-language-server

  # Nix
  nixd
  nil
  nixfmt

  # Lua
  stylua
  lua-language-server

  # Python
  ruff
  ty

  # Bash / Shell
  bash-language-server
  shfmt

  # Docker
  dockerfile-language-server
  dockfmt
  docker-compose-language-service

  emmet-ls
  typescript-language-server
  tailwindcss-language-server
  svelte-language-server
  prettier

  # PostgreSQL
  pgformatter

  # Markdown
  markdown-oxide
]
