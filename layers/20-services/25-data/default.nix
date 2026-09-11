{ mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "chromadb" ./chromadb.nix)
    (mkDendriticModule "databases" ./databases.nix)
    (mkDendriticModule "filebrowser" ./filebrowser.nix)
    (mkDendriticModule "harmonia" ./harmonia.nix)
    (mkDendriticModule "lokb" ./lokb.nix)
    (mkDendriticModule "postgresql-vectordb" ./postgresql-vectordb.nix)
    (mkDendriticModule "qdrant" ./qdrant.nix)
    (mkDendriticModule "restic-backups" ./restic-backups.nix)
    (mkDendriticModule "syncthing" ./syncthing.nix)
    (mkDendriticModule "vaultwarden" ./vaultwarden.nix)
  ];
}
