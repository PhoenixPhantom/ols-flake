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
      with pkgs;
      {
         packages.${system}.default =
         let
            version = "nightly";
         in
         stdenv.mkDerivation {
            name = "ols";

            src = fetchFromGitHub {
               owner = "DanielGavin";
               repo = "ols";
               rev = version;
               hash = "sha256-nbJuvdkQvwKiV1x/s97GpORGcYUtPXRvImZgYlNEt5E=";
            };

            postPatch = ''
               substituteInPlace build.sh \
               --replace-fail "-microarch:native" ""
               patchShebangs build.sh odinfmt.sh
               '';

            nativeBuildInputs = [
               makeBinaryWrapper
            ];

            buildInputs = [
               odin
            ];

            buildPhase = ''
               runHook preBuild

               ./build.sh && ./odinfmt.sh

               runHook postBuild
               '';

            installPhase = ''
               runHook preInstall

               install -Dm755 ols odinfmt -t $out/bin/
               wrapProgram $out/bin/ols --set-default ODIN_ROOT ${odin}/share

               runHook postInstall
               '';

            passthru.updateScript = unstableGitUpdater { hardcodeZeroVersion = true; };
         };
         overlays = {
            default = final: prev: {
               ols = self.packages.${prev.system}.default;
            };
         };
      };
}
