{
  description = "My cute Rust crate!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    naersk.url = "github:nmattia/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, naersk }:
    let
      cargoToml = (builtins.fromTOML (builtins.readFile ./Cargo.toml));
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in
    {
      overlay = final: prev: {
        "${cargoToml.package.name}" = final.callPackage ./. { inherit naersk; };
      };

    #  x86_64-linux = {
    #    type = "realisation";
    #    system = "x86_64-linux";
    #    outputs = [ "out" "debug" ];
    #    defaultOutput = "out";
    #    buildInputs = [ nixpkgs.clang ];
    #    shellHook = ''
    #      export CC=clang
    #    '';
    #    packages = import ./default.nix {
    #      system = "x86_64-linux";
    #      pkgs = nixpkgs;
    #    };
    #  };
    #  aarch64-linux = {
    #    type = "realisation";
    #    system = "aarch64-linux";
    #    outputs = [ "out" "debug" ];
    #    defaultOutput = "out";
    #    crossSystem = "x86_64-linux";
    #    buildPackages = [ nixpkgs.cross.aarch64-linux.gcc ];
    #    nativeBuildInputs = [ nixpkgs.autoconf nixpkgs.automake nixpkgs.libtool ];
    #    packages = import ./default.nix {
    #      system = "aarch64-linux";
    #      pkgs = nixpkgs;
    #    };
    #  };
    #};



      packages =
        let
          pkgs = import nixpkgs {
            system = "aarch64-linux";
            overlays = [
              self.overlay
            ];
          };
        in
        {
          "${cargoToml.package.name}" = pkgs."${cargoToml.package.name}";
        };


      defaultPackage = forAllSystems (system: (import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      })."${cargoToml.package.name}");

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlay
            ];
          };
        in
        {
          format = pkgs.runCommand "check-format"
            {
              buildInputs = with pkgs; [ rustfmt cargo ];
            } ''
            ${pkgs.rustfmt}/bin/cargo-fmt fmt --manifest-path ${./.}/Cargo.toml -- --check
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${./.}
            touch $out # it worked!
          '';
          "${cargoToml.package.name}" = pkgs."${cargoToml.package.name}";
        });
      devShell = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlay ];
          };
        in
        pkgs.mkShell {
          inputsFrom = with pkgs; [
            pkgs."${cargoToml.package.name}"
          ];
          buildInputs = with pkgs; [
            rustfmt
            nixpkgs-fmt
          ];
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        });
    };
}

