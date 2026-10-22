# overlays/custom-packages.nix
# Custom packages you might want available on all systems.

final: prev: {
  # ── electron_41 pin: REMOVED (2026-10-15) ──────────────────────────
  # Tried pinning electron_41 to 41.10.3 to stop paseo-desktop/hermes-* from
  # re-hashing on nixpkgs bumps. It was wrong on both counts:
  #   1. No benefit — paseo/hermes-one come from inputs.llm-agents, which does
  #      NOT follow our nixpkgs (see flake.nix), so this overlay could never
  #      reach them anyway.
  #   2. Net harm — it forked electron_41 into a local-only derivation that is
  #      404 on cache.nixos.org, turning a substitutable electron into a
  #      multi-hour from-scratch build.
  # If pinning is ever needed, do it where the package is actually consumed
  # (llmPkgs.paseo-desktop.override { electron_41 = ...; }), not in our overlay.

  # ── typescript-language-server: stale pnpmDeps pin ─────────────────
  # nixpkgs (rev 7fd4004d / 2026-10-11) pins pnpmDeps to
  #   sha256-MUSxDMlbG21KSesGdEvqa2kEpuVfLlXRUX1qV/FGsSo=
  # but `fetchPnpmDeps` reproducibly produces
  #   sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=
  # under our toolchain — verified: that "got" hash is byte-identical to the
  # already-valid store path 4q1qpv5q...-typescript-language-server-pnpm-deps,
  # so the build output is correct and the pin is what's wrong. Left alone this
  # FOD aborts and cascades into tsserver -> helix-languages-config, neovim,
  # nixvim, home-manager-generation -> the toplevel on BOTH machines.
  # Drop this override once nixpkgs fixes the pin (nix-update / upstream PR).
  typescript-language-server = prev.typescript-language-server.overrideAttrs (old: {
    pnpmDeps = prev.fetchPnpmDeps {
      inherit (old) pname version src;
      pnpm = prev.pnpm_12;
      fetcherVersion = 4;
      hash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
    };
  });

  # REMOVED (2026-08-06): glibc 2.42+ linuxHeaders overlays for flatpak,
  # seahorse, vte, libadwaita, xdg-desktop-portal, xdg-desktop-portal-gtk,
  # gnome-bluetooth, zenity, libpanel, gedit, gnome-color-manager, rustdesk,
  # mupdf. The fix is now upstream in nixpkgs-unstable — these packages build
  # and cache-hit without the postPatch workaround. Removing saves ~23 builds.
  #
  # If any of these fail to build after this removal, the upstream fix may have
  # regressed — re-add the specific override and file an upstream issue.
  # Fix: glib 2.88.x libgio links libmount.so.1 from util-linuxMinimal, but
  # buildFHSEnv's rootfs builder sandbox doesn't have util-linuxMinimal
  # available (glib doesn't propagate it). Fix by wrapping buildFHSEnv to add
  # util-linuxMinimal to the rootfs derivation's nativeBuildInputs. Only affects
  # fhsenv rootfs builds (steam, lutris, steam-run, bottles), not the entire system.
  buildFHSEnvBubblewrap =
    let
      interceptCallPackage =
        file: overrides:
        if builtins.isPath file && baseNameOf file == "buildFHSEnv.nix" then
          let
            originalBuildFHSEnv = prev.lib.callPackageWith prev.pkgs file overrides;
          in
          args:
          (originalBuildFHSEnv args).overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              prev.util-linuxMinimal
            ];
          })
        else
          prev.callPackage file overrides;
    in
    prev.lib.callPackageWith prev.pkgs (
      prev.path + "/pkgs/build-support/build-fhsenv-bubblewrap/default.nix"
    ) { callPackage = interceptCallPackage; };

  # REMOVED (2026-08-06): glances test-disable overlay. Upstream 4.5.5 already
  # disables specific sandbox-failing tests (test_webui, test_msg_curse, etc.).
  # Removing restores cache hit for glances.

  # REMOVED (2026-08-07): openldap i686 doCheck overlay — z0r0/luffy are both
  # x86_64-only; this conditional never fires and merely shadows the cached
  # upstream attr. Referenced nowhere in the repo.

  # Upstream nixpkgs has 1.2.16; pin 1.4.4 for Gemini 4 Argon support
  antigravity-cli = prev.antigravity-cli.overrideAttrs (_oldAttrs: rec {
    version = "1.4.4";
    wholeVersion = "${version}-4783783166214144";
    src = prev.fetchurl {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${wholeVersion}/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-muT38GZ6KGjhW7mtk4Gf91J8cYfxLRLjtRkRN8cmKHs=";
    };
  });

  # Antigravity Agent Control Protocol (ACP) server package
  antigravity-acp =
    prev.antigravity-acp or (
      if builtins.pathExists (prev.path + "/pkgs/by-name/an/antigravity-acp/package.nix") then
        final.callPackage (prev.path + "/pkgs/by-name/an/antigravity-acp/package.nix") { }
      else
        final.writeShellScriptBin "antigravity-acp" ''
          exec ${final.antigravity-cli}/bin/agy acp "$@"
        ''
    );

  # niri-flake (2026-08 rev) callPackages its pinned niri with
  # libdisplay-info_0_2 and asserts version == "0.2.0". nixpkgs-unstable
  # removed the 0.2 attr (throw alias). Re-provide it as 0.3 with a version
  # shim: nixpkgs' own niri 26.04 builds cleanly against 0.3, and the C API
  # is stable. Drop this overlay when niri-flake adapts to the removal.
  #
  # 2026-10-15: overriding `version` alone renames the store path but leaves
  # libdisplay-info.pc saying "Version: 0.3.0". libdisplay-info-sys v0.2.2
  # probes pkg-config for `libdisplay-info >= 0.1.0, < 0.3.0` and panics
  # (build.rs unwrap, exit 101) when the .pc rejects it. Patch the .pc too.
  libdisplay-info_0_2 = prev.libdisplay-info_0_3.overrideAttrs (old: {
    version = "0.2.0";
    __intentionallyOverridingVersion = true;
    postFixup = (old.postFixup or "") + ''
      if [ -f "$out/lib/pkgconfig/libdisplay-info.pc" ]; then
        sed -i 's/^Version:.*/Version: 0.2.0/' "$out/lib/pkgconfig/libdisplay-info.pc"
      fi
    '';
  });

  # pgAdmin 4 9.14's installCheckPhase imports its regression suite, which
  # trips psycopg 3.3.5's read-only `psycopg._encodings._py_codecs`
  # (TypeError: 'tuple' object does not support item assignment) and aborts
  # the build. Upstream packaging mismatch, not a pgAdmin runtime defect —
  # skip the checks (same treatment as zat).
  pgadmin4-desktopmode = prev.pgadmin4-desktopmode.overrideAttrs (_old: {
    doCheck = false;
    doInstallCheck = false;
  });

  # Camoufox prebuilt binary from GitHub releases (v150.0.2-beta.25 / alpha.26).
  # Bumped from v135.0.1-beta.24 (2025-03) → v150.0.2-beta.25 (2026-05) because
  # the v135 prebuilt's `libgkcodecs.so` and other dependent libraries carry init
  # routines that SEGV_MAPERR in `_dl_init` on glibc ≥ 2.42 (the dynamic linker
  # fault happens before `_start` even returns, so `MOZ_DISABLE_GKCODECS=1`
  # cannot help). v150 ships a Firefox 150 codebase that is compatible with
  # the current nixpkgs-unstable toolchain.
  #
  # Replaces the source-build from camoufox-nix which fails on newer nixpkgs
  # (Firefox 146 source requires linux-headers in include path; build times ~hours).
  #
  # NOTE: We deliberately do NOT use `autoPatchelfHook` because the camoufox
  # prebuilt is already self-contained — its binaries are pre-patched with
  # RUNPATH entries that point to specific /nix/store paths from the build
  # environment. Re-running autoPatchelfHook rewrites those RUNPATH entries
  # (and the .so files' RUNPATHs) and breaks the static init of `libgkcodecs.so`
  # (and others) on glibc 2.42+, which then segfaults the browser before
  # `main()` ever runs.
  #
  # We only wrap the entry point with `makeWrapper` to prepend the current
  # nixpkgs library path (gtk3, x11, libdrm, mesa, …) so the runtime can find
  # Nix-built system libraries. The prebuilt's own wrapper script (under
  # share/camoufox/camoufox-bin) handles the rest.
  #
  # The v150 alpha.26 release no longer ships a `version.json` file in the
  # zip — we synthesize one from `application.ini` so camoufox-js (used by
  # camofox-browser) can identify the bundle version.
  camoufox =
    let
      version = "150.0.2-beta.25";
      release = "150.0.2";
      runtimeLibs = with final; [
        gtk3
        libxcb
        libx11
        libxkbcommon
        alsa-lib
        libdrm
        mesa
        nss
        nspr
        dbus
        ffmpeg_7
        libpulseaudio
        stdenv.cc.cc.lib
      ];
    in
    final.stdenv.mkDerivation {
      pname = "camoufox";
      inherit version;

      src = final.fetchzip {
        url = "https://github.com/daijro/camoufox/releases/download/v150.0.2-beta.25/camoufox-150.0.2-alpha.26-lin.x86_64.zip";
        hash = "sha256-F/J3HNsGAmlpl4FUdT6vFJwQA0djWEdDjI8heho0zcc=";
        stripRoot = false;
      };

      nativeBuildInputs = [ final.makeWrapper ];
      dontBuild = true;
      dontConfigure = true;
      dontFixup = true;

      installPhase = ''
        mkdir -p $out/lib $out/bin $out/share/camoufox

        # Copy all files (preserves the upstream camoufox-bin wrapper script
        # and the pre-patched ELF binaries / .so files).
        cp -r . $out/share/camoufox/

        # Symlink every .so into $out/lib so the dynamic linker can find them
        # via the LD_LIBRARY_PATH prepend below.
        find $out/share/camoufox -maxdepth 1 -name "*.so" -exec ln -sf {} $out/lib/ \;

        # Synthesize version.json (alpha.26 doesn't ship one). camoufox-js needs
        # this to recognize the bundle via `Version.fromPath()`. It looks for
        # version.json relative to the executable's directory (path.dirname of
        # CAMOUFOX_EXECUTABLE), which resolves to $out/bin/ — so we must place
        # it there too, not just under share/camoufox/.
        cat > $out/share/camoufox/version.json <<EOF
        { "version": "${version}", "release": "${release}" }
        EOF
        cp $out/share/camoufox/version.json $out/bin/version.json
        # Also copy properties.json to bin/ (camoufox-js reads it from there)
        cp $out/share/camoufox/properties.json $out/bin/properties.json 2>/dev/null || true

        # Wrap the upstream camoufox-bin entry point. The upstream wrapper sets
        # up LD_LIBRARY_PATH for the prebuilt's own dependencies; we additionally
        # prepend the Nix runtime lib path so the current nixpkgs libraries
        # (gtk3, x11, libdrm, mesa, ffmpeg, libpulse, dbus, nss, nspr,
        # libxkbcommon, gcc.cc.lib) resolve correctly.
        makeWrapper $out/share/camoufox/camoufox-bin $out/bin/camoufox-bin \
          --prefix LD_LIBRARY_PATH : ${final.lib.makeLibraryPath runtimeLibs} \
          --prefix LD_LIBRARY_PATH : $out/lib

        # Also expose `camoufox` as a convenient alias.
        ln -sf $out/bin/camoufox-bin $out/bin/camoufox
      '';

      meta.mainProgram = "camoufox";
    };
  # camofox-browser: replaced by jo-camofox-browser from camoufox-nix flake overlay
  # (jo-inc fork with VNC + persistence plugins, OpenAPI docs, tracing)
  # Override to use our prebuilt camoufox instead of camoufox-nix's source-built one
  # (Firefox 146 source build takes hours and fails on this machine)
  jo-camofox-browser = prev.jo-camofox-browser.override {
    inherit (final) camoufox;
  };
  camofox-browser = prev.camofox-browser.override {
    inherit (final) camoufox;
  };
  camofox-cli = prev.camofox-cli.override {
    inherit (final) camoufox;
  };
  camofox-mcp = prev.camofox-mcp.override {
    inherit (final) camoufox;
  };
  camoufox-js = prev.camoufox-js.override {
    inherit (final) camoufox;
  };

  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (python-final: python-prev: {
      radios = python-prev.radios.overridePythonAttrs (old: {
        pythonRelaxDeps = [ "pycountry" ];
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ python-final.pythonRelaxDepsHook ];
      });
    })
  ];

  # ── lokb: Local Offline Knowledge Base ─────────────────────────────
  # Rust-based knowledge base with MCP server, hybrid search, and
  # support for 15+ formats (PDF, EPUB, ZIM, Telegram, etc.)
  # https://github.com/meteora-pro/lokb
  # lokb = final.rustPlatform.buildRustPackage rec {
  #   pname = "lokb";
  #   version = "0.1.0-unstable-2026-04-22";

  #   src = final.fetchFromGitHub {
  #     owner = "meteora-pro";
  #     repo = "lokb";
  #     rev = "7f0c8ba068e083467dc8e520f54569b208dd2303";
  #     hash = "sha256-ErF4xAMeWw9K6s7MK/MRZ91iGM8p+tr8smfUBE8vW6I=";
  #   };

  #   cargoLock = {
  #     lockFile = src + "/Cargo.lock";
  #     outputHashes = {
  #       # Add any git dependency hashes here if needed
  #     };
  #   };

  #   nativeBuildInputs = with final; [
  #     pkg-config
  #     rustPlatform.bindgenHook
  #   ];

  #   buildInputs =
  #     with final;
  #     [
  #       openssl
  #       sqlite
  #       zlib
  #       linuxHeaders
  #     ]
  #     ++ final.lib.optionals final.stdenv.isLinux [
  #       # For PDF rendering (poppler)
  #       poppler
  #       poppler_gi
  #       cairo
  #       glib
  #     ];

  #   # Patch lokb-cli to remove lokb-embed dependency (ONNX runtime version conflict).
  #   # Full-text search (Tantivy) and knowledge graph work without embeddings.
  #   # Semantic search can be added later via Ollama API.
  #   postPatch = ''
  #     substituteInPlace crates/lokb-cli/Cargo.toml \
  #       --replace 'lokb-embed = { path = "../lokb-embed" }' '# lokb-embed disabled (ONNX runtime conflict)'
  #     substituteInPlace crates/lokb-cli/src/main.rs \
  #       --replace 'mod parallel_zim;' '# mod parallel_zim;' \
  #       --replace 'Commands::Enrich' 'Commands::_Enrich' \
  #       --replace 'Commands::Entity' 'Commands::_Entity' \
  #       --replace 'Commands::Substring' 'Commands::_Substring' \
  #       --replace 'Commands::BuildIndex' 'Commands::_BuildIndex'
  #   '';

  #   # Disable tests that need network or special setup
  #   doCheck = false;

  #   meta = with final.lib; {
  #     description = "Local Offline Knowledge Base — 15 formats, hybrid search, MCP server";
  #     homepage = "https://github.com/meteora-pro/lokb";
  #     license = licenses.asl20;
  #     maintainers = [ ];
  #     mainProgram = "lokb";
  #   };
  # };

  # ── codegraph: Semantic code intelligence for AI agents ───────────
  # Wrap codegraph to strip plain-text update banners on stdout that break stdio MCP JSON-RPC
  codegraph = final.symlinkJoin {
    name = "codegraph-${prev.codegraph.version or "1.4.1"}";
    paths = [ prev.codegraph ];
    nativeBuildInputs = [ final.makeWrapper ];
    postBuild = ''
      unlink $out/bin/codegraph
      makeWrapper ${prev.codegraph}/bin/codegraph $out/bin/codegraph \
        --run 'if [ "$1" = "serve" ]; then exec ${prev.codegraph}/bin/codegraph "$@" | ${final.gnugrep}/bin/grep --line-buffered -v "^\[CodeGraph\]"; fi'
    '';
  };

  # ── lazyskills: TUI for managing agent skills ────────────────────
  # Blazing-fast terminal UI for managing agent skills across all agents.
  # https://github.com/alvinunreal/lazyskills
  lazyskills = final.buildGoModule {
    pname = "lazyskills";
    version = "0.1.0-unstable-2026-08-08";

    src = final.fetchFromGitHub {
      owner = "alvinunreal";
      repo = "lazyskills";
      # PINNED (2026-10-15): was `rev = "main"`, which drifted and broke the
      # FOD hash mid-build. This is the commit the recorded `hash` above was
      # captured from (verified: its tarball unpacks to exactly
      # sha256-uTosunMSnmgV0gr7eYhxbFAPYQu77Ou4Na8wtVEoiP0=), so vendorHash
      # below is still correct for this rev.
      # To bump: nix-prefetch-github alvinunreal/lazyskills --rev <new>, update
      # `rev` + `hash` (+ `vendorHash` via nix build and take the got-hash),
      # then set `version` to 0.1.0-unstable-<commit-date>.
      rev = "f22610cdb5b745b439354a13f04c1f42de99c06d";
      hash = "sha256-uTosunMSnmgV0gr7eYhxbFAPYQu77Ou4Na8wtVEoiP0=";
    };

    vendorHash = "sha256-JBia588EtY89+vVGUiOyGwLD+rDqBwa2s/jjtd55DE0=";

    # Tests fail in sandbox (network access)
    doCheck = false;

    meta = with final.lib; {
      description = "Blazing-fast TUI for managing agent skills";
      homepage = "https://github.com/alvinunreal/lazyskills";
      license = licenses.mit;
      maintainers = [ ];
      mainProgram = "lazyskills";
    };
  };

  uni-pet = final.buildNpmPackage rec {
    pname = "uni-pet";
    version = "0.1.5";

    src = final.fetchFromGitHub {
      owner = "ydyangdan";
      repo = "UniPet";
      rev = "v${version}";
      hash = "sha256-+bP60vOnCsmEknSSYZ5kxY0xfXEUHZY9dKtVWBofo5A=";
    };

    npmDepsHash = "sha256-jDqXZMd+3jVInzWb3R1mxwTqhTSOFtUrbfMkAyJt7EI=";

    dontNpmBuild = true;

    # Electron's install.js tries to download prebuilt binaries from github.com
    # during npm install, which fails in the nix sandbox (no network).
    # Skip all lifecycle scripts during install to avoid this.
    npmFlags = [ "--ignore-scripts" ];

    meta = with final.lib; {
      description = "Universal Desktop Pet for AI coding agents";
      homepage = "https://github.com/ydyangdan/UniPet";
      license = licenses.mit;
      mainProgram = "unipet";
    };
  };

  agentburn =
    with final.python3Packages;
    buildPythonPackage {
      pname = "agentburn";
      version = "0.1.0-unstable-2026-08-06";
      format = "pyproject";

      # Not on PyPI — distributed via GitHub + uvx. Fetch from GitHub instead.
      #
      # PINNED TO A COMMIT, NOT A BRANCH. `rev = "main"` made this a moving
      # target: upstream commits to main, the fixed-output hash stops matching,
      # and every build fails with `hash mismatch in fixed-output derivation
      # ...-source.drv` (last: 2026-10-12, blocked hermes-agent -> system-path
      # -> z0r0 toplevel for ~1h7m before surfacing). Branch refs are not
      # immutable, so this WILL drift again unless pinned.
      # Repo now tags releases (v0.14.0 as of 2026-10-12) — prefer a tag over
      # a raw commit when bumping, and update `version` alongside it.
      # Bump procedure: curl -s https://api.github.com/repos/Socialpranker/agentburn/commits/main
      # then set rev=<sha> and hash from the build error's `got:` value.
      src = final.fetchFromGitHub {
        owner = "Socialpranker";
        repo = "agentburn";
        rev = "8477cc81b2982e3799864c407d4de0069339854f"; # main @ 2026-10-12
        hash = "sha256-L7rxsJ61ZvFcTQo6vhYGY9ZO/Naa9/0F71tFF3X4bEE=";
      };

      # pyproject.toml requires setuptools>=68 as build backend
      nativeBuildInputs = [ setuptools ];

      doCheck = false;

      meta = with final.lib; {
        description = "Local profiler for AI agent spend";
        homepage = "https://github.com/Socialpranker/agentburn";
        license = licenses.mit;
        mainProgram = "agentburn";
      };
    };

  # REMOVED (2026-08-07): hermes-paperclip-adapter — buildNpmPackage with
  # placeholder hashes (sha256-AAAA...) that never got filled in. Referenced
  # nowhere in the repo. It caused EVERY rebuild to attempt a doomed npm build.
  # Re-add with real hashes if Paperclip integration resumes.

  # ── Headroom: Context compression proxy for AI agents ────────────
  # https://github.com/headroomlabs-ai/headroom
  # Compresses tool outputs, logs, files, and RAG chunks before LLM.
  # 20% fewer tokens for coding agents, 60-95% for JSON.
  headroom-ai = final.python3Packages.buildPythonPackage rec {
    pname = "headroom-ai";
    version = "0.35.0";
    format = "wheel";

    src = final.fetchurl {
      url = "https://files.pythonhosted.org/packages/cp310/h/headroom-ai/headroom_ai-${version}-cp310-abi3-manylinux_2_28_x86_64.whl";
      hash = "sha256-q9u6vDFLCeDyexZvC+Q9w4a43jOASKZv6AS8HTzyv/Q=";
    };

    nativeBuildInputs = with final.python3Packages; [
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = true;
    pythonRemoveDeps = [ "ast-grep-cli" ]; # Not available in nixpkgs, optional for code compression

    propagatedBuildInputs = with final.python3Packages; [
      fastapi
      uvicorn
      httpx
      h2
      pydantic
      tiktoken
      rich
      opentelemetry-api
      pyyaml
      tomlkit
      mcp
    ];

    doCheck = false;

    meta = with final.lib; {
      description = "Context compression proxy for AI agents — 20-95% fewer tokens";
      homepage = "https://github.com/headroomlabs-ai/headroom";
      license = licenses.asl20;
      mainProgram = "headroom";
      platforms = [ "x86_64-linux" ];
    };
  };

  wl_shimeji = final.callPackage ../83-packages/wl_shimeji/default.nix { };
}
