{
  lib,
  stdenvNoCC,
  requireFile,
  libarchive,
  autoPatchelfHook,
  # installer deps
  alsa-lib,
  fontconfig,
  freetype,
  gtk2,
  libGL,
  mesa,
  nss,
  pam,
  qt5,
  wayland,
  xorg,
  installKey ? "",
  licenseFiles ? [ ],
}:
stdenvNoCC.mkDerivation {
  pname = "matlab-unwrapped";
  version = "R2024a";

  src = requireFile {
    name = "R2024a_Update_2_Linux.iso";
    url = "https://mathworks.com/products/matlab.html";
    hash = "sha256-Is6cdF49ec6tHjvmUQrCcpmCVMDjaeDq9IJXPh9A5Q0=";
  };

  nativeBuildInputs = [
    libarchive
    autoPatchelfHook

    # Used by the installer
    alsa-lib
    fontconfig
    freetype
    gtk2
    libGL
    mesa
    nss
    pam
    qt5.qtbase
    wayland
    xorg.libICE
    xorg.libXdamage
  ];

  inherit installKey;

  # this needs to run in a FHS env (bleh) so don't actually fix up anything for
  # a Nix environment
  dontWrapQtApps = true;
  dontAutoPatchelf = true;
  dontStrip = true;
  dontFixup = true;

  unpackCmd = "bsdtar -vxf $curSrc";
  sourceRoot = ".";

  preUnpack = ''
    if [[ "$installKey" = "" ]]; then
      echo "Set install key: pkgs.matlab.override { installKey = "…"; }"
      exit 1
    fi
  '';

  postPatch = ''
    patchShebangs --build ./install

    # There's more to patch... this script uses absolute paths throughout. yuck.
    # However this should be enough
    substituteInPlace ./install \
      --replace-fail '/bin/pwd' 'command pwd' \
      --replace-fail 'ARCH="unknown"' 'ARCH="glnxa64"'

    extraAutoPatchelfLibs="bin/glnxa64" autoPatchelf bin/glnxa64
  '';

  configurePhase = ''
    {
      printf "destinationFolder=%s\n" "$out"
      printf "fileInstallationKey=%s\n" "$installKey"
      printf "agreeToLicense=%s\n" "yes"
      printf "improveMATLAB=%s\n" "no"
      printf "createAccelTask=%s\n" "false"
    } > installer_input.txt
  '';

  buildPhase = ''
    ./install -inputFile installer_input.txt
  '';

  postInstall = ''
    mkdir -p $out/licenses

    ${lib.concatMapStringsSep "\n" (f: ''
      cp ${lib.escapeShellArg f} $out/licenses/${lib.escapeShellArg (baseNameOf f)}
    '') licenseFiles}
  '';

  meta = {
    description = "A high-level language for numerical computation and visualization";
    homepage = "https://mathworks.com/";
  };
}
