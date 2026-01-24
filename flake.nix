{
  description = "Grandlix-Gang NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

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

    anifetch = {
      url = "github:Notenlish/anifetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww.url = "git+https://codeberg.org/LGFae/awww";

    # Desktop Environments
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland and plugins - version-matched for ABI compatibility
    hyprland = {
      url = "github:hyprwm/Hyprland";
      # Don't follow nixpkgs to get matching plugin versions
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs.hyprland.follows = "hyprland";
    };

    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    omnixy = {
      url = "github:thearctesian/omnixy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-caelestia-shell = {
      url = "github:jutraim/niri-caelestia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # App Launcher
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dynamic Material Design theming from wallpaper
    matugen = {
      url = "github:InioX/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Editor
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional packages
    nixai = {
      url = "github:olafkfreund/nix-ai-help";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    # Spicetify theme
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NUR - Nix User Repository (for Firefox addons)
    nur.url = "github:nix-community/NUR";

    # NixOS image generators (for VMs, ISOs, containers)
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dendritic pattern support
    import-tree.url = "github:vic/import-tree";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    nixos-facter-modules = {
      url = "github:numtide/nixos-facter-modules";
      #  inputs.nixpkgs.follows = "nixpkgs";
    };

    lobster = {
      url = "github:justchokingaround/lobster";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jerry = {
      url = "github:justchokingaround/jerry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      clan-core,
      home-manager,
      import-tree,
      nvf,
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
              ];
            };
        };

        systems = [ "x86_64-linux" ];

        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          {
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
              ];

              shellHook = ''
                echo "Grandlix-Gang NixOS Configuration Development Environment"
                echo "=================================================="
                echo "Available tools:"
                echo "  - clan: Clan-core CLI"
                echo "  - nil: Nix language server"
                echo "  - nixfmt: Nix formatter"
                echo "  - deadnix: Find dead Nix code"
                echo "  - statix: Lints and suggestions for Nix"
                echo "  - nix-search: Search nixpkgs"
                echo ""
                echo "Build images:"
                echo "  - nix build .#images.iso         # Live ISO"
                echo "  - nix build .#images.vm          # VM image"
                echo "  - nix build .#images.container   # Container image"
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

              # # VM Image (QEMU qcow2)
              # vm = inputs.nixos-generators.nixosGenerate {
              #   inherit system;
              #   specialArgs = {inherit inputs;};
              #   modules = [
              #     ./templates/vm/default.nix
              #   ];
              #   format = "vm";
              # };

              # # VMware Image
              # vmware = inputs.nixos-generators.nixosGenerate {
              #   inherit system;
              #   specialArgs = {inherit inputs;};
              #   modules = [
              #     ./templates/vm/default.nix
              #   ];
              #   format = "vmware";
              # };

              # # VirtualBox Image
              # virtualbox = inputs.nixos-generators.nixosGenerate {
              #   inherit system;
              #   specialArgs = {inherit inputs;};
              #   modules = [
              #     ./templates/vm/default.nix
              #   ];
              #   format = "virtualbox";
              # };

              # # Docker Container
              # docker = inputs.nixos-generators.nixosGenerate {
              #   inherit system;
              #   specialArgs = {inherit inputs;};
              #   modules = [
              #     ./templates/container/default.nix
              #   ];
              #   format = "docker";
              # };

              # # LXC Container
              # lxc = inputs.nixos-generators.nixosGenerate {
              #   inherit system;
              #   specialArgs = {inherit inputs;};
              #   modules = [
              #     ./templates/container/default.nix
              #   ];
              #   format = "lxc";
              # };

              # # Amazon EC2 AMI
              # amazon = inputs.nixos-generators.nixosGenerate {
              #   inherit system;
              #   specialArgs = {inherit inputs;};
              #   modules = [
              #     ./templates/vm/default.nix
              #   ];
              #   format = "amazon";
              # };
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
