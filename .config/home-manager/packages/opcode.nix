# Nix package for opcode - GUI app and Toolkit for Claude Code
# https://github.com/winfunc/opcode
{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, bun
, nodejs
, pkg-config
, openssl
, makeWrapper
# Linux dependencies
, webkitgtk_4_1 ? null
, gtk3 ? null
, cairo ? null
, gdk-pixbuf ? null
, glib ? null
, dbus ? null
, librsvg ? null
, libsoup_3 ? null
, libayatana-appindicator ? null
# macOS dependencies - make them optional
, darwin ? null
, Security ? null
, CoreServices ? null
, SystemConfiguration ? null
, AppKit ? null
, WebKit ? null
}:

let
  version = "0.2.0";
  pname = "opcode";

  # Frontend assets built with bun
  frontend = stdenv.mkDerivation {
    pname = "${pname}-frontend";
    inherit version;

    src = fetchFromGitHub {
      owner = "winfunc";
      repo = "opcode";
      rev = "v${version}";
      hash = "sha256-sTDOevSbfvsxcdf6yxAqtDfQL7jmSvvr1cFH32upysA=";
    };

    nativeBuildInputs = [ bun nodejs ];

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      bun install --frozen-lockfile
      bun run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r dist $out/

      runHook postInstall
    '';
  };

in
rustPlatform.buildRustPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "winfunc";
    repo = "opcode";
    rev = "v${version}";
    hash = "sha256-sTDOevSbfvsxcdf6yxAqtDfQL7jmSvvr1cFH32upysA=";
  };

  # Don't set sourceRoot yet - we need to copy frontend assets first
  postUnpack = ''
    # Copy frontend assets into the source tree before it becomes read-only
    cp -r ${frontend}/dist source/dist
    # Now we can change to the Tauri source directory
    sourceRoot=source/src-tauri
  '';

  cargoHash = "sha256-z3sl62L4rNbg0iVEsX3adPgqRLwk5k9hdcvqiRhG52E="; # Will be filled after first build attempt

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    openssl
  ] ++ lib.optionals stdenv.isLinux [
    webkitgtk_4_1
    gtk3
    cairo
    gdk-pixbuf
    glib
    dbus
    librsvg
    libsoup_3
    libayatana-appindicator
  ] ++ lib.optionals stdenv.isDarwin [
    Security
    CoreServices
    SystemConfiguration
    AppKit
    WebKit
  ];

  # Enable required Tauri features
  buildFeatures = [ "custom-protocol" ];

  # Tauri requires network access during build to fetch some assets
  __darwinAllowLocalNetworking = true;

  # TODO: rustPlatform.buildRustPackage builds the CLI binary only.
  # Tauri app bundles (.app) require `cargo tauri build` which isn't run here.
  # The CLI binary will be installed to $out/bin/opcode.
  # postInstall = lib.optionalString stdenv.isDarwin ''
  #   mkdir -p $out/Applications
  #   cp -r target/release/bundle/macos/opcode.app $out/Applications/
  # '';

  meta = with lib; {
    description = "A powerful GUI app and Toolkit for Claude Code";
    longDescription = ''
      opcode is a powerful desktop application that transforms how you interact with Claude Code.
      Built with Tauri 2, it provides a beautiful GUI for managing your Claude Code sessions,
      creating custom agents, tracking usage, and much more.

      Features:
      - Visual Project Browser
      - Session History Management
      - Custom AI Agents
      - Background Execution
      - Usage Analytics Dashboard
      - MCP Server Management
      - Timeline & Checkpoints
      - CLAUDE.md Management
    '';
    homepage = "https://github.com/winfunc/opcode";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ ]; # Add your name here
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "opcode";
  };
}
