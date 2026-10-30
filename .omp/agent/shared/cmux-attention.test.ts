// cmux-attention.test.ts — the attention depth / in-flight notification machine.
// Copyright: Ben Chatelain. MIT
//
// Run from this directory: bun test ./cmux-attention.test.ts
// (from $HOME, bun test scans the whole home tree and does not finish).
//
// `spawn` is stubbed so each `cmux notify` stays in flight until the test
// resolves it, which is what exposes the interleavings.

import { EventEmitter } from "node:events";
import { beforeEach, expect, mock, test } from "bun:test";

interface FakeChild extends EventEmitter {
  stdout: EventEmitter;
  kill: () => void;
  unref: () => void;
}

/** Every spawned cmux invocation, in order. */
const calls: { args: string[]; child: FakeChild }[] = [];

mock.module("node:child_process", () => ({
  spawn: (_bin: string, args: string[]) => {
    const child = new EventEmitter() as FakeChild;
    child.stdout = new EventEmitter();
    child.kill = () => {};
    child.unref = () => {};
    calls.push({ args, child });
    return child;
  },
}));
mock.module("@oh-my-pi/pi-coding-agent/utils/run-status", () => ({ setRunStatus: () => {} }));

// Dynamic import: the module must load after the mocks above are registered,
// which a hoisted static import cannot guarantee.
const { raiseAttention, lowerAttention, releaseAttention } = await import("./cmux-attention");

const request = { kind: "permission", summary: "approve?" } as const;

const notifies = () => calls.filter((c) => c.args[0] === "notify");
const markedRead = () =>
  calls.filter((c) => c.args[0] === "mark-notification-read").map((c) => c.args[2]);

/** Answer the n-th `cmux notify` with the given notification id. */
function finishNotify(index: number, id: string): void {
  const { child } = notifies()[index];
  child.stdout.emit("data", Buffer.from(JSON.stringify({ id })));
  child.emit("close");
}

beforeEach(() => {
  process.env.CMUX_SURFACE_ID = "surface-1";
  process.env.CMUX_WORKSPACE_ID = "workspace-1";
  calls.length = 0;
  const globals = globalThis as { __cmuxOmpAttention?: unknown };
  globals.__cmuxOmpAttention = undefined;
});

test("answered while the notify is in flight: the late notification is marked read", async () => {
  const raised = raiseAttention(request);
  lowerAttention();
  finishNotify(0, "n1");
  await raised;
  expect(markedRead()).toEqual(["n1"]);
});

test("nested raise during an in-flight notify keeps it open until the last prompt lowers", async () => {
  const first = raiseAttention(request);
  await raiseAttention(request);
  finishNotify(0, "n1");
  await first;
  expect(notifies()).toHaveLength(1);
  expect(markedRead()).toEqual([]);

  lowerAttention();
  expect(markedRead()).toEqual([]);
  lowerAttention();
  expect(markedRead()).toEqual(["n1"]);
});

test("lowering with nothing open does not mark anything read", () => {
  lowerAttention();
  expect(markedRead()).toEqual([]);
});

test("releaseAttention releases only the requested count, leaving other sessions' prompts open", async () => {
  const first = raiseAttention(request);
  finishNotify(0, "n1");
  await first;
  await raiseAttention(request);
  await raiseAttention(request);

  releaseAttention(2);
  expect(markedRead()).toEqual([]);
  releaseAttention(1);
  expect(markedRead()).toEqual(["n1"]);
});
