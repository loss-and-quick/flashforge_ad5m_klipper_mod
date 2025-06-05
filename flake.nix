{
  description = "Klipper development shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      devShells.x86_64-linux.default = pkgs.buildFHSEnv {
        name = "klippermod-dev-shell-fhs";

        targetPkgs = ps: with ps; [
          bash
          git
          gcc
          binutils
          glibc
          gnumake
          unzip
          file
          python3
          bc
          xz
          bzip2
          cpio
          wget
        ];

        runScript = "bash";
      };
    };
}
