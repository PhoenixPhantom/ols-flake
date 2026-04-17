# flake.nix
{
   inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      flake-utils.url = "github:numtide/flake-utils";
      odinlang = {
         url = "github:PhoenixPhantom/odin-flake";
         inputs = {
            nixpkgs.follows = "nixpkgs";
            flake-utils.follows = "flake-utils";
         };
      };
   };
   outputs = { self, nixpkgs, flake-utils, odinlang }:
   flake-utils.lib.eachDefaultSystem (system:
      let
         overlays = [ odinlang.overlays.default ];
         pkgs = import nixpkgs {
            inherit system overlays;
         };
      in
      rec {
         packages.default = pkgs.stdenv.mkDerivation( prev: {
            name = "ols";
            version = "nightly-2026-04-17";

            src = pkgs.fetchFromGitHub {
               owner = "DanielGavin";
               repo = "ols";
               rev = "8bcda891f6ab2adfdc7d2b9a8106814b401adfcf";
               hash = "sha256-aPYBK+UkbdY2WV+nmXwWdJTPsR1pTCvG7b/ORmXdcWE=";
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

               mkdir -p $out/bin/builtin
               install -Dm755 ols odinfmt builtin/* -t $out/bin/
               wrapProgram $out/bin/ols \
                  --set-default ODIN_ROOT ${prev.odin-override}/share \
                  --set-default OLS_BUILTIN_FOLDER ${prev.odin-override}/share/base/builtin

               runHook postInstall
            '';

            passthru.updateScript = pkgs.unstableGitUpdater { hardcodeZeroVersion = true; };
         });
         devShells.default = pkgs.mkShell {
            name = "ols";
            buildInputs = [ packages.default ];
         };
      }) // {
      overlays = {
         default = final: prev: {
            ols = self.packages.${prev.system}.default;
         };
      };
   };
}
