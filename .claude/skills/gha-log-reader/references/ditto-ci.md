# Ditto CI Context (getditto/ditto repo)

**Before using this file, confirm the repo.**

Extract `owner/repo` from the run URL or from:
```bash
gh run view <RUN_ID> --repo <owner/repo>
```

- If `owner/repo` is `getditto/ditto`: apply everything below as authoritative.
- If `owner/repo` is anything else: treat this as a pattern reference only.
  Check whether the concepts (domain structure, rollup jobs, runner naming, path
  filters) apply before using them — do not assume they do. Look for similar
  patterns in the actual workflow files if needed.

## Domain architecture

`ci.yml` is the entry point. It calls 8 domain workflows, then a final `ci-gate`
aggregates them all. Job names follow this nesting pattern:

```
<domain> / <domain>-ci / <actual job name>
```

Example: `small-peer / small-peer-ci / SDK: JS Node v24 (linux, arm64, legacy)`

**Domains:**
| Domain | Workflow | What it covers |
|--------|----------|----------------|
| `big-peer` | `big-peer-ci.yml` | HyDRA (big peer) tests |
| `small-peer` | `small-peer-ci.yml` | SDKs (Rust, JS, Swift, Kotlin, Flutter, .NET, C++, Go) + core |
| `linting` | `linting.yml` | Shell, Rust, YAML format checks |
| `default-pr` | `default-pr-ci.yml` | PR-only checks (linear ticket, size report, changelogs) |
| `smoke-tests` | `smoke-tests.yml` | Cross-peer replication stress tests |
| `ditto-operator` | `ditto-operator-ci.yml` | Kubernetes operator |
| `dtp` | `dtp.yml` | Device test platform |

**Rollup/aggregator jobs — always skip these, never fetch their logs:**
- `ci-gate` — final gate in `ci.yml`, step: "Check domain results"
- `small-peer / small-peer-ci / small-peer-ci-workflow` — step: "Job Checks"
- `big-peer / big-peer-ci / big-peer-ci-workflow` — step: "Job Checks"
- Any job whose leaf name ends in `-workflow`

Example: in a run with 159 jobs, 3 had `conclusion: failure`:
- `small-peer / small-peer-ci / SDK: JS Node v24 (linux, arm64, legacy)` ← **real failure**
- `small-peer / small-peer-ci / small-peer-ci-workflow` ← rollup, skip
- `ci-gate` ← rollup, skip

## Runner fleet

| Runner label | Type | Arch | Size | Used for |
|---|---|---|---|---|
| `ditto-sdk-runner-small-amd64-new` | Self-hosted Linux | AMD64 | Small | Pre-flight checks, linting, lightweight jobs |
| `ditto-sdk-runner-large-amd64-new` | Self-hosted Linux | AMD64 | Large | Most SDK builds and tests |
| `ditto-sdk-runner-large-arm64-new` | Self-hosted Linux | ARM64 | Large | ARM64 SDK builds (JS Node arm64, C++, .NET, Rust) |
| `ditto-sdk-runner-large-amd64-kvm` | Self-hosted Linux | AMD64 | Large + KVM | Android emulator tests (Kotlin SDK) |
| `mac-aws` | Self-hosted macOS | ARM64 | — | Swift, iOS simulator, macOS .NET, Flutter macOS |
| `ubuntu-22.04` / `ubuntu-latest` | GitHub-hosted | AMD64 | Standard | Flutter Linux amd64, lightweight checks |
| `ubuntu-22.04-xlarge` | GitHub-hosted | AMD64 | XL | Flutter Linux web (disk-intensive WASM build) |
| `linux-aarch64` | GitHub-hosted | ARM64 | — | Flutter Linux arm64 |
| `windows-2022` / `windows-2022-xlarge` | GitHub-hosted | AMD64 | — | JS/Electron Windows, .NET Windows, Flutter Windows |

## Known flaky / quarantined jobs

When you see one of these fail, always mention the known issue before diagnosing:

| Job name pattern | Issue | Notes |
|---|---|---|
| `SDK: JS Node v*` | **DEVX-877** — teardown SIGTRAP/SIGSEGV in napi-rs fork (V8 GlobalHandles race) | Quarantined to `sdk-js-node-quarantined.yml`. Runs nightly on `main` or on PRs with label `D-ci-include-node-sdk-tests`. Also runs on `releases/release-*` pushes only |
| `SDK: JS Electron *` | **DEVX-877 / DEVX-912** — same napi-rs teardown crash | Same quarantine as Node SDK |
| `LocalStack (ditto-peer)` | **DEVX-913** — intermittent UDP peer connect / first DB commit timeout | Has 3-retry mitigation; a failure after all retries is usually a real regression |

## Cache system

- Cache is controlled by `CACHE_VERSION: 7` in `small-peer-ci.yml`
- If a failure looks like a corrupted or partial cache (missing files, unexpected state), suggest incrementing `CACHE_VERSION` as the fix
- Cache action: `runs-on/cache@v4`

## CI control labels (PR labels that modify CI behavior)

| Label | Effect |
|---|---|
| `D-ci-run-on-draft` | Run full CI on a draft PR |
| `D-build-images-on-draft` | Build HyDRA Docker images only on a draft PR |
| `D-ci-run-ngn-sdk-checks` | Add NGN network stack to the JS SDK test matrix |
| `D-ci-include-node-sdk-tests` | Opt into quarantined JS Node + Electron tests |
| `D-ci-react-native` | Include React Native tests |

## Path filtering

- Coarse (which domains run): `.github/paths-filters/ci-gate.yml`
- Fine (which jobs within small-peer run): `.github/paths-filters/small-peer.yml`
- On push to `main` or `releases/*`: all filters return `true`, all jobs run
- On PR: only domains/jobs whose paths changed are triggered
