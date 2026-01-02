# ~/.config/nix/pkgs/claude-code.nix
# Nix derivation for Anthropic's Claude Code CLI tool

{ lib
, stdenv
, fetchurl
, nodejs_22
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "claude-code";
  version = "2.0.76";

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    sha256 = "fca39936ff8e9310c8e4c6833d6455341b92acd92317785f0f773ee74391b9d9";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs_22 ];

  sourceRoot = "package";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/claude-code
    cp -r . $out/lib/claude-code/

    mkdir -p $out/bin
    makeWrapper ${nodejs_22}/bin/node $out/bin/claude \
      --add-flags "$out/lib/claude-code/cli.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - Anthropic's AI coding assistant CLI";
    homepage = "https://claude.ai/code";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "claude";
  };
}
