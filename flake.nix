# Build, testing, and developments specification for the `nix` environment
#
# # Prerequisites
#
# - Install the `nix` package manager: https://nixos.org/download/
# - Configure `flake` support: https://nixos.wiki/wiki/Flakes
#
# # Build
#
# ```
# $ nix build --print-build-logs
# ```
#
# This produces all build artifacts within the directly linked to `./result`.
#
# The book directory is the root of the book source, so to view the rendered book:
#
# ```
# $ xdg-open ./result/book/book/index.html
# ```
#
# # Development
#
# ```
# $ nix develop
# ```
#
# This starts a new subshell with a development environment, such as
# `cargo`, `clang`, `protoc`, etc... So `cargo test` for example should
# work.
{
  description = "The zebra zcash node binaries and crates with Crosslink protocol features";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: Switch to `flake-parts` lib for cleaner organization.
    flake-utils.url = "github:numtide/flake-utils";

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
  };

  outputs =
    inputs:
    import ./flake inputs rec {
      project-name = "zebra-crosslink";
      src-root = ./.;
      rust-toolchain-toml = ./rust-toolchain.toml;
    };
}
