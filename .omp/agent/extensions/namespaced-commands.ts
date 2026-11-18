// namespaced-commands.ts — route Claude-style `/ns:name` slash commands to their OMP-native `ns-name` adapters.
// Copyright: Ben Chatelain. MIT
//
// OMP splits a slash command's name from its arguments at the first whitespace or `:`,
// and dispatches builtins before file commands. `/git:commit` therefore runs the builtin
// `/git` with revision "commit" ("Cannot resolve revision: commit"), and `/plan:worktree`
// enters plan mode. The Claude adapter registered as `git:commit` is unreachable.
// scripts/agent-harnesses.py renders every nested command as a flat OMP command
// (`git/commit` -> `~/.omp/agent/commands/git-commit.md`). The `input` hook runs before
// builtin dispatch, so it rewrites `/a:b[:c] args` to `/a-b[-c] args` when that file
// exists. Everything else passes through untouched, including builtin colon forms such
// as `/effort:high`. Delete this file once OMP resolves a full `ns:name` token before
// splitting on `:`.
import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import { getAgentDir } from "@oh-my-pi/pi-coding-agent";

// Lowercase only: generated command ids are lowercase kebab-case, and APFS is
// case-insensitive, so a mixed-case probe would "find" a file OMP's case-sensitive
// command lookup then misses.
const NAMESPACED = /^\/([a-z0-9][a-z0-9-]*(?::[a-z0-9][a-z0-9-]*)+)(?=\s|$)/;

export default function namespacedCommands(pi: ExtensionAPI) {
  pi.on("input", async (event) => {
    const match = NAMESPACED.exec(event.text);
    if (!match) return;
    const flat = match[1].replaceAll(":", "-");
    if (!fs.existsSync(path.join(getAgentDir(), "commands", `${flat}.md`))) return;
    return { text: `/${flat}${event.text.slice(match[0].length)}` };
  });
}
