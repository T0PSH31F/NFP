{
  description = "Grandlix-Gang NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    # ADD THIS - devenv integration
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-python = {
      url = "github:cachix/nixpkgs-python";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    import-tree.url = "github:vic/import-tree";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixai = {
      url = "github:olafkfreund/nix-ai-help";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules = {
      url = "github:numtide/nixos-facter-modules";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:nix-community/NUR";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazelix = {
      url = "github:luccahuguet/yazelix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      clan-core,
      devenv,
      nix2container,
      nixpkgs-python,
      home-manager,
      import-tree,
      nvf,
      llm-agents,
      noctalia,
      spicetify-nix,
      yazelix,
      ...
    }:
    let
      themeOverlays = import ./overlays/default.nix { inherit inputs; };
      themeOverlay =
        final: prev: (themeOverlays.sonic-cursor final prev) // (themeOverlays.themes final prev);
      customOverlay = import ./overlays/custom-packages.nix;
      desktopOverlay = import ./overlays/desktop-packages.nix;
    in
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        config,
        inputs,
        ...
      }:
      {
        imports = [
          clan-core.flakeModules.default
          home-manager.flakeModules.home-manager
          devenv.flakeModule
          ./devenvs
        ];

        clan = {
          imports = [ ./clan.nix ];
          specialArgs = {
            inherit inputs;
          };
          # Configure nixpkgs to allow unfree packages
          pkgsForSystem =
            system:
            import inputs.nixpkgs {
              localSystem = system;
              config.allowUnfree = true;
              overlays = [
                inputs.nur.overlays.default
                # desktop overlays moved to modules/nixos/overlays.nix
                customOverlay
              ];
            };
        };

        flake.clan.modules = {
          desktop = ./clan-service-modules/desktop;
          media = ./clan-service-modules/media;
          ai = ./clan-service-modules/ai;
        };

        systems = [ "x86_64-linux" ];

        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [
                inputs.nur.overlays.default
                # desktop overlays moved to modules/nixos/overlays.nix
                customOverlay
              ];
            };
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                clan-core.packages.${system}.clan-cli
                nil
                nixfmt-tree
                nixel
                nix-top
                nix-fast-build
                nixpkgs-pytools
                nixfmt
                deadnix
                statix
                nix-search-cli
                git
                curl
              ];

              shellHook = ''
                                cat << 'EOF'
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⢿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⣀⣼⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⡗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⡈⣇⠀⠀⠀⢀⣠⣴⣶⠿⢿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡀⣀⣇⣀⡀⠀⠀⠀⠀⠀⠀⣄⣤⡾⠿⡻⣿⣿⣿⣶⠾⠛⠋⠁⠀⠀⢸⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⠛⠿⠟⢻⣷⡄⠀⣀⣦⠶⠛⠉⠁⠀⠀⢹⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣶⣿⣷⣾⣯⡿⡟⠉⠀⠀⠀⠀⠀⠀⠀⠀⢃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣩⣿⠿⠋⢡⠊⣻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣶⠿⠛⠉⠀⢀⣴⡵⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢱⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⠟⢻⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⡾⢿⠏⠁⡠⠒⣉⣹⣾⣏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢇⠀⠀⢆⠀⠀⣇⠀⠀⢸⡏⡍⠀⢸⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠰⡿⠛⠁⣴⡅⢣⣾⣲⣿⡿⠿⡟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠇⢀⣨⣤⣶⣾⣾⣟⣿⣿⡇⣀⣼
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠇⠀⠀⢀⣼⣾⣷⠋⡟⢱⣰⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⡿⣿⠛⣿⠉⡟⠀⡏⠈⡇⠙⢻⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠊⢹⡞⣸⣘⠥⣻⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⡏⠀⡇⠀⡇⠀⢳⠀⢇⠀⣸⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠘⣍⠙⣏⣼⡍⠢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣷⠀⢹⡀⢿⢀⣸⣆⣾⣽⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣄⢠⡠⠤⣄⣸⡀⠀⠀⠀⡸⣿⡯⣷⣯⡟⠦⡈⠲⣄⣠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣼⣼⣧⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⣿⢿⢟⠟⢠⡴⠈⢿⡇⠀⠀⢰⢣⠻⡉⠉⢀⠇⠀⠌⠳⡄⢀⡽⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⠿⠿⣟⢷⣶⠏⡼⣲⣶⢸⣧⣄⢸⣷⣤⣌⣉⣙⣒⣋⠻⠥⢀⣀⡘⠀⢙⣶⣇⡀⣤⠤⠤⢤⡄⠤⣀⣀⣀⠀⠀⠀⠀⣿⣿⣟⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⡿⠟⢋⢰⣿⠇⠀⠸⣅⣼⠟⡿⡃⢀⣿⡿⢸⣿⣦⡟⢁⡀⢀⡸⡙⣿⣷⣶⠉⠻⠿⠿⢿⣰⠁⡎⠉⢢⠹⡀⠈⠻⣿⣷⡄⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⠂⠀⣾⠀⠀⠀⢰⣴⡿⢛⣾⣣⣿⡟⣻⡀⢋⣿⣿⡄⢻⡇⢸⡇⣀⣿⣿⡏⢀⣦⣤⣤⣤⣘⣦⣉⣁⡼⢠⣇⠀⣀⣧⣿⣿⡀⠀⣿⠏⢠⣏⣿⠛⢿⣿⣿
                ⣿⣿⣿⣦⡤⠃⠀⠀⢠⣿⠀⢠⣾⣿⣿⣿⠷⡿⠇⣿⠿⢿⣿⣿⣇⢼⣿⢹⣿⡟⢀⣼⣿⣧⡿⣿⣿⣿⡄⢠⢶⣿⣿⡿⠿⠿⠿⠟⠧⢸⣿⣿⣿⣿⣿⣶⣿
                ⣿⣿⣿⣿⣿⣦⡐⢠⡯⠼⣶⣿⣿⣿⣿⡏⠀⠀⣸⣿⣶⣦⣤⣍⣙⠛⠻⠿⠿⠀⡞⢻⣿⣿⣿⣿⣿⣿⣷⠘⡞⣿⣿⣿⣄⣠⣾⡧⠀⠤⡟⢓⠷⠽⣦⣭⣓⠿
                ⣿⣿⣿⣿⣿⡟⠅⣠⡳⠀⣨⣿⣟⢻⣟⣔⡆⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣼⡁⠸⣿⣿⣿⣭⣿⣿⣿⡄⢱⣘⣿⣿⣿⣯⣡⣿⠇⠀⡇⣸⠉⠓⣶⢸⣿⣿
                ⣿⣿⣿⣿⣿⣿⣾⠟⣹⡋⣿⡆⢹⠿⣄⠛⣣⣿⣿⣿⠁⣾⣿⣿⣿⣿⡟⠀⣼⣿⣷⣆⢻⣿⣿⣯⣾⣿⣿⣿⡄⠉⢽⣿⣿⣿⣿⢽⢴⡶⠁⣯⣶⡆⣿⡍⠙⢻
                ⣿⣿⣿⣿⣿⡏⠀⣼⡿⠿⡾⣿⠀⢀⡼⣼⣿⣿⣿⣿⣿⣬⣽⣿⣿⠟⢀⣾⣿⣿⣿⣜⡌⢿⣿⣿⣿⣿⣻⢿⣿⣄⣠⢿⣾⣿⣿⣷⡊⠁⣼⣛⠿⢿⡇⣿⣿⣿
                ⣿⣿⣿⣿⣿⣧⣴⣿⣿⠓⣾⡧⡴⣏⣿⣿⣷⣌⡙⠻⣿⣿⣿⣿⠋⣠⣿⣿⣿⣿⣿⣿⣿⣆⠻⣿⣿⣮⣯⣾⣿⡿⠱⢿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣾⢹⣿⣇⣈
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣬⣤⣾⣿⣿⠛⠻⣿⣿⣷⣦⣭⠙⢁⣴⣿⣿⣧⡝⠿⣿⣿⣿⣿⣧⡙⠿⣿⣿⣿⣿⡇⠀⠚⣿⡏⠹⣿⣿⣾⣿⣿⡿⢣⣶⣤⣭⣍
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣷⣽⣿⣷⣤⡼⣿⡿⠛⠁⣠⠾⠿⣿⣿⣿⣿⣦⣈⠻⣿⣿⣿⣷⣄⡈⠙⠿⣿⡇⠀⢒⣿⡇⠀⣿⣿⣿⡿⠟⣡⣿⣾⣿⣯⣽
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⡛⢻⡛⠛⠉⢀⣤⠞⠙⡏⠙⠻⣿⣿⣿⣿⣿⣿⣷⣌⡙⠿⣿⣿⣿⣷⣾⣿⣷⡂⢘⣿⡇⠀⣿⣿⣿⣴⣊⣉⣿⠟⣷⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠻⣗⢺⣿⣏⠀⠀⠀⠁⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣶⣤⣉⣿⣿⣿⣿⣿⣷⠛⣛⠛⣶⣿⣿⣃⣠⠴⠚⢁⣴⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠈⠳⠙⢿⣿⣄⠀⠀⠐⣲⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣾⣿⣿⡿⠯⢐⣦⣵⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠙⠻⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡷⣶⣖⣉⣹⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠈⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠟⠉⠁⠀⢈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠛⠿⠿⣿⣿⣿⣿⣿⣿⣿⣯⣭⣤⣀⣀⠀⠀⠀⣰⣿⣿⠍⣿⣿⣿⣿⣿⣿⣿⣿⣿
                ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⣤⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿
                EOF
                                echo "Grandlix-Gang NixOS Configuration Development Environment"
                                echo "=================================================="
                                echo ""
                                echo "Available devenv shells:"
                                echo "  nix develop .#python-ai-agent  - Python AI/automation dev"
                                echo "  nix develop .#rust-saas        - Rust SaaS development"
                                echo "  nix develop .#node-automation  - Node.js + n8n automation"
                                echo "  nix develop .#go-microservice  - Go microservices"
                                echo "  nix develop .#fullstack        - Combined full-stack"
                                echo ""
                                echo "Quick start with direnv:"
                                echo "  cd ~/projects/my-ai-agent && echo 'use flake ~/Grandlix-Gang#python-ai-agent' > .envrc && direnv allow"
                                echo ""
              '';
            };

            # Image generation outputs using nixos-generators
            # Temporarily commented out to fix base configuration first
            # Uncomment after base system builds successfully
            packages = {
              # # Live ISO
              iso = inputs.nixos-generators.nixosGenerate {
                system = system;
                specialArgs = { inherit inputs; };
                modules = [
                  ./templates/iso/default.nix
                ];
                format = "iso";
              };

            };
            checks =
              let
                theme-tests = import ./tests/themes.nix {
                  inherit pkgs;
                  lib = pkgs.lib;
                };
              in
              {
                inherit (theme-tests) plymouth-theme-builds sddm-theme-builds all-themes;

                services-test = pkgs.testers.nixosTest (import ./tests/services.nix);
              };
          };
      }
    );
}
