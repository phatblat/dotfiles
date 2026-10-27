// flywheel-ledger.ts — shared ledger append for the omp flywheel extensions.
// Copyright: Ben Chatelain. MIT
//
// Mirrors `state_dir()` in scripts/flywheel-record.py: $XDG_STATE_HOME (with a
// leading `~` expanded) or ~/.local/state, then flywheel/dotfiles/.
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

/** Append one JSON record to a ledger; recording must never break the session. */
export function appendLedger(name: "outcomes.jsonl" | "scaffolds.jsonl", record: object): void {
  try {
    const ledger = ledgerPath(name);
    fs.mkdirSync(path.dirname(ledger), { recursive: true });
    fs.appendFileSync(ledger, `${JSON.stringify(record)}\n`, "utf8");
  } catch {}
}
