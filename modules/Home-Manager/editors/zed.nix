{pkgs, ...}: {
  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;
    extensions = [
      # get the names from here : https://zed.dev/extensions
      "nix"
      "html"
      "nu"
      "yaml"
      "basher"
      "toml"
      "git-firefly"
      "github-actions"
      "mcp-server-github"
      "github-activity-summarizer"
      "opencode"
      "quadlet"
      "dockerfile"
      "docker-compose"
      "catppuccin"
      "catppuccin-icons"
      "terraform"
      "catppuccin-blur"
      "ruff"
      "csv"
      "vscode-dark-modern"
      "intellij-newui-theme"
      "python-requirements"
      "fish"
      "nginx"
      "wakatime"
      "helm"
      "python-snippets"
      "caddyfile"
      "http"
      "perplexity"
      "strace"
      #"cython"
      "color-highlight"
      "supaglass"
      "opentofu"
      "jq"
      "django"
      "eyecandy"
    ];
    extraPackages = with pkgs; [
      nixd
      nil
    ];
  };
}
