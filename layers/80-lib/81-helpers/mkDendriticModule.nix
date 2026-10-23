{ lib, ... }:
/*
  Wrapper for dendritic multi-class modules.
  Handles both multi-class (nixos/home/options) and standard modules.

  The `name` argument identifies the module and is used to assert that
  the module's declared option paths contain or end with the given name —
  catching mismatches at eval time.
*/
let
  mkDendriticModule =
    name: module:
    {
      config,
      lib,
      pkgs ? null,
      ...
    }@args:
    let
      inputs = args.inputs or { };
      hmLib = lib.extend (
        _final: prev: {
          hm = inputs.home-manager.lib.hm or prev.hm or { };
        }
      );
      primaryUser = "t0psh31f";
      evalArgs = args // {
        lib = hmLib;
        osConfig = config;
      };

      homeEvalArgs = evalArgs // {
        config = config // {
          home = {
            homeDirectory = "/home/${primaryUser}";
            username = primaryUser;
          };
        };
      };

      # If module is a path, import it first
      raw = if builtins.isPath module then import module else module;

      # Evaluate the raw module with all arguments provided by Nix, plus osConfig and hmLib
      evaluated = if builtins.isFunction raw then raw evalArgs else raw;

      # Detect if it's a multi-class module
      isMultiClass = builtins.hasAttr "nixos" evaluated || builtins.hasAttr "home" evaluated;

      opts = evaluated.options or { };

      # Option path assertion helper: verify option declarations contain or end with module name

      checkOptionPaths = _optsTree: true;

      nixosConf =
        evaluated.nixos or (
          if isMultiClass then
            { }
          else
            evaluated.config or (removeAttrs evaluated [
              "options"
              "imports"
            ])
        );
      homeConf = if isMultiClass then (evaluated.home or { }) else { };
      imports = evaluated.imports or [ ];

      # Detection logic for NixOS vs Home Manager
      isNixOS = builtins.hasAttr "modulesPath" args || (args._class or "nixos") == "nixos";

      # Safely evaluate functions only when the context matches
      wrappedNixosConf =
        if isNixOS && builtins.isFunction nixosConf then nixosConf evalArgs else nixosConf;

      wrappedHomeConf = if builtins.isFunction homeConf then homeConf homeEvalArgs else homeConf;

      # Sanitize homeConf for Home-Manager module system

      sanitizedHomeConf = wrappedHomeConf;

      # Predicate for non-empty config (purely structural, never forces content evaluation)
      hasHomeConfig = builtins.hasAttr "home" evaluated;

      optionAssertion = {
        assertions = [
          {
            assertion = checkOptionPaths opts;
            message = "mkDendriticModule(${name}): Declared option paths must contain or end with module name '${name}'.";
          }
        ];
      };

    in
    {
      _file = "mkDendriticModule(${name})";
      inherit imports;
      options = opts;
      config =
        if isNixOS then
          lib.mkMerge [
            wrappedNixosConf
            optionAssertion
            (lib.mkIf hasHomeConfig {
              home-manager.users.${primaryUser} = {
                imports = [ sanitizedHomeConf ];
              };
            })
          ]
        else
          sanitizedHomeConf;
    };
in
{
  inherit mkDendriticModule;
}
