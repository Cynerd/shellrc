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

      environment.pathsToLink = ["/etc/shellrc.d" "/etc/bashrc.d"] ++ optional zshEnable "/etc/zshrc.d";
      programs.bash.interactiveShellInit = ''
        # Load files provided by packages
        for p in $NIX_PROFILES; do
          [ -e $p/etc/bashrc.d ] || continue
          for file in $p/etc/bashrc.d/*; do
            [ -f "$file" ] || continue
            . "$file"
          done
        done
      '';
      programs.zsh.interactiveShellInit = mkIf zshEnable ''
        # Load files provided by packages
        for p in ''${=NIX_PROFILES}; do
          [ -e $p/etc/zshrc.d ] || continue
          for file in $p/etc/zshrc.d/*; do
            [ -f "$file" ] || continue
            . "$file"
          done
        done
      '';
    }
    (mkIf cnf.enable {
      environment.systemPackages =
        [pkgs.shellrc-generic pkgs.shellrc-bash]
        ++ optional cnf.desktop pkgs.shellrc-desktop
        ++ optional zshEnable pkgs.shellrc-zsh;

      # Disable default prompt as we have our own
      programs.bash.promptInit = "";
      programs.zsh.promptInit = ""; # Disable default prompt as we have our own
    })
  ];
}
