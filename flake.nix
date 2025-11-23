{
  description = "uNmINeD CLI - Minecraft mapper command line interface";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    packages.${system} = {
      unmined-gui = pkgs.stdenv.mkDerivation {
        pname = "unmined-gui";
        version = "0.19.52-dev";

        src = pkgs.fetchurl {
          url = "https://unmined.net/download/unmined-gui-linux-x64-dev/?tmstv=1763761742";
          sha256 = "sha256-+5DGWxE7omkyloLnyPvpl/NAGW0wVqsu3qri0mPalu8=";
          name = "unmined-gui_0.19.52-dev_linux-x64.tar.gz";
        };

        nativeBuildInputs = [pkgs.makeWrapper];

        sourceRoot = ".";

        dontAutoPatchelf = true;
        dontPatchELF = true;
        dontStrip = true;

        installPhase = ''
                    runHook preInstall

                    # Install all files to lib directory
                    mkdir -p $out/lib/unmined
                    cp -r unmined-gui_0.19.52-dev_linux-x64/* $out/lib/unmined/

                    # Create wrapper script that sets up a writable runtime environment
                    mkdir -p $out/bin
                    cat > $out/bin/unmined << 'EOF'
          #!/bin/sh
          # Create a runtime directory with symlinks to read-only files
          RUNTIME_DIR="$HOME/.cache/unmined-runtime"
          mkdir -p "$RUNTIME_DIR"

          # Create symlinks to all the read-only resources if they don't exist
          for item in "$out/lib/unmined"/*; do
            basename_item=$(basename "$item")
            if [ ! -e "$RUNTIME_DIR/$basename_item" ] && [ "$basename_item" != "unmined" ]; then
              ln -sf "$item" "$RUNTIME_DIR/$basename_item"
            fi
          done

          # Copy the binary itself so it can write crash logs in its own directory
          if [ ! -f "$RUNTIME_DIR/unmined" ] || [ "$out/lib/unmined/unmined" -nt "$RUNTIME_DIR/unmined" ]; then
            cp "$out/lib/unmined/unmined" "$RUNTIME_DIR/unmined"
            chmod +x "$RUNTIME_DIR/unmined"
          fi

          cd "$RUNTIME_DIR"

          # Set LD_LIBRARY_PATH for all required libraries
          LIBS="${pkgs.lib.makeLibraryPath [
            pkgs.icu
            pkgs.fontconfig
            pkgs.xorg.libX11
            pkgs.xorg.libXext
            pkgs.xorg.libXi
            pkgs.xorg.libXcursor
            pkgs.xorg.libXrandr
            pkgs.xorg.libICE
            pkgs.xorg.libSM
            pkgs.xorg.libXrender
            pkgs.libGL
            pkgs.libglvnd
          ]}"
          export LD_LIBRARY_PATH="$RUNTIME_DIR:$LIBS:$LD_LIBRARY_PATH"

          # Run the binary from the writable runtime directory
          exec "$RUNTIME_DIR/unmined" "$@"
          EOF
                    chmod +x $out/bin/unmined

                    # Substitute the actual $out path and library paths
                    libs="${pkgs.lib.makeLibraryPath [
            pkgs.icu
            pkgs.fontconfig
            pkgs.xorg.libX11
            pkgs.xorg.libXext
            pkgs.xorg.libXi
            pkgs.xorg.libXcursor
            pkgs.xorg.libXrandr
            pkgs.xorg.libICE
            pkgs.xorg.libSM
            pkgs.xorg.libXrender
            pkgs.libGL
            pkgs.libglvnd
          ]}"
                    substituteInPlace $out/bin/unmined \
                      --replace '$out' "$out" \
                      --subst-var libs

                    runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "uNmINeD - Minecraft world mapper GUI";
          homepage = "https://unmined.net";
          license = licenses.unfree;
          platforms = ["x86_64-linux"];
          mainProgram = "unmined";
        };
      };

      unmined-cli = pkgs.stdenv.mkDerivation {
        pname = "unmined-cli";
        version = "0.19.52-dev";

        src = pkgs.fetchurl {
          url = "https://unmined.net/download/unmined-cli-linux-x64-dev/?tmstv=1763761743";
          sha256 = "sha256-u3ffs4V437/RKJ32YCYFFFTz+L5cq5MHQJBcxVlONkY=";
          name = "unmined-cli_0.19.52-dev_linux-x64.tar.gz";
        };

        nativeBuildInputs = [pkgs.makeWrapper];

        sourceRoot = ".";

        dontAutoPatchelf = true;
        dontPatchELF = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall

          # Install all files to lib directory
          mkdir -p $out/lib/unmined-cli
          cp -r unmined-cli_0.19.52-dev_linux-x64/* $out/lib/unmined-cli/

          # Install the binary to bin and wrap it with ICU library path
          mkdir -p $out/bin
          makeWrapper $out/lib/unmined-cli/unmined-cli $out/bin/unmined-cli \
            --chdir "$out/lib/unmined-cli" \
            --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [pkgs.icu]}"

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "uNmINeD CLI - Minecraft world mapper";
          homepage = "https://unmined.net";
          license = licenses.unfree;
          platforms = ["x86_64-linux"];
          mainProgram = "unmined-cli";
        };
      };

      default = self.packages.${system}.unmined-gui;
    };

    # Convenience app definitions
    apps.${system} = {
      default = {
        type = "app";
        program = "${self.packages.${system}.unmined-gui}/bin/unmined";
      };

      unmined-cli = {
        type = "app";
        program = "${self.packages.${system}.unmined-cli}/bin/unmined-cli";
      };
    };
  };
}
