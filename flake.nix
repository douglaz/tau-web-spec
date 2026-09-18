{
  # Dev shell for this specification: the Lean toolchain the formal companion needs
  # (ADR-0032) and the Python the document gates need.
  #
  # Lean comes from nixpkgs rather than elan so the version is pinned by flake.lock
  # and the binaries run on NixOS unpatched. Mathlib is not a dependency; if it ever
  # is, it must match this Lean version exactly (the Mathlib tag named `v<lean
  # version>`) or `lake` rebuilds it from source.
  description = "tau-web specification gates and Lean toolchain";

  # The revision provisiond-spec pinned on 2026-09-12: it has lean4 4.30.0, the
  # version tools/formal/lean-toolchain names, in the binary cache. Later
  # nixos-unstable revisions shipped a lean4 whose install step wrote to /usr/local
  # and had no cache entry.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/aff8a0b28396750446e5537a96461bc4facdb287";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.lean4        # lean, lake
            pkgs.python3      # tools/check_*.py
          ];
        };
      });

      # `nix flake check` runs the same gates CI does, the Lean build included.
      checks = forAll (pkgs: {
        # runCommandCC, not runCommand: lake compiles the gate executable's C output.
        gates = pkgs.runCommandCC "tau-web-gates"
          { nativeBuildInputs = [ pkgs.python3 pkgs.bash pkgs.lean4 ]; } ''
          export HOME="$TMPDIR"
          cp -r ${self} src && chmod -R u+w src && cd src
          bash tools/check-all.sh
          touch $out
        '';
      });
    };
}
