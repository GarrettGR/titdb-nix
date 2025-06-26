{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libevdev,
}: let
  simple-cmd-parser = fetchFromGitHub {
    owner = "tascvh";
    repo = "simple-cmd-parser";
    rev = "8b04b233517f64883b4181dc3fb7beac3fe6afd3";
    sha256 = "sha256-ZBvXd11r3OHfqnmeRl7te7RY4XfpSKdFuJXDBEIukrk=";
  };
in
  stdenv.mkDerivation rec {
    pname = "trackpad-is-too-damn-big";
    version = "unstable-2025-06-26";

    src = fetchFromGitHub {
      owner = "tascvh";
      repo = "trackpad-is-too-damn-big";
      rev = "main";
      sha256 = "sha256-WAJXSWO3d8JfvBXS23hRxBbyP2vESXf+aVRLy7u/Jgw=";
    };

    nativeBuildInputs = [
      cmake
      pkg-config
    ];

    buildInputs = [
      libevdev
    ];

    postUnpack = ''
      mkdir -p $sourceRoot/external/simple-cmd-parser
      cp -r ${simple-cmd-parser}/* $sourceRoot/external/simple-cmd-parser/
    '';

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp titdb $out/bin/

      runHook postInstall
    '';

    meta = with lib; {
      description = "Utility to customize trackpad behavior on Linux by virtually reducing trackpad size";
      longDescription = ''
        Trackpad Is Too Damn Big (TITDB) is a utility designed to customize trackpad behavior on Linux.
        TITDB creates a virtual trackpad device and forwards input events from the selected trackpad device
        to it while preventing other applications from receiving events from the original trackpad device
        and modifying the events to achieve the desired functionality.
      '';
      homepage = "https://github.com/tascvh/trackpad-is-too-damn-big";
      license = licenses.gpl3Plus;
      maintainers = [garrettgr];
      platforms = platforms.linux;
      mainProgram = "titdb";
    };
  }
