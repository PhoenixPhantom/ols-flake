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
         packages.${system}.default = pkgs.stdenv.mkDerivation( prev: {
            name = "ols";
            version = "2026-03";

            src = pkgs.fetchFromGitHub {
               owner = "DanielGavin";
               repo = "ols";
               rev = "6df736633040e58f48859f243ae3759706fe7be5";
               hash = "sha256-Hx1wxYXHAAJ9s0mjBpj4SvVKSLJY7dCBK9+cVsDrLiY=";
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
