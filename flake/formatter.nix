_: {
  perSystem = _: {
    # Multi-tool Nix formatting/linting via treefmt-nix
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt.enable = true;
        deadnix = {
          enable = true;
          no-lambda-pattern-names = true;
        };
        statix.enable = true;
        nixf-diagnose = {
          enable = true;
          ignore = [
            "sema-unused-def-lambda-noarg-formal"
            "sema-unused-def-lambda-witharg-formal"
          ];
        };
        shfmt.enable = true;
      };
      settings.formatter.nixf-diagnose.excludes = [
        "layers/00-cyberia/05-tests/test-radios.nix"
        "layers/00-cyberia/09-tools/nfpu/eval-registry.nix"
      ];
    };
  };
}
