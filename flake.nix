{
  description = "Cynerd's shell configuration";

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    with flake-utils.lib;
      {
        overlays = {
          shellrc = final: prev: import ./pkgs.nix {pkgs = prev;};
          default = self.overlays.shellrc;
        };
        nixosModules = {
          shellrc = import ./nixos.nix [self.overlays.shellrc];
          default = self.nixosModules.shellrc;
        };
      }
      // eachDefaultSystem (system: let
        pkgs = nixpkgs.legacyPackages.${system};
        selfPkgs = filterPackages system (flattenTree (import ./pkgs.nix {inherit pkgs;}));
      in {
        packages = selfPkgs // {default = selfPkgs.shellrc-bash;};
        legacyPackages = pkgs.extend self.overlays.default;
        formatter = pkgs.alejandra;
      });
}
