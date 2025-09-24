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
            version = "d4e3c3a58d3ae0c5d42ef76b3de037fc5b720f77"; # nightly
         in
         pkgs.stdenv.mkDerivation( self: {
            name = "ols";
            inherit version;

            src = pkgs.fetchFromGitHub {
               owner = "DanielGavin";
               repo = "ols";
               rev = version;
               hash = "sha256-PNSU2J8cLSTsLZqKVOXyEAJGDjhsKdcxqsa4Tdq+wQU=";
            };

            postPatch = ''
               substituteInPlace build.sh \
               --replace-fail "-microarch:native" ""
               patchShebangs build.sh odinfmt.sh
               '';

            nativeBuildInputs = [
               pkgs.makeBinaryWrapper
            ];

            odin-override = pkgs.lib.mkDefault pkgs.odin;

            buildInputs = [
               self.odin-override
            ];

            buildPhase = ''
               runHook preBuild

               ./build.sh && ./odinfmt.sh

               runHook postBuild
               '';

            installPhase = ''
               runHook preInstall

               install -Dm755 ols odinfmt -t $out/bin/
               wrapProgram $out/bin/ols --set-default ODIN_ROOT ${self.odin-override}/share

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
