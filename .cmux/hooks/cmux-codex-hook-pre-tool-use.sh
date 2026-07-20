#!/bin/sh
cmux_cli="${CMUX_BUNDLED_CLI_PATH:-}"
if [ -z "$cmux_cli" ] || [ ! -x "$cmux_cli" ]; then cmux_cli="$(command -v cmux 2>/dev/null || true)"; fi
agent_pid="${CMUX_CODEX_PID:-${PPID:-}}"
if [ -n "$CMUX_SURFACE_ID" ] && [ "$CMUX_CODEX_HOOKS_DISABLED" != "1" ] && [ -n "$cmux_cli" ]; then
  payload="$(mktemp "${TMPDIR:-/tmp}/cmux-codex-hook.XXXXXX" 2>/dev/null || mktemp -t cmux-codex-hook 2>/dev/null)" || {
    echo '{}'
    exit 0
  }
  cat >"$payload" || true
  if [ -n "${CMUX_SOCKET_PATH:-}" ]; then CMUX_CODEX_PID="$agent_pid" nohup sh -c 'payload="$1"; shift; "$@" <"$payload" >/dev/null 2>&1 & child="$!"; ( sleep 30; kill "$child" 2>/dev/null || true ) & watchdog="$!"; wait "$child" 2>/dev/null || true; kill "$watchdog" 2>/dev/null || true; rm -f "$payload"' cmux-codex-hook "$payload" "$cmux_cli" --socket "$CMUX_SOCKET_PATH" hooks codex pre-tool-use >/dev/null 2>&1 & else CMUX_CODEX_PID="$agent_pid" nohup sh -c 'payload="$1"; shift; "$@" <"$payload" >/dev/null 2>&1 & child="$!"; ( sleep 30; kill "$child" 2>/dev/null || true ) & watchdog="$!"; wait "$child" 2>/dev/null || true; kill "$watchdog" 2>/dev/null || true; rm -f "$payload"' cmux-codex-hook "$payload" "$cmux_cli" hooks codex pre-tool-use >/dev/null 2>&1 & fi
  echo '{}'
else echo '{}'; fi
