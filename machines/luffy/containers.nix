_:

{
  virtualisation.oci-containers.containers = {

    crawl4ai = {
      image = "unclecode/crawl4ai@sha256:a45fd08f8f15f67026c1bff0a151f0479244caf6751a0c6943b3870efafcd025";
      ports = [ "32775:11235" ];
    };

    skyvern-ui = {
      image = "public.ecr.aws/skyvern/skyvern-ui@sha256:5d963660ec3a0827f79b2e1549e99112d5e707926d623b9423c2cb0d31566cb7";
      ports = [ "32776:8080" ];
    };

    # Disabled 2026-11-04: the pinned Skyvern image (digest d52b7ddc; :latest is
    # the same image ID fd9e14f63e0f) fails its own startup migrations on every
    # boot, even against a brand-new empty database:
    #   sqlalchemy.exc.OperationalError: duplicate column name: title
    #   [SQL: ALTER TABLE tasks ADD COLUMN title VARCHAR]
    # `alembic heads` reports a single head (78a8db531e69), so this is an
    # upstream schema/migration inconsistency, not corrupted local state.
    # Re-enable after pinning a fixed image, or migrate to Postgres.
    # skyvern-api = {
    #   image = "public.ecr.aws/skyvern/skyvern@sha256:d52b7ddc32301f46de09ed340ab3097b22a2c13e4b3d99b76273a03c92fc7960";
    #   ports = [ "32779:8000" ];
    #   volumes = [
    #     "/var/lib/skyvern/data:/data"
    #     "/var/lib/skyvern/.skyvern:/app/.skyvern"
    #   ];
    #   environment = {
    #     DATABASE_STRING = "sqlite+aiosqlite:////data/skyvern.db";
    #     BROWSER_REMOTE_DEBUGGING_URL = "http://skyvern-chrome:3000";
    #     DOWNLOAD_PATH = "/data/downloads";
    #     BROWSER_SESSION_BASE_PATH = "/data/browser_sessions";
    #     CREDENTIAL_VAULT_TYPE = "skyvern";
    #     ENABLE_LOCAL_CREDENTIAL_VAULT = "true";
    #     LOCAL_CREDENTIAL_VAULT_PATH = "/data/credential_vault";
    #     ENABLE_CODE_BLOCK = "true";
    #     LOG_LEVEL = "INFO";
    #   };
    # };

    skyvern-chrome = {
      image = "ghcr.io/browserless/chromium@sha256:8fb011d07d4f469ea936a0605b4705c7b585108a095d598fcd27b7bef9597caa";
      ports = [ "32780:3000" ];
    };

    sim-studio-ui = {
      image = "ghcr.io/simstudioai/simstudio@sha256:a96bec26e7bca9d125fe6d03e3030082cf97d074fae5b6a0387a44c591e1d1e1";
      ports = [ "32790:3000" ];
    };

    spacedrive = {
      image = "ghcr.io/spacedriveapp/spacedrive/server@sha256:fd3bc896f3a5b8e429e008cedde361d6b9468c48d8c81996fdb1d99e90e0837b";
      ports = [
        "32768:7373"
        "32769:8080"
      ];
      volumes = [ "/var/lib/spacedrive:/data" ];
      environment = {
        SD_AUTH = "disabled";
      };
    };

    # Removed: homepage-dashboard
    # Replaced by the declarative NixOS native service at port 3007.
    # Caddy now reverse-proxies lovelain.duckdns.org → localhost:3007.
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/spacedrive 0755 root root -"
    "d /var/lib/skyvern/data 0755 root root -"
    "d /var/lib/skyvern/.skyvern 0700 root root -"
  ];
}
