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

      zebradPackage = mkBinaryPackage {
        name = "zebrad";
        cargoExtraArgs = "--locked -p zebrad --bin zebrad";
      };

      zebraCheckpointsPackage = mkBinaryPackage {
        name = "zebra-checkpoints";
        cargoExtraArgs = "--locked -p zebra-utils --features zebra-checkpoints --bin zebra-checkpoints";
      };

      searchIssueRefsPackage = mkBinaryPackage {
        name = "search-issue-refs";
        cargoExtraArgs = "--locked -p zebra-utils --features search-issue-refs --bin search-issue-refs";
      };

      blockTemplateToProposalPackage = mkBinaryPackage {
        name = "block-template-to-proposal";
        cargoExtraArgs = "--locked -p zebra-utils --bin block-template-to-proposal";
      };

      zebraBinaries = pkgs.symlinkJoin {
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
        default = zebraBinaries;
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

        zebra-binaries = zebraBinaries;
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
