// flywheel-ledger.ts — shared ledger append for the omp flywheel extensions.
// Copyright: Ben Chatelain. MIT
//
// Mirrors `state_dir()` in scripts/flywheel-record.py: $XDG_STATE_HOME (with a
// leading `~` expanded) or ~/.local/state, then flywheel/dotfiles/.
import { createHash } from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

function expandHome(value: string): string {
  if (value === "~") return os.homedir();
  if (value.startsWith("~/")) return path.join(os.homedir(), value.slice(2));
  return value;
}

export function ledgerPath(name: "outcomes.jsonl" | "scaffolds.jsonl"): string {
  const xdg = process.env.XDG_STATE_HOME;
  const base = xdg ? expandHome(xdg) : path.join(os.homedir(), ".local", "state");
  return path.join(base, "flywheel", "dotfiles", name);
}

// Mirrors sanitize_text/opaque_session_id in scripts/flywheel-record.py.
const MAX_TEXT_LEN = 80;
const SECRET_RE =
  /(AKIA[0-9A-Z]{16}|(?<![A-Za-z0-9_-])sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|glpat-[A-Za-z0-9_-]{20,}|xox[bpoas]-[A-Za-z0-9-]+|-----BEGIN [A-Z ]*PRIVATE KEY-----)/gi;
const OPAQUE_ID_RE = /^[0-9A-Za-z-]{8,64}$/;

/** One line, secret-shaped tokens redacted, at most 80 characters. */
export function sanitizeText(text: string): string {
  const single = text.split(/\s+/).filter(Boolean).join(" ");
  return single.replace(SECRET_RE, "[REDACTED]").slice(0, MAX_TEXT_LEN);
}

/** Harness session IDs pass through; anything else is hashed. */
export function opaqueSessionId(raw: string): string {
  const clean = raw.trim();
  if (!clean) return "unknown";
  if (OPAQUE_ID_RE.test(clean)) return clean;
  return createHash("sha256").update(clean, "utf8").digest("hex").slice(0, 12);
}

/** Append one JSON record to a ledger; recording must never break the session. */
export function appendLedger(name: "outcomes.jsonl" | "scaffolds.jsonl", record: object): void {
  try {
    const ledger = ledgerPath(name);
    fs.mkdirSync(path.dirname(ledger), { recursive: true });
    fs.appendFileSync(ledger, `${JSON.stringify(record)}\n`, "utf8");
  } catch {}
}
