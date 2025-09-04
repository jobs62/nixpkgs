{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  makeWrapper,
  coreutils,
}:
stdenv.mkDerivation rec {
  pname = "osc-udev-rules";
  version = "20190314";

  # extract debian package from larger zip file
  src = fetchurl {
    url = "https://oos.eu-west-2.outscale.com/omi/packages/osc-udev-rules-${version}_amd64.deb";
    hash = "sha256-OFRBcxYU7648WRFpYq+EUpi7yS9QLYAq2hfg2U5GS+c=";
  };

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = ''
    dpkg-deb -x "$src" .
  '';

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -R ./etc $out/
    cp -R ./bin $out/

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/sd-xvd \
       --set PATH ${lib.makeBinPath [
      coreutils
    ]}

    substituteInPlace $out/etc/udev/rules.d/96-osc.rules \
      --replace-fail /bin/ $out/bin
  '';

  meta = with lib; {
    description = "Outscale Udev rules";
    platforms = ["x86_64-linux"];
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    license = licenses.unfree;
    maintainers = with maintainers; [jobs62];
  };
}
