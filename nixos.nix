overlays: {
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cnf = config.programs.shellrc;
  zshEnable = config.programs.zsh.enable;

  # Source all files in an appropriate shell directory in every profile
  shellInit = dir: ''
    for p in $NIX_PROFILES; do
      for file in $p/etc/${dir}/*; do
        [ -f "$file" ] || continue
        . "$file"
      done
    done
  '';
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

  config = mkMerge [
    {
      nixpkgs.overlays = overlays;

      programs.bash.interactiveShellInit = shellInit "bashrc.d";
      programs.zsh.interactiveShellInit = mkIf zshEnable (shellInit "zshrc.d");
    }
    (mkIf cnf.enable {
      environment.systemPackages =
        [pkgs.shellrc-bash]
        ++ optional cnf.desktop pkgs.shellrc-desktop
        ++ optional zshEnable pkgs.shellrc-zsh;

      # Disable default prompt as we have our own
      programs.bash.promptInit = "";
      programs.zsh.promptInit = ""; # Disable default prompt as we have our own
    })
  ];
}
