#!/usr/bin/env node
// Agent Flow hook forwarder for Codex.
// Reads live Agent Flow extension registrations from $CODEX_HOME/agent-flow
// and forwards Codex hook input to matching localhost listeners.
"use strict";

const fs = require("fs");
const path = require("path");
const http = require("http");
const os = require("os");

setTimeout(() => process.exit(0), 1500);

const CODEX_HOME = process.env.CODEX_HOME || path.join(os.homedir(), ".codex");
const DIR = process.env.AGENT_FLOW_DIR || path.join(CODEX_HOME, "agent-flow");
const IS_WIN = process.platform === "win32";

function normPath(p) {
  let result = path.resolve(p);
  try {
    result = fs.realpathSync(result);
  } catch {}
  return result;
}

function isAlive(pid) {
  if (IS_WIN) return true;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  input += chunk;
});
process.stdin.on("end", () => {
  let cwd;
  try {
    cwd = JSON.parse(input).cwd;
  } catch {
    process.exit(0);
  }
  if (!cwd) process.exit(0);

  const resolvedCwd = normPath(cwd);

  let allFiles;
  try {
    allFiles = fs
      .readdirSync(DIR)
      .filter((file) => file.endsWith(".json") && file !== "workspaces.json");
  } catch {
    process.exit(0);
  }
  if (!allFiles.length) process.exit(0);

  const matches = [];
  for (const file of allFiles) {
    let data;
    const filePath = path.join(DIR, file);
    try {
      data = JSON.parse(fs.readFileSync(filePath, "utf8"));
    } catch {
      continue;
    }
    if (!data.workspace || !data.pid || !data.port) continue;

    if (!isAlive(data.pid)) {
      try {
        fs.unlinkSync(filePath);
      } catch {}
      continue;
    }

    const workspace = normPath(data.workspace);
    if (
      resolvedCwd === workspace ||
      resolvedCwd.startsWith(workspace + path.sep)
    ) {
      matches.push({ data, workspaceLength: workspace.length });
    }
  }

  if (!matches.length) process.exit(0);

  matches.sort((a, b) => b.workspaceLength - a.workspaceLength);
  const bestLength = matches[0].workspaceLength;
  const targets = matches.filter(
    (match) => match.workspaceLength === bestLength
  );

  let pending = targets.length;
  for (const { data } of targets) {
    let settled = false;
    const finish = () => {
      if (settled) return;
      settled = true;
      done();
    };
    const req = http.request(
      {
        hostname: "127.0.0.1",
        port: data.port,
        method: "POST",
        headers: { "Content-Type": "application/json" },
        timeout: 1000,
      },
      (res) => {
        res.resume();
        res.on("end", finish);
      }
    );
    req.on("error", finish);
    req.on("timeout", () => {
      req.destroy();
      finish();
    });
    req.write(input);
    req.end();
  }

  function done() {
    if (--pending <= 0) process.exit(0);
  }
});
