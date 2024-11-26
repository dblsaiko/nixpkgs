{
  lib,
  stdenvNoCC,
  buildFHSEnv,
  makeDesktopItem,
  writeShellScriptBin,
  copyDesktopItems,
  matlab-unwrapped,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "matlab";
  version = matlab-unwrapped.version;

  nativeBuildInputs = [ copyDesktopItems ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  matlabBins = [
    "matlab"
    "mex"
    "mlint"
  ];

  postInstall = ''
    install -d $out/bin $out/share/applications $out/share/pixmaps

    ln -s ${self.env}/bin/matlab-env $out/bin/matlab-env

    ${
      let
        launcherFor =
          name:
          writeShellScriptBin name ''
            exec ${self.env}/bin/matlab-env ${name} "''${@}"
          '';
      in
      lib.concatMapStringsSep "\n" (
        name: "ln -sv ${lib.getExe (launcherFor name)} $out/bin/${name}"
      ) self.matlabBins
    }

    ln -s ${matlab-unwrapped}/bin/glnxa64/cef_resources/matlab_icon.png $out/share/pixmaps/matlab.png
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "matlab";
      exec = "matlab -desktop %F";
      icon = "matlab";
      desktopName = "MATLAB";
      categories = [
        "Utility"
        "TextEditor"
        "Development"
        "IDE"
      ];
      mimeTypes = [
        "text/x-octave"
        "text/x-matlab"
      ];
      keywords = [
        "science"
        "math"
        "matrix"
        "numerical computation"
        "plotting"
      ];
    })
  ];

  env = buildFHSEnv {
    name = "matlab-env";

    targetPkgs =
      pkgs:
      builtins.attrValues {
        matlab-bins = pkgs.runCommand "matlab-bins" { } ''
          install -d $out/bin

          ${lib.concatMapStringsSep "\n" (name: ''
            found=0
            for prefix in ${matlab-unwrapped}/bin ${matlab-unwrapped}/bin/glnxa64; do
              if [[ -f "$prefix/${name}" ]]; then
                ln -sv $prefix/${name} $out/bin/${name}
                found=1
                break
              fi
            done

            if (( ! found )); then
              echo "couldn't find MATLAB binary ${name}"
              exit 1
            fi
          '') self.matlabBins}
        '';

        # From https://gitlab.com/doronbehar/nix-matlab/-/blob/master/common.nix
        inherit (pkgs)
          alsa-lib
          at-spi2-atk
          at-spi2-core
          atk
          cairo
          cups
          dbus
          fontconfig
          gcc
          gdk-pixbuf
          gfortran
          glib
          glibc
          glibcLocales
          gtk3
          gtk2
          jre
          libdrm
          libglvnd
          libselinux
          libsndfile
          libuuid
          libxcrypt
          libxcrypt-legacy
          libxkbcommon
          mesa
          ncurses
          nspr
          nss
          pam
          pango
          procps
          python3
          udev
          unzip
          xkeyboard_config
          zlib
          cacert
          ;

        inherit (pkgs.gst_all_1)
          gst-plugins-base
          gstreamer
          ;

        inherit (pkgs.mesa)
          drivers
          ;

        inherit (pkgs.xorg)
          libSM
          libX11
          libXcomposite
          libXcursor
          libXdamage
          libXext
          libXfixes
          libXft
          libXi
          libXinerama
          libXrandr
          libXrender
          libXt
          libXtst
          libXxf86vm
          libxcb
          ;
      };

    runScript = lib.getExe (
      writeShellScriptBin "matlab-env" ''
        if [[ "$1" = "" ]]; then
          exec "$SHELL"
        else
          exec "''${@}"
        fi
      ''
    );
  };

  passthru.unwrapped = matlab-unwrapped;

  meta = {
    inherit (matlab-unwrapped.meta)
      description
      homepage
      ;
    mainProgram = "matlab";
  };
})
