# devenvs/default.nix - Imports all development environments
{ inputs, ... }:
{
  imports = [
    ./python-ai-agent.nix
    ./rust-saas.nix
    ./node-automation.nix
    ./go-microservice.nix
    ./fullstack.nix
  ];

  perSystem =
    { ... }:
    {
      # Fix "devenv was not able to determine the current directory" error
      # by explicitly setting the root for each shell.
      devenv.shells.python-ai-agent.devenv.root = inputs.self.outPath;
      devenv.shells.node-automation.devenv.root = inputs.self.outPath;
      devenv.shells.rust-saas.devenv.root = inputs.self.outPath;
      devenv.shells.go-microservice.devenv.root = inputs.self.outPath;
      devenv.shells.fullstack.devenv.root = inputs.self.outPath;
    };
}
