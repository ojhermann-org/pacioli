{
  description = "Pacioli — verified accounting mechanics (Lean 4) paired with curated judgment (OKF)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, git-hooks, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Fast, hermetic checks: Nix, markdown, hygiene, and a Lean-specific guard
      # that no `sorry`/`admit` lands. `lake build` is NOT run here — elan/Lake
      # need network the flake-check sandbox denies; the full Lean compile runs in
      # pre-push and in a dedicated CI job instead.
      hooksFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          noSorry = pkgs.writeShellApplication {
            name = "no-sorry";
            runtimeInputs = [ pkgs.gnugrep ];
            text = ''
              status=0
              for f in "$@"; do
                if grep -nE '\b(sorry|admit)\b' "$f"; then
                  echo "error: $f contains 'sorry' or 'admit' — proofs must be complete"
                  status=1
                fi
              done
              exit "$status"
            '';
          };
          # The full Lean compile, run as a pre-push gate (not in flake check —
          # elan/Lake need network the check sandbox denies). elan resolves the
          # toolchain from `lean-toolchain` and puts `lake` on PATH; `cache get`
          # pulls mathlib's prebuilt oleans so the push isn't a from-scratch
          # build. Both libraries are named so `Examples` is compiled too.
          lakeBuild = pkgs.writeShellApplication {
            name = "lake-build";
            runtimeInputs = [ pkgs.elan ];
            text = ''
              lake exe cache get
              lake build Pacioli Examples
            '';
          };
        in
        git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            check-merge-conflicts.enable = true;
            check-added-large-files.enable = true;
            trim-trailing-whitespace.enable = true;
            end-of-file-fixer.enable = true;
            check-yaml.enable = true;
            markdownlint = {
              enable = true;
              settings.configuration = {
                MD013 = {
                  # line length — prose wraps at 80 for terminal review; tables
                  # and code blocks (ASCII trees) can't reflow, so exempt them.
                  line_length = 80;
                  tables = false;
                  code_blocks = false;
                };
                MD033 = false; # inline HTML
                MD036 = false; # emphasis-as-heading — prose uses emphasis stylistically
                MD040 = false; # fenced code language not required (ASCII trees)
                MD025.front_matter_title = ""; # don't treat YAML front-matter title as an H1
              };
            };
            no-sorry = {
              enable = true;
              name = "no sorry or admit in Lean sources";
              entry = "${noSorry}/bin/no-sorry";
              files = "\\.lean$";
              language = "system";
              pass_filenames = true;
            };
            lake-build = {
              enable = true;
              name = "lake build (full Lean compile)";
              entry = "${lakeBuild}/bin/lake-build";
              language = "system";
              stages = [ "pre-push" ];
              pass_filenames = false;
              always_run = true;
            };
          };
        };
    in
    {
      checks = forAllSystems (system: {
        pre-commit = hooksFor system;
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hooks = hooksFor system;
        in
        {
          default = pkgs.mkShell {
            inherit (hooks) shellHook;
            buildInputs = hooks.enabledPackages ++ [ pkgs.elan ];
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellApplication {
          name = "fmt";
          runtimeInputs = [
            pkgs.nixfmt
            pkgs.findutils
          ];
          text = ''
            find . -name '*.nix' -not -path './.git/*' -print0 | xargs -0 nixfmt
          '';
        }
      );
    };
}
