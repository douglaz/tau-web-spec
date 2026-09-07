{
  description = "tau-web wasm spikes devshell: stable Rust with the wasm32 target, wasm-bindgen, wasm-opt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ (import rust-overlay) ]; };
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ "wasm32-unknown-unknown" ];
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [ rustToolchain ] ++ (with pkgs; [ wasm-bindgen-cli binaryen websocat python3 ]);
          # ring compiles C for wasm via cc-rs; the nix cc-wrapper injects host hardening flags
          # clang rejects for wasm32, so cc-rs gets an unwrapped clang for that target.
          CC_wasm32_unknown_unknown = "${pkgs.llvmPackages.clang-unwrapped}/bin/clang";
          AR_wasm32_unknown_unknown = "${pkgs.llvmPackages.llvm}/bin/llvm-ar";
          shellHook = ''
            echo "wasm-spikes devshell · $(rustc --version) · $(wasm-bindgen --version)"
          '';
        };
      });
}
