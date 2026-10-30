_: {
  perSystem = _: {
    # Multi-tool Nix formatting/linting via treefmt-nix
    treefmt = {
      projectRootFile = "flake.nix";
      programs.nixfmt.enable = true;
      programs.deadnix.no-lambda-pattern-names = true;
      programs.deadnix.enable = true;
      programs.statix.enable = true;
      programs.nixf-diagnose.enable = true;
      programs.shfmt.enable = true;
      programs.nixf-diagnose.ignore = [
        "sema-unused-def-lambda-noarg-formal"
        "sema-unused-def-lambda-witharg-formal"
      ];
      settings.formatter.nixf-diagnose.excludes = [
        "layers/00-cyberia/05-tests/test-radios.nix"
        "layers/00-cyberia/09-tools/nfpu/eval-registry.nix"
      ];
    };
  };
}
