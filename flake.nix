{
  description = "Nix Flake Pirates (NFP) Configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "https://vicinae.cachix.org"
      "https://hyprland.cachix.org"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
      "https://yazelix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:vSxzZPSh9OCpqJc572Mk9BdbrGMNSbR4F5O4/jVtHK8="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "yazelix.cachix.org-1:ZgxIjQvaP0VTWL8Racx27mpUNzDJ97xC2y7QWYjmGNM="
    ];
  };

  inputs = {
    # ── Core Flake Tools & Clan ──────────────────────────────────
    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.sops-nix.follows = "sops-nix";
      inputs.disko.follows = "disko";
      inputs.systems.follows = "systems";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix.follows = "clan-core/treefmt-nix";

    # ── Desktop & UI Runtimes ───────────────────────────────────
    dsh-nix = {
      url = "github:Samuka007/dsh-nix";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };
    noctalia-official-plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    noctalia-community-plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.systems.follows = "systems";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.vicinae.follows = "vicinae";
      inputs.systems.follows = "systems";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── AI & Agents ────────────────────────────────────────────
    antigravity = {
      url = "github:Jacopone/Antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    camoufox-nix = {
      url = "github:maximoffua/camoufox-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "systems";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-webui = {
      url = "github:nesquena/hermes-webui/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "clan-core/treefmt-nix";
      inputs.systems.follows = "systems";
    };
    nixai = {
      url = "github:olafkfreund/nix-ai-help";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    omp = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    polyfloor = {
      url = "github:T0PSH31F/Polyfloor";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "systems";
      inputs.clan-core.follows = "clan-core";
      inputs.sops-nix.follows = "sops-nix";
    };

    hister = {
      url = "github:asciimoo/hister";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Services & Utilities ───────────────────────────────────
    jerry = {
      url = "github:justchokingaround/jerry";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.flake-parts.follows = "flake-parts";
    };
    lobster = {
      url = "github:justchokingaround/lobster";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    luffy = {
      url = "github:DemonKingSwarn/luffy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr = {
      url = "github:nix-media-server/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-telemetry = {
      url = "github:mrVanDalo/nixos-telemetry";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stellar = {
      url = "github:a3chron/stellar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wakatime-lsp = {
      url = "github:mrnossiom/wakatime-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      clan-core,
      flake-parts,
      home-manager,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        imports = [
          clan-core.flakeModules.default
          home-manager.flakeModules.home-manager
          inputs.treefmt-nix.flakeModule
          ./flake/formatter.nix
          ./flake/checks.nix
          ./flake/packages.nix
          ./layers/00-cyberia/07-clan/clan-inventory.nix
          ./layers/00-cyberia/07-clan/devshell.nix
          ./layers/00-cyberia/07-clan/git-hooks.nix
        ];

        clan = {
          imports = [ ./clan.nix ];
          specialArgs = {
            inherit inputs;
            inherit (import ./layers/80-lib/81-helpers/mkDendriticModule.nix { inherit (inputs.nixpkgs) lib; })
              mkDendriticModule
              ;
            inherit (import ./layers/80-lib/81-helpers/mkDendriticTree.nix { inherit (inputs.nixpkgs) lib; })
              mkDendriticTree
              ;
          };
          pkgsForSystem =
            system:
            import inputs.nixpkgs {
              localSystem = system;
              config.allowUnfree = true;
            };
        };

        flake.clan = {
          modules = {
            nix-cache = ./layers/20-services/28-clan-services/nix-cache/default.nix;
            matrix-synapse = ./layers/20-services/28-clan-services/matrix-synapse/module.nix;
          };
        };

        flake.nfpuRegistry =
          let
            extractMachineConfig =
              _name: machine:
              let
                cfg = machine.config;
                layer20Services = cfg.layers.layer-20.services.config or { };
                services = builtins.mapAttrs (_sName: sCfg: {
                  enable = sCfg.enable or false;
                }) layer20Services;
              in
              {
                inherit services;
                layer10 = cfg.layers.layer-10.system or { };
              };
          in
          builtins.mapAttrs extractMachineConfig inputs.self.nixosConfigurations;

        systems = [ "x86_64-linux" ];
      }
    );
}
