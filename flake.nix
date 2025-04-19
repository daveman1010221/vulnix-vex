{
  description = "Dev env and package for Vulnix VEX UI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
    let
      system = "x86_64-linux";

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

linuxdeploy = pkgs.stdenv.mkDerivation {
  pname = "linuxdeploy";
  version = "continuous";

  src = pkgs.fetchurl {
    url = "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage";
    sha256 = "sha256-zMA8d0fVDtyVVlrR8nJH3SNe+CfMHUb6iQ4NIakXkrc=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    # Move the real AppImage
    cp $src $out/bin/linuxdeploy-real
    chmod +x $out/bin/linuxdeploy-real

    # Create a wrapper that logs
    cat > $out/bin/linuxdeploy << 'EOF'
#!/usr/bin/env bash
echo "[linuxdeploy] Invoked with args: $@" >&2
exec "$(dirname "$0")/linuxdeploy-real" "$@"
EOF
    chmod +x $out/bin/linuxdeploy
  '';
};


#      linuxdeploy = pkgs.stdenv.mkDerivation {
#        name = "linuxdeploy";
#        src = pkgs.fetchurl {
#          url = "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage";
#          sha256 = "sha256-zMA8d0fVDtyVVlrR8nJH3SNe+CfMHUb6iQ4NIakXkrc=";
#        };
#
#        phases = [ "unpackPhase" "installPhase" ];
#
#        dontUnpack = true;
#
#        buildInputs = [ pkgs.appimage-run ];
#
#        installPhase = ''
#          mkdir -p $out/bin
#
#          cp $src ./linuxdeploy.AppImage
#          chmod +x ./linuxdeploy.AppImage
#          ./linuxdeploy.AppImage --appimage-extract
#
#          # Copy extracted files
#          cp -r squashfs-root/usr/* $out/
#        '';
#      };

    in {
      packages.${system} = {
        vulnix-vex = rustPlatform.buildRustPackage {
          pname = "vulnix-vex";
          version = "0.1.0";
          src = ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
          };

          nativeBuildInputs = with pkgs; [
            binaryen
            pkg-config
            gobject-introspection
            nodejs
            tailwindcss
            myCargoTauri
            wasm-bindgen-cli_0_2_100.out
            wasm-pack
          ];

          buildInputs = with pkgs; [
            gobject-introspection
            pkg-config
            at-spi2-atk
            atkmm
            binaryen
            cairo
            gdk-pixbuf
            glib
            gtk3
            gtk4
            harfbuzz
            librsvg
            libsoup_3
            pango
            webkitgtk_4_1
            openssl
            wasm-bindgen-cli_0_2_100.out
            wasm-pack
          ];

          inherit rust;
        };

        linuxdeploy = linuxdeploy;

        default = self.packages.${system}.vulnix-vex;
      };

      devShells.${system}.default = 
        pkgs.mkShell {
          packages = [
            rust
            myCargoTauri
            pkgs.pkg-config
            pkgs.nodejs
            pkgs.tailwindcss
          ] ++ (with pkgs; [
            gobject-introspection
            at-spi2-atk
            atkmm
            binaryen
            cairo
            gdk-pixbuf
            glib
            gtk3
            gtk4
            harfbuzz
            librsvg
            libsoup_3
            pango
            webkitgtk_4_1
            openssl
            wasm-bindgen-cli_0_2_100.out
            wasm-pack
            simple-http-server
            linuxdeploy
          ]);

          shellHook = ''
            export PROJECT_ROOT=$(pwd -P)
            echo "[+] Vulnix dev shell activated"
          '';
        };
    };
}
