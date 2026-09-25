# ai-inference — local LLM inference engines (Ollama, llama-cpp)
# Enable ONLY on machines with GPU/accelerated compute intended for local model execution.
{ config, lib, ... }:
{
  config = lib.mkIf (builtins.elem "ai-inference" config.machine.tags) {
    services.ai-services.ollama.enable = lib.mkDefault true;
  };
}
