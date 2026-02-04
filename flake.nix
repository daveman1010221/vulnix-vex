{
  description = "Dev env and package for Vulnix VEX UI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, npmlock2nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        rust = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rust;
          rustc = rust;
        };

        myCargoTauri = pkgs.callPackage (pkgs.path + "/pkgs/by-name/ca/cargo-tauri/package.nix") {
          rustPlatform = rustPlatform;
        };

        npmlock2nixLib = import (npmlock2nix + "/internal-v2.nix") {
          inherit (pkgs)
            jq
            openssl
            coreutils
            stdenv
            mkShell
            lib
            fetchurl
            writeText
            writeShellScript
            runCommand
            fetchFromGitHub;
          nodejs-16_x = pkgs.nodejs_22;  # map nodejs_16_x to latest LTS
        };

        nodeEnv = npmlock2nixLib.node_modules {
          src = ./.;
          nodejs = pkgs.nodejs_22;
          production = false;
          buildRequirePatchShebangs = true;
        };

        # Detect COSMIC reasonably (Wayland + COSMIC desktop/session markers).
        # We keep this logic duplicated in:
        #   - runtime wrapper (installed app)
        #   - devShell hook (developer workflow)
        cosmicDetectSh = ''
          is_cosmic() {
            # COSMIC tends to advertise via these, depending on how it was launched.
            # We do a case-insensitive substring match.
            for v in \
              "''${XDG_CURRENT_DESKTOP:-}" \
              "''${XDG_SESSION_DESKTOP:-}" \
              "''${DESKTOP_SESSION:-}" \
              "''${COSMIC_SESSION:-}" \
              "''${COSMIC_DESKTOP:-}"
            do
              echo "$v" | ${pkgs.gnugrep}/bin/grep -qi cosmic && return 0
            done
            return 1
          }
        '';
      in {
        packages.vulnix-vex = rustPlatform.buildRustPackage {
          pname = "vulnix-vex";
          version = "0.1.0";
          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            pkg-config
            gobject-introspection
            nodejs
            myCargoTauri
            wasm-bindgen-cli_0_2_108
            wasm-pack
            makeWrapper
            lld
            tailwindcss
            esbuild
            nodeEnv
          ];

          buildInputs = with pkgs; [
            at-spi2-atk
            atkmm
            cairo
            gdk-pixbuf
            glib
            gtk4
            harfbuzz
            librsvg
            libsoup_3
            pango
            webkitgtk_4_1
            openssl
            tailwindcss
          ];

          buildPhase = ''
            echo ">> Setting up writable temp dirs"
          
            export PROJECT_ROOT=$PWD
          
            mkdir -p ./tmp/cargo-home
            mkdir -p ./tmp/rustup-home
            mkdir -p ./tmp/cargo-target
            mkdir -p ./tmp/tmpdir
          
            export CARGO_HOME=$PWD/tmp/cargo-home
            export RUSTUP_HOME=$PWD/tmp/rustup-home
            export CARGO_TARGET_DIR=$PWD/tmp/cargo-target
            export TMPDIR=$PWD/tmp/tmpdir
          
            export CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER=lld

            echo ">> Setting NODE_PATH to our reproducible node_modules"
            export NODE_PATH=${nodeEnv}/node_modules

            echo ">> Running scripts/build-assets.sh manually"
            bash scripts/build-assets.sh
          
            echo ">> Running cargo tauri build"
            cargo tauri build || true
          '';

          installPhase = ''
            runHook preInstall
          
            # Install real binary under libexec so we can put a wrapper in bin/
            mkdir -p $out/libexec
            cp tmp/cargo-target/release/vulnix-vex $out/libexec/vulnix-vex-bin

            # Wrapper: if running under COSMIC+Wayland, force X11 backend via XWayland.
            # Opt-out: VULNIX_VEX_NO_COSMIC_WORKAROUND=1
            mkdir -p $out/bin
cat > $out/bin/vulnix-vex <<EOF
#!/usr/bin/env bash
set -euo pipefail

${cosmicDetectSh}

if [ "''${VULNIX_VEX_NO_COSMIC_WORKAROUND:-0}" != "1" ]; then
  export GDK_BACKEND=x11
fi

exec "$out/libexec/vulnix-vex-bin" "\$@"
EOF
            chmod +x $out/bin/vulnix-vex

            # Install .desktop file
            mkdir -p $out/share/applications
            cat > $out/share/applications/vulnix-vex.desktop <<EOF
[Desktop Entry]
Name=Vulnix VEX
Comment=Vulnerability Explorer UI
Exec=${"$out"}/bin/vulnix-vex
Icon=vulnix-vex
Type=Application
Categories=Utility;
EOF
          
            # Install icons of all sizes
            for size in 16x16 32x32 64x64 128x128 256x256 512x512; do
              mkdir -p $out/share/icons/hicolor/$size/apps
              cp src-tauri/assets/icons/hicolor/$size/apps/vulnix-vex.png $out/share/icons/hicolor/$size/apps/
            done

            # Install a minimal index.theme
            mkdir -p $out/share/icons/hicolor
            cat > $out/share/icons/hicolor/index.theme <<EOF
[Icon Theme]
Name=hicolor
Comment=Fallback theme for icons
Directories=16x16/apps,32x32/apps,64x64/apps,128x128/apps,256x256/apps,512x512/apps

[16x16/apps]
Size=16
Context=Applications
Type=Fixed

[32x32/apps]
Size=32
Context=Applications
Type=Fixed

[64x64/apps]
Size=64
Context=Applications
Type=Fixed

[128x128/apps]
Size=128
Context=Applications
Type=Fixed

[256x256/apps]
Size=256
Context=Applications
Type=Fixed

[512x512/apps]
Size=512
Context=Applications
Type=Fixed
EOF

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Vulnix VEX - A vulnerability analysis UI tool";
            homepage = "https://github.com/daveman1010221/vulnix-vex";
            license = licenses.mit;
            platforms = platforms.all;
            maintainers = [ "David Shepard" ];
          };
        };

        packages.default = self.packages.${system}.vulnix-vex;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rust
            myCargoTauri
            pkg-config
            nodejs
            gobject-introspection
            at-spi2-atk
            atkmm
            binaryen
            cairo
            gdk-pixbuf
            glib
            gtk4
            harfbuzz
            librsvg
            libsoup_3
            pango
            webkitgtk_4_1
            openssl
            wasm-bindgen-cli_0_2_108
            wasm-pack
            simple-http-server
            tree
            strace
            lld
            tailwindcss
          ];

          shellHook = ''
            export PROJECT_ROOT=$(pwd -P)
            export PATH="$PROJECT_ROOT/scripts:$PATH"

            if [ "''${VULNIX_VEX_NO_COSMIC_WORKAROUND:-0}" != "1" ]; then
              export GDK_BACKEND=x11
            fi

            echo "[+] Vulnix dev shell activated"
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.vulnix-vex}/bin/vulnix-vex";
        };
      }
    );
}
