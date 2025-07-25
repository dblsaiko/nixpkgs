{
  fetchFromGitHub,
  python3Packages,
  python3,
  rustPlatform,

  stdenv,
  cmake,
  gcc12,

  gdb,
  gobject-introspection,
  pkg-config,
  gtk3,
  wrapGAppsHook3,
  qt6,
}:
let
  version = "0.4.3";

  libscanmem = stdenv.mkDerivation {
    pname = "libscanmem-PINCE";
    inherit version;

    src = fetchFromGitHub {
      owner = "brkzlr";
      repo = "libscanmem-PINCE";
      rev = "03b28a7a673bee355a535d756de00d2caf2d10a8";
      hash = "sha256-jAg+Er0KbdwvblEk/wNSEqncQtyAwLqOPHur8jnRZac=";
    };

    nativeBuildInputs = [
      gcc12
      cmake
    ];

    installPhase = ''
      mkdir -p $out/include
      cp --preserve "libscanmem.so" $out/include/
      cp --preserve "$src/wrappers/scanmem.py" $out/include/
    '';
  };

  pointersearcher = rustPlatform.buildRustPackage rec {
    pname = "pointersearcher-x";
    version = "0.7.4";

    src = fetchFromGitHub {
      owner = "kekeimiku";
      repo = "PointerSearcher-X";
      rev = "v${version}-dylib";
      hash = "sha256-XEIaAdOvX87ISL335Sxg0NXRVJScwQUKDaSqiYaHkto=";
    };

    cargoDeps = rustPlatform.importCargoLock {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "argh-0.1.13" = "sha256-h8jQI23JIoGqXzmeQDDCGX5Pz24w2tIGnsbtBYdzfPA=";
      };
    };

    nativeBuildInputs = [
      gcc12
      cmake
      pkg-config
    ];

    postPatch = ''
      ln -s ${./Cargo.lock} Cargo.lock
    '';

    buildAndTestSubdir = "libptrscan";
  };

  pythonPATH = python3.withPackages (
    lb: with lb; [
      pyqt6
      pexpect
      capstone
      keystone-engine
      pygdbmi
      keyboard
      pygobject3
    ]
  );
in
python3Packages.buildPythonApplication rec {
  pname = "PINCE";
  inherit version;

  src = fetchFromGitHub {
    owner = "korcankaraokcu";
    repo = "PINCE";
    rev = "v${version}";
    hash = "sha256-hGPENzcMbXTRZ57wxTDIGPK9dDvjKVeGwhgGX6fB25I=";
    fetchSubmodules = true;
  };

  propagatedBuildInputs = with python3Packages; [
    pyqt6
    pexpect
    capstone
    keystone-engine
    pygdbmi
    keyboard
    pygobject3

    pkg-config
    gdb
    gobject-introspection
    gtk3
    qt6.qtbase
  ];

  nativeBuildInputs = [
    wrapGAppsHook3
    gobject-introspection
    qt6.wrapQtAppsHook
  ];

  dontWrapGApps = true;
  dontWrapQtApps = true;

  installPhase = ''
    mkdir -p $out/bin/

    cp -r GUI      $out/bin/
    cp -r i18n     $out/bin/
    cp -r libpince $out/bin/
    cp -r media    $out/bin/
    cp -r tr       $out/bin/

    cp -r PINCE.py $out/bin/PINCE

    patchShebangs --host $out/bin/PINCE
    wrapPythonProgramsIn "$out/bin/" "$out ${pythonPATH}"
  '';

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  postFixup = ''
    mkdir -p $out/bin/libpince/libscanmem
    mkdir -p $out/bin/libpince/libptrscan

    cp --preserve ${libscanmem}/include/libscanmem.so   $out/bin/libpince/libscanmem/
    cp --preserve ${libscanmem}/include/scanmem.py      $out/bin/libpince/libscanmem/

    cp --preserve ${pointersearcher}/lib/libptrscan.so  $out/bin/libpince/libptrscan/
    cp --preserve ${./ptrscan.py}                       $out/bin/libpince/libptrscan/ptrscan.py
  '';

  pyproject = false;
}
