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
        eval $(/run/current-system/sw/bin/shellrc-bash)
      '';
      programs.zsh.interactiveShellInit = mkIf zshEnable ''
        eval $(/run/current-system/sw/bin/shellrc-zsh)
      '';

      environment.systemPackages = with pkgs; [shellrc-bash] ++ (optional zshEnable shellrc-zsh);
    })
  ];
}
