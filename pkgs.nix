{pkgs}: let
  shellrcPkgs = {
    shellrc-generic = pkgs.stdenvNoCC.mkDerivation {
      name = "shellrc-generic";
      src = ./.;
      installPhase = ''
        mkdir -p "$out/etc/shellrc.d"
        cp -r ./shellrc.d/. "$out/etc/shellrc.d/"
      '';
    };
    shellrc-desktop = pkgs.stdenvNoCC.mkDerivation {
      name = "shellrc-desktop";
      src = ./.;
      installPhase = ''
        mkdir -p "$out/etc/shellrc.d"
        cp -r ./shellrc-desktop.d/. "$out/etc/shellrc.d/"
      '';
    };
    shellrc-bash = pkgs.stdenvNoCC.mkDerivation {
      name = "shellrc-bash";
      src = ./.;
      propagatedBuildInputs = [shellrcPkgs.shellrc-generic];
      installPhase = ''
        mkdir -p "$out/etc/bashrc.d"
        cp -r ./bashrc.d/. "$out/etc/bashrc.d/"
        cat >"$out/etc/bashrc.d/shellrc" <<EOF
        # Load ShellRC files
        for p in $NIX_PROFILES; do
          for sh in $p/etc/shellrc.d/*; do
            [ -r "\$sh" ] && . "\$sh"
          done
        done
        EOF
        for comp in bash-completion/*; do
          installShellCompletion --bash --name "''${comp##*/}.bash" "$comp"
        done
      '';
    };
    shellrc-zsh = pkgs.stdenvNoCC.mkDerivation {
      name = "shellrc-zsh";
      src = ./.;
      propagatedBuildInputs = [shellrcPkgs.shellrc-generic];
      installPhase = ''
        mkdir -p "$out/etc/zshrc.d"
        cp -r ./zshrc.d/. "$out/etc/zshrc.d/"
        cat >"$out/etc/zshrc.d/shellrc" <<EOF
        # Load ShellRC files
        for p in $NIX_PROFILES; do
          for sh in $p/etc/shellrc.d/*; do
            [ -r "\$sh" ] && . "\$sh"
          done
        done
        EOF
        for comp in zsh-completion/*; do
          installShellCompletion --zsh --name "''${comp##*/}" "$comp"
        done
      '';
    };
  };
in
  shellrcPkgs
