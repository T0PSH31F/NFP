# ai-ui — interactive chat & RAG user interfaces (Open WebUI, SillyTavern)
# Enable ONLY on machines explicitly intended to host public or tailnet user chat UIs.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "ai-ui" config.machine.tags) {
    services.ai-services.open-webui.enable = lib.mkDefault true;
    services.sillytavern-app.enable = lib.mkDefault true;
  };
}
