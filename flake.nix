# flake.nix
{
   inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      flake-utils.url = "github:numtide/flake-utils";
   };
   outputs = { self, nixpkgs, flake-utils }:
      let
         system = "x86_64-linux";
         overlays = [];
         pkgs = import nixpkgs {
            inherit system overlays;
         };
      in
      {
         packages.${system}.default =
         let
            version = "cbb4e352197763b0475ed3be6650fc9fe08d9c99"; # nightly
         in
         pkgs.stdenv.mkDerivation( prev: {
            name = "ols";
            inherit version;

            src = pkgs.fetchFromGitHub {
               owner = "DanielGavin";
               repo = "ols";
               rev = version;
               hash = "sha256-y1RzC3QweG7ocZAse/Lhdvt9yY46BPSOBWw8deyQCDM=";
            };

            postPatch = ''
               substituteInPlace build.sh \
               --replace-fail "-microarch:native" ""
               patchShebangs build.sh odinfmt.sh
               '';

            nativeBuildInputs = [
               pkgs.makeBinaryWrapper
            ];

            odin-override = pkgs.odin;

            buildInputs = [
               prev.odin-override
            ];

            buildPhase = ''
               runHook preBuild

               ./build.sh && ./odinfmt.sh

               runHook postBuild
               '';

            installPhase = ''
               runHook preInstall

               install -Dm755 ols odinfmt -t $out/bin/
               wrapProgram $out/bin/ols --set-default ODIN_ROOT ${prev.odin-override}/share

               runHook postInstall
               '';

            passthru.updateScript = pkgs.unstableGitUpdater { hardcodeZeroVersion = true; };
         });
         overlays = {
            default = final: prev: {
               ols = self.packages.${prev.system}.default;
            };
         };
      };
}
