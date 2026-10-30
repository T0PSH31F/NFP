let
  lib = import <nixpkgs/lib>;
  inherit ((import ./layers/80-lib/81-helpers/mkDendriticModule.nix { inherit lib; }))
    mkDendriticModule
    ;

  mockModule =
    {
      lib,
      ...
    }:
    {
      options.foo = lib.mkEnableOption "foo";
      nixos = {
        environment.systemPackages = [ ];
      };
      home = {
        home.packages = [ ];
      };
    };

  result = mkDendriticModule "test" mockModule {
    config = { };
    inherit lib;
    pkgs = { };
  };
in
builtins.attrNames result
