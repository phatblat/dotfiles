// Copyright: Ben Chatelain. Apache 2.0.
//
// Routes omp tool calls through the shared harness guard so omp enforces the
// same protected paths, blocked command categories, and secret-content rules
// as every other harness. Hand-written on purpose: ~/.omp/agent is tracked
// manually, not emitted by scripts/agent-harnesses.py.

import { execFileSync } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";

type GuardResult = { decision: "allow" | "warn" | "deny"; reason?: string };

// execFileSync throws on a non-zero exit, attaching the captured streams to
// the error. Read stdout back off it without asserting a shape we cannot check.
function stdoutOf(error: unknown): string {
  if (error && typeof error === "object" && "stdout" in error) {
    const stdout = error.stdout;
    if (typeof stdout === "string") return stdout;
    if (stdout instanceof Uint8Array) return Buffer.from(stdout).toString("utf8");
  }
  return "";
}

function guard(args: string[]): GuardResult {
  const script = join(homedir(), "scripts", "agent-harnesses.py");
  try {
    const output = execFileSync(
      "python3",
      [script, "guard", "--harness", "omp", ...args],
      { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
    );
    return JSON.parse(output) as GuardResult;
  } catch (error: unknown) {
    // The guard exits non-zero on deny but still prints its verdict.
    const output = stdoutOf(error);
    if (output) return JSON.parse(output) as GuardResult;
    return { decision: "deny", reason: "Shared guard failed closed" };
  }
}

export default function hook(pi: HookAPI): void {
  pi.on("tool_call", async (event) => {
    let result: GuardResult = { decision: "allow" };
    if (event.toolName === "bash") {
      result = guard([
        "--tool",
        "bash",
        "--command",
        String(event.input.command ?? ""),
      ]);
    } else if (event.toolName === "write" || event.toolName === "edit") {
      const path = String(event.input.file_path ?? event.input.path ?? "");
      const content = String(
        event.input.content ?? event.input.new_string ?? "",
      );
      result = guard(["--tool", event.toolName, "--path", path, "--content", content]);
    }
    if (result.decision === "deny") {
      return {
        block: true,
        reason: result.reason || "Blocked by shared harness guard",
      };
    }
    return undefined;
  });
}
