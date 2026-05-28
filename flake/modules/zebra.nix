{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      helpers = import ../lib.nix {
        inherit inputs system;
      };

      inherit (helpers)
        cargoArtifacts
        commonArgs
        craneLib
        mkBinaryPackage
        pkgs
        src
        toolchain
        ;
    in
    {
      formatter = pkgs.nixfmt-rfc-style;

      packages = rec {
        zebrad = mkBinaryPackage {
          name = "zebrad";
          cargoExtraArgs = "--locked -p zebrad --bin zebrad";
        };

        zebra-checkpoints = mkBinaryPackage {
          name = "zebra-checkpoints";
          cargoExtraArgs = "--locked -p zebra-utils --features zebra-checkpoints --bin zebra-checkpoints";
        };

        search-issue-refs = mkBinaryPackage {
          name = "search-issue-refs";
          cargoExtraArgs = "--locked -p zebra-utils --features search-issue-refs --bin search-issue-refs";
        };

        block-template-to-proposal = mkBinaryPackage {
          name = "block-template-to-proposal";
          cargoExtraArgs = "--locked -p zebra-utils --bin block-template-to-proposal";
        };

        default = pkgs.symlinkJoin {
          name = "zebra-binaries";
          paths = [
            zebrad
            zebra-checkpoints
            search-issue-refs
            block-template-to-proposal
          ];
        };
      };

      checks = rec {
        fmt = craneLib.cargoFmt {
          inherit src;
        };

        clippy = craneLib.cargoClippy (commonArgs // {
          inherit cargoArtifacts;
          cargoClippyExtraArgs = "--locked --workspace --all-features --all-targets -- -D warnings";
        });

        check = craneLib.cargoCheck (commonArgs // {
          inherit cargoArtifacts;
          cargoExtraArgs = "--locked --workspace --all-features --all-targets";
        });

        test = craneLib.cargoTest (commonArgs // {
          inherit cargoArtifacts;
          cargoExtraArgs = "--locked --workspace";
        });

        zebra-binaries = packages.default;
      };

      devShells.default = pkgs.mkShell {
        packages = [
          toolchain
          pkgs.cargo-hack
          pkgs.cargo-nextest
          pkgs.clang
          pkgs.nixfmt-rfc-style
          pkgs.pkg-config
          pkgs.protobuf
          pkgs.rust-analyzer
        ];

        buildInputs = [
          pkgs.llvmPackages.libclang
          pkgs.rocksdb
        ];

        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        PROTOC = "${pkgs.protobuf}/bin/protoc";
        ROCKSDB_LIB_DIR = "${pkgs.rocksdb}/lib";
      };
    };
}
