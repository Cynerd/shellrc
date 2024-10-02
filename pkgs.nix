{pkgs}: let
  shellrcPkgs = {
    shellrc-bash = pkgs.stdenvNoCC.mkDerivation {
      name = "shellrc-bash";
      src = ./.;
      nativeBuildInputs = [pkgs.installShellFiles];
      installPhase = ''
        mkdir -p "$out/bin"
        cat >"$out/bin/shellrc-bash" <<"EOF"
        #!/usr/bin/env bash
        for file in ${./bashrc.d}/* ${./shellrc.d}/*; do
          echo "source $file;"
        done
        EOF
        chmod +x "$out/bin/shellrc-bash"
        for comp in bash-completion/*; do
          installShellCompletion --bash --name "''${comp##*/}.bash" "$comp"
        done
      '';
    };
    shellrc-zsh = pkgs.stdenvNoCC.mkDerivation {
      name = "shellrc-zsh";
      src = ./.;
      nativeBuildInputs = [pkgs.installShellFiles];
      installPhase = ''
        mkdir -p "$out/bin"
        cat >"$out/bin/shellrc-zsh" <<"EOF"
        #!/usr/bin/env zsh
        for file in ${./zshrc.d}/* ${./shellrc.d}/*; do
          echo "source $file;"
        done
        EOF
        chmod +x "$out/bin/shellrc-zsh"
        for comp in zsh-completion/*; do
          installShellCompletion --zsh --name "''${comp##*/}" "$comp"
        done
      '';
    };
    shellrc-user-setup = pkgs.writeScriptBin "shellrc-user-setup" ''
      #!/usr/bin/env bash
      cmdbash='eval $(shellrc-bash)'
      cmdzsh='eval $(shellrc-zsh)'
      if command -v shellrc-bash 2>/dev/null >&2 \
          && ! grep -qxF "$cmdbash" ~/.bashrc 2>/dev/null; then
        echo "$cmdbash" >>~/.bashrc
      fi
      if command -v shellrc-zsh 2>/dev/null >&2 \
          && ! grep -qxF "$cmdzsh" ~/.zshrc 2>/dev/null; then
          echo "$cmdzsh" >>~/.zshrc
      fi
    '';
  };
in
  shellrcPkgs
