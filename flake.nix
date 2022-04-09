{
  description = "Cynerd's shell configuration";

  outputs = { self, nixpkgs }: {

    nixosModule = { config, lib, pkgs, ... }:
    with lib;
    let
      zsh-completion = pkgs.stdenv.mkDerivation rec {
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
    in {

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
        environment.interactiveShellInit = ''
            for sh in ${./shellrc.d}/*; do
                [ -r "$sh" ] && . "$sh"
            done
          '' + optionalString config.programs.shellrc.desktop ''
            for sh in ${./shellrc-desktop.d}/*; do
                [ -r "$sh" ] && . "$sh"
            done
          '';

        programs.bash.interactiveShellInit = ''
            for sh in ${./bashrc.d}/*; do
                [ -r "$sh" ] && . "$sh"
            done
          '';
        programs.bash.promptInit = ""; # Disable default prompt as we have our own

        programs.zsh.interactiveShellInit = mkIf config.programs.zsh.enable ''
            for sh in ${./zshrc.d}/*; do
                [ -r "$sh" ] && . "$sh"
            done
          '';
        programs.zsh.promptInit = ""; # Disable default prompt as we have our own

        environment.systemPackages = [
          zsh-completion
        ];

      };

    };

  };
}
