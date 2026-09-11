# pkb-node — personal knowledge base / RAG / vector memory node
# Deployed on homelab machines with private corpus storage.
# Runs brain-service (FastAPI + pgvector + LlamaIndex) and Honcho (profile memory).
{ config, lib, ... }:
{
  config = lib.mkIf (lib.elem "pkb-node" config.machine.tags) {
    services = {
      ai-services.postgresql.enable = lib.mkDefault true;
      ai-services.brain-service.enable = lib.mkDefault true;
      honcho.enable = lib.mkDefault true;
      infrastructure.langfuse.enable = lib.mkDefault true;
    };
    # Monitoring (temp-intensive RAG workloads)
    layers.layer-20.services.config.monitoring.enable = lib.mkDefault true;
    layers.layer-20.services.config.syncthing.enable = lib.mkDefault true;
    layers.layer-20.services.backups.restic.enable = lib.mkDefault true;
  };
}
