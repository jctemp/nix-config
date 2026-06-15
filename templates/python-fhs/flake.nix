{
  description = "Python FHS environment (CUDA-capable, for pip/uv wheels)";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      fhs = pkgs.buildFHSEnv {
        name = "python-fhs";
        targetPkgs =
          p: with p; [
            uv
            ruff
            ty
            python3
            python3Packages.ipython

            # Runtime libs commonly needed by CUDA / binary wheels
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            stdenv.cc.cc.lib
            zlib
            libGL
            glib
          ];
        runScript = "bash";
      };
    in
    {
      devShells.${system}.default = fhs.env;
    };
}
