{
  description = "Flake environment for buildroot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          devShells.default =
            (pkgs.buildFHSEnv {
              name = "buildroot";
              targetPkgs =
                pkgs:
                (
                  with pkgs;
                  [
                    (lib.hiPrio gcc)
                    file
                    gnumake
                    ncurses.dev
                    pkg-config
                    unzip
                    wget
                    (libxcrypt.override {
                      enableHashes = "glibc";
                    })
                  ]
                  ++ pkgs.linux.nativeBuildInputs
                );
            }).env;
        };
      flake = {
      };
    };
}
