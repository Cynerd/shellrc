overlays: {
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cnf = config.programs.shellrc;
  zshEnable = config.programs.zsh.enable;
in {
  options.programs.shellrc = mkEnableOption "shellrc";

  config = mkMerge [
    {
      nixpkgs.overlays = overlays;
    }
    (mkIf cnf {
      # Disable default prompt as we have our own
      programs.bash.promptInit = "";
      programs.zsh.promptInit = ""; # Disable default prompt as we have our own

      programs.bash.interactiveShellInit = ''
        eval $(${pkgs.shellrc-bash}/bin/shellrc-bash)
      '';
      programs.zsh.interactiveShellInit = mkIf zshEnable ''
        eval $(${pkgs.shellrc-zsh}/bin/shellrc-zsh)
      '';
    })
  ];
}
