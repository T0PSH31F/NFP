{
  description = "Grandlix-Gang NixOS Configuration";

  inputs = {
    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      clan-core,
      flake-parts,
      home-manager,
      hypr-dynamic-cursors,
      hyprland-plugins,
      hyprspace,
      import-tree,
      llm-agents,
      noctalia,
      spicetify-nix,
      vicinae,
      vicinae-extensions,

      ...
    }:
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
          ./flake-parts/clan-inventory.nix
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
              overrides = [
                # custom/desktop overlays are handled in flake-parts/system/overlays.nix
                (import ./overlays/custom-packages.nix)
              ];
            };
        };

        # Register clan services from new structure
        flake.clan.modules = {
          # AI services
          ai = ./clan-services/sillytavern/module.nix;

          # Desktop/Infrastructure services bundle
          desktop = ./clan-services/homepage-dashboard/module.nix;

          # Media services
          media = ./clan-services/aria2/module.nix;

          # Binary cache
          binary-cache = ./clan-services/binary-cache/module.nix;
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
                (import ./overlays/custom-packages.nix)
              ];
            };
            packages.iso =
              (inputs.nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = { inherit inputs; };
                modules = [
                  ./templates/iso/default.nix
                ];
              }).config.system.build.isoImage;

            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                clan-core.packages.${system}.clan-cli
                curl
                deadnix
                git
                nil
                nix-fast-build
                nix-search-cli
                nix-top
                nixel
                nixfmt
                nixfmt-tree
                nixpkgs-pytools
                statix
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
                                echo "Nix Flake Pirates Configuration"
                                echo "==================================="
                                echo ""
                                echo "NOTE: Development environments have been moved to T0PSH31F/grandlix-devenvs"
                                echo ""
                                echo "Quick start:"
                                echo "  nix develop github:T0PSH31F/grandlix-devenvs#python-ai-agent"
                                echo ""
              '';
            };

            # Image generation outputs using nixos-generators removed
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
