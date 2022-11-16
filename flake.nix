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
      shellrc-generic = pkgs.stdenvNoCC.mkDerivation {
        name = "shellrc-profile";
        src = ./.;
        installPhase = ''
          mkdir -p "$out/etc/shellrc"
          cp -r ./shellrc.d/. "$out/etc/shellrc/"
        '';
      };
      shellrc-bashrc = pkgs.stdenvNoCC.mkDerivation {
        name = "shellrc-profile-bash";
        src = ./.;
        shellrc = shellrc-generic;
        installPhase = ''
          mkdir -p "$out/etc/bashrc.d"
          cp -r ./bashrc.d/. "$out/etc/bashrc.d/"
          cat >"$out/etc/bashrc.d/shellrc" <<EOF
          for sh in $shellrc/etc/shellrc/*; do
            [ -r "\$sh" ] && . "\$sh"
          done
          EOF
        '';
      };
      shellrc-zshrc = pkgs.stdenvNoCC.mkDerivation {
        name = "shellrc-profile-zsh";
        src = ./.;
        shellrc = shellrc-generic;
        installPhase = ''
          mkdir -p "$out/etc/zshrc.d"
          cp -r ./zshrc.d/. "$out/etc/zshrc.d/"
          cat >"$out/etc/zshrc.d/shellrc" <<EOF
          for sh in $shellrc/etc/shellrc/*; do
            [ -r "\$sh" ] && . "\$sh"
          done
          EOF
        '';
      };
      shellrc-completion = pkgs.stdenvNoCC.mkDerivation {
        name = "shellrc-completion";
        src = ./.;
        nativeBuildInputs = [ pkgs.installShellFiles ];
        installPhase = ''
          for comp in bash-completion/*; do
            installShellCompletion --bash --name "''${comp##*/}.bash" "$comp"
          done
          for comp in zsh-completion/*; do
            installShellCompletion --zsh --name "''${comp##*/}" "$comp"
          done
        '';
      };
      shellrc = pkgs.symlinkJoin {
        name = "shellrc";
        paths = [ shellrc-bashrc shellrc-zshrc shellrc-completion ];
      };
      default = shellrc;
    };

  in {

    overlays = {
      shellrc = final: prev: packages prev;
      default = self.overlays.shellrc;
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
