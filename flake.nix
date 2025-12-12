{
  inputs = {
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
  };
  description = "Output a function nix2zon which you can use in your flake";
  outputs = { self, nixpkgs-lib }:
  let
    toZon = import ./toZon.nix {
      inherit (nixpkgs-lib) lib;
    };
  in {
    lib = {
      toZon = toZon {};
      generators.toZon = toZon; 
      # use this helper in `preBuild` hook to generate build.zig.zon with symlinked dependencies
      genBuildZig = { depsDirName ? "zigDeps", linkFarm }: buildAttr: ''
        ln -s ${linkFarm depsDirName buildAttr.dependencies} ./${depsDirName} -f
        >build.zig.zon cat <<< '${toZon {} (buildAttr // {
          dependencies = builtins.mapAttrs (name: _: {
            path = "\\./${depsDirName}/${name}/";
          }) buildAttr.dependencies;
        })}'
      '';
    };
    # run with `nix-unit --flake .#tests`
    # **nix flake check would have required glue code or extra dependencies
    # in order to work because of `system` which do not seems a good
    # trade off for testing pure nix**
    tests = import ./tests.nix { inherit (self.lib) toZon generators; };
  };
}
