{ inputs, system }:
let
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.rust-overlay.overlays.default
    ];
  };

  toolchain = pkgs.rust-bin.fromRustupToolchainFile ../rust-toolchain.toml;
  craneLib = (inputs.crane.mkLib pkgs).overrideToolchain (_: toolchain);
  src = inputs.self;

  commonArgs = {
    inherit src;
    strictDeps = true;
    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.protobuf
    ];
    buildInputs = [
      pkgs.llvmPackages.libclang
      pkgs.rocksdb
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.libiconv
    ];
    LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
    PROTOC = "${pkgs.protobuf}/bin/protoc";
    ROCKSDB_LIB_DIR = "${pkgs.rocksdb}/lib";
  };

  packageCargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
    cargoExtraArgs = "--locked --workspace";
  });

  checkCargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
    cargoExtraArgs = "--locked --workspace --all-features --all-targets";
  });
in
{
  inherit pkgs toolchain craneLib src commonArgs packageCargoArtifacts checkCargoArtifacts;

  mkBinaryPackage =
    {
      name,
      cargoToml,
      cargoExtraArgs,
      mainProgram ? name,
    }:
    let
      crateInfo = craneLib.crateNameFromCargoToml { inherit cargoToml; };
    in
    craneLib.buildPackage (commonArgs // {
      pname = name;
      version = crateInfo.version;
      cargoArtifacts = packageCargoArtifacts;
      inherit cargoExtraArgs;
      doCheck = false;
      meta.mainProgram = mainProgram;
    });
}
