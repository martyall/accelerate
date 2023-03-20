{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];

    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        hello-embedded =
          let
            embeddedPkgs = import nixpkgs {
              inherit system;
              crossSystem = nixpkgs.lib.systems.examples.aarch64-multiplatform;
              config.allowUnsupportedSystem = true;
            };
          in
            embeddedPkgs.callPackage ./default.nix { };
        pkgs = import nixpkgs { inherit system; };
        hello-native = pkgs.callPackage ./default.nix { };
      in
      {
        packages = {
          hello-embedded = hello-embedded;
          hello-native = hello-native;
          default = hello-embedded;
        };
        
        devShell = pkgs.mkShell {
          packages = [ pkgs.cargo pkgs.rustc pkgs.rustup ];
        };
      }
    );
}
