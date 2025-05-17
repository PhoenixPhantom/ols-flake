# flake.nix
{
   inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
      flake-utils.url = "github:numtide/flake-utils";
      odinlang = {
         url = "git+file:///home/phoenix/Code/odin-flake";
         inputs = {
            nixpkgs.follows = "nixpkgs";
            flake-utils.follows = "flake-utils";
         };
      };
   };
   outputs = { self, nixpkgs, flake-utils, odinlang }:
      let
         system = "x86_64-linux";
         overlays = [ odinlang.overlays.default ];
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
               hash = "sha256-2Mzbld71I0j+lJ6PmuYe8qMIi6oS7u70u9w+5A23DbY=";
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
