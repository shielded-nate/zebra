{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      helpers = import ../lib.nix {
        inherit inputs system;
      };

      inherit (helpers)
        checkCargoArtifacts
        commonArgs
        craneLib
        mkBinaryPackage
        pkgs
        src
        toolchain
        ;

      zebradPackage = mkBinaryPackage {
        name = "zebrad";
        cargoToml = ../../zebrad/Cargo.toml;
        cargoExtraArgs = "--locked -p zebrad --bin zebrad";
      };

      zebraCheckpointsPackage = mkBinaryPackage {
        name = "zebra-checkpoints";
        cargoToml = ../../zebra-utils/Cargo.toml;
        cargoExtraArgs = "--locked -p zebra-utils --features zebra-checkpoints --bin zebra-checkpoints";
      };

      searchIssueRefsPackage = mkBinaryPackage {
        name = "search-issue-refs";
        cargoToml = ../../zebra-utils/Cargo.toml;
        cargoExtraArgs = "--locked -p zebra-utils --features search-issue-refs --bin search-issue-refs";
      };

      blockTemplateToProposalPackage = mkBinaryPackage {
        name = "block-template-to-proposal";
        cargoToml = ../../zebra-utils/Cargo.toml;
        cargoExtraArgs = "--locked -p zebra-utils --bin block-template-to-proposal";
      };

      zebraBinariesPackage = pkgs.symlinkJoin {
        name = "zebra-binaries";
        paths = [
          zebradPackage
          zebraCheckpointsPackage
          searchIssueRefsPackage
          blockTemplateToProposalPackage
        ];
      };
    in
    {
      formatter = pkgs.nixfmt-rfc-style;

      packages = {
        zebrad = zebradPackage;
        zebra-checkpoints = zebraCheckpointsPackage;
        search-issue-refs = searchIssueRefsPackage;
        block-template-to-proposal = blockTemplateToProposalPackage;
        default = zebraBinariesPackage;
      };

      checks = {
        fmt = craneLib.cargoFmt {
          inherit src;
        };

        clippy = craneLib.cargoClippy (commonArgs // {
          cargoArtifacts = checkCargoArtifacts;
          cargoClippyExtraArgs = "--locked --workspace --all-targets -- -D warnings";
        });

        clippy-release = craneLib.cargoClippy (commonArgs // {
          cargoArtifacts = checkCargoArtifacts;
          cargoClippyExtraArgs = "--locked --workspace --all-targets --features default-release-binaries -- -D warnings";
        });

        clippy-tests = craneLib.cargoClippy (commonArgs // {
          cargoArtifacts = checkCargoArtifacts;
          cargoClippyExtraArgs = "--locked --workspace --all-targets --features 'default-release-binaries proptest-impl lightwalletd-grpc-tests zebra-checkpoints' -- -D warnings";
        });

        check = craneLib.cargoCheck (commonArgs // {
          cargoArtifacts = checkCargoArtifacts;
          cargoExtraArgs = "--locked --workspace --all-targets";
        });

        check-all-features = craneLib.cargoCheck (commonArgs // {
          cargoArtifacts = checkCargoArtifacts;
          cargoExtraArgs = "--locked --workspace --all-features --all-targets";
        });

        test = craneLib.cargoTest (commonArgs // {
          cargoArtifacts = checkCargoArtifacts;
          cargoExtraArgs = "--locked --workspace";
        });

        zebra-binaries = zebraBinariesPackage;
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
