{
  inputs = {
    #nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  nixConfig = {
    # Useful as a build cache, but let's not bother with it for now
    #extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    #extra-substituters = "https://devenv.cachix.org";
  };

  outputs = { self, nixpkgs, devenv, systems, ... } @ inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });

      devShells = forEachSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  languages.python = {
                    enable = true;
                    uv = {
                      enable = true;
                      sync.enable = true;
                    };
                  };
                  packages = [ pkgs.gcc-unwrapped ];
                  env.LD_LIBRARY_PATH = "${pkgs.gcc-unwrapped.lib}/lib64";
                  pre-commit.hooks = {
                    clean-notebook = {
                      enable = true;
                      name = "Clean Jupyter notebook files.";
                      entry = "uv run --with jupyter jupyter nbconvert --ClearOutputPreprocessor.enabled=True --ClearMetadataPreprocessor.enabled=True --to=notebook --inplace --log-level=ERROR";
                      files = "\\.ipynb$";
                    };
                    nixpkgs-fmt.enable = true;
                    ruff = {
                      enable = true;
                      files = "\\.(py|ipynb)$";
                      types = [ "file" ];
                    };
                    ruff-format = {
                      enable = true;
                      files = "\\.(py|ipynb)$";
                      types = [ "file" ];
                    };
                  };
                }
              ];
            };
          });
    };
}
