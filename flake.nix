{
  description = "Cynerd's shell configuration";

  outputs = { self, flake-utils, nixpkgs }: 
  let

    loadrc = dir: ''
      for sh in ${dir}/*; do
          [ -r "$sh" ] && . "$sh"
      done
      '';
    commonrc = loadrc ./shellrc.d;
    desktoprc = loadrc ./shellrc-desktop.d;
    bashrc = loadrc ./bashrc.d;
    zshrc = loadrc ./zshrc.d;

    packages = pkgs: rec {
      shellrc-completion = pkgs.stdenv.mkDerivation {
        name = "shellrc-completion";
        src = ./.;
        nativeBuildInputs = [ pkgs.installShellFiles ];
        installPhase = ''
          for comp in bash-completion/*; do
            installShellCompletion --bash --name "$${comp##*/}.bash" "$comp"
          done
          for comp in zsh-completion/*; do
            installShellCompletion --zsh --name "$${comp##*/}" "$comp"
          done
        '';
      };
      default = shellrc-completion;
    };

  in {

    overlays = {
      shellrc = final: prev: packages prev;
      default = self.overlay.shellrc;
    };

    nixosModules = {
      shellrc = { config, lib, pkgs, ... }: with lib; {
        options = {
          programs.shellrc = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "If shellrc should be enabled.";
            };
            desktop = mkOption {
              type = types.bool;
              default = false;
              description = "If shellrc's desktop specific files should be used.";
            };
          };
        };

        config = mkIf config.programs.shellrc.enable {

          environment.interactiveShellInit = commonrc + optionalString config.programs.shellrc.desktop desktoprc;

          programs.bash.interactiveShellInit = bashrc;
          programs.bash.promptInit = ""; # Disable default prompt as we have our own

          programs.zsh.interactiveShellInit = mkIf config.programs.zsh.enable zshrc;
          programs.zsh.promptInit = ""; # Disable default prompt as we have our own

          nixpkgs.overlays = [ self.overlays.shellrc ];
          environment.systemPackages = [ pkgs.shellrc-completion ];

        };
      };
      default = self.nixosModules.shellrc;
    };

  } // (flake-utils.lib.eachDefaultSystem (system: {
    packages = packages nixpkgs.legacyPackages.${system};
  }));

}
