# Feature Plan: Sync System, Analyze Tab, and Sync Tab

## Overview

Replace the Console tab with an **Analyze** tab for saving log excerpts with full context, and add a new **Sync** tab for background sync control and metrics. Build a background sync system to download job metadata for the last 24 hours and logs for failed builds only.

### Tab Structure After Implementation
1. **Runners** - existing
2. **Workflows** - existing
3. **Analyze** - replaces Console (save/review log excerpts)
4. **Sync** - new (sync control, metrics, error log)

---

## Phase 1: Data Structures and State

### 1.1 Analysis Session (`src/state/analyze.rs`)

```rust
pub struct AnalysisSession {
    pub id: Uuid,
    pub title: String,
    pub notes: Option<String>,
    pub tags: Vec<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub nav_context: NavigationContext,
    pub run_metadata: RunMetadata,
    pub github_url: String,
    pub log_excerpt: String,
    pub total_log_lines: usize,
    pub excerpt_start_line: usize,
    pub excerpt_end_line: usize,
}

pub struct NavigationContext {
    pub source_tab: SourceTab,  // Workflows or Runners
    pub owner: String,
    pub repo: String,
    pub workflow_id: Option<u64>,
    pub workflow_name: Option<String>,
    pub run_id: u64,
    pub run_number: u64,
    pub job_id: u64,
    pub job_name: String,
    pub job_status: RunStatus,
    pub job_conclusion: Option<RunConclusion>,
    pub scroll_to_line: usize,
    pub selection_anchor: usize,
    pub selection_cursor: usize,
}

pub struct RunMetadata {
    pub pr_number: Option<u64>,
    pub branch_name: Option<String>,
    pub commit_sha: String,
    pub author: Option<String>,
    pub runner_name: Option<String>,
    pub runner_labels: Vec<String>,
}
```

### 1.2 Sync State (`src/state/sync.rs`)

```rust
pub struct SyncState {
    pub enabled: bool,
    pub status: SyncStatus,
    pub progress: SyncProgress,
    pub metrics: SyncMetrics,
    pub error_tracker: ErrorTracker,
    pub messages: Vec<ConsoleMessage>,  // Moved from Console
}

pub enum SyncStatus {
    Idle,
    Running,
    Paused { reason: PauseReason },
}

pub enum PauseReason {
    UserDisabled,
    RateLimited { reset_at: DateTime<Utc> },
    ErrorThreshold,  // 5 errors in 1 minute
}

pub struct SyncProgress {
    pub phase: SyncPhase,
    pub current_item: Option<String>,
    pub pending_jobs: usize,
    pub pending_logs: usize,
}

pub struct SyncMetrics {
    pub jobs_synced_total: u64,
    pub jobs_synced_session: u64,
    pub logs_cached_total: u64,
    pub errors: u64,
}

pub struct ErrorTracker {
    errors: VecDeque<Instant>,  // Rolling 1-minute window
    // Pauses when errors.len() >= 5
}
```

### 1.3 Analyze Tab State (`src/state/analyze.rs`)

```rust
pub struct AnalyzeTabState {
    pub view: AnalyzeViewLevel,  // List or Detail
    pub sessions: Vec<AnalysisSession>,
    pub list_state: ListState,
    pub detail_scroll_y: u16,
    // Note: No edit_buffer or edit fields in v1 (read-only)
}

pub enum AnalyzeViewLevel {
    List,
    Detail { session_id: Uuid },
}
```

---

## Phase 2: Sync Worker Architecture

### 2.1 Channel Communication

```rust
// Commands from App to Worker
pub enum SyncCommand {
    Start,
    Pause,
    Stop,
    UpdateFavorites(HashSet<String>),
}

// Events from Worker to App
pub enum SyncEvent {
    StatusChanged(SyncStatus),
    ProgressUpdate(SyncProgress),
    RunSynced { owner, repo, workflow_id, run_id },
    LogDownloaded { owner, repo, job_id },
    Error(String),
    MetricsUpdate(SyncMetrics),
    PausedForErrors,
    RateLimited { reset_at },
}
```

### 2.2 Worker Loop

1. Check for commands (non-blocking)
2. If not running, sleep briefly and continue
3. Process queue (favorites only):
   - **High priority**: Favorited workflows' job metadata (last 24h)
   - **Low priority**: Log downloads for failed runs only
4. Rate limit: 500ms between requests, adaptive based on remaining quota
5. Error handling: Record errors, pause if 5 in 1 minute
6. Retry logic: 3 retries with exponential backoff for transient errors

### 2.3 Rate Limiting

- Base delay: 500ms between requests
- Adaptive: Increase to 2-5s when API quota < 500
- Backoff: Double delay after errors (max 30s)
- Reset: Return to base delay after success

---

## Phase 3: UI Implementation

### 3.1 Analyze Tab Layout

**List View:**
```
+------------------------------------------------------------------+
| Analyze                                                          |
+------------------------------------------------------------------+
| > build-linux - 15 lines from jolt                    2h ago     |
|   PR #42 on feature-branch  @mac-runner-01                       |
|                                                                  |
|   test-windows - 8 lines from jolt                    1d ago     |
|   main branch  @windows-runner-02                                |
+------------------------------------------------------------------+
| ↑↓ Navigate  ↵ View  d Delete  g Go to log  ? Help               |
+------------------------------------------------------------------+
```

**Detail View:**
```
+------------------------------------------------------------------+
| Analyze > build-linux - 15 lines from jolt                       |
+------------------------------------------------------------------+
| Context: phatblat/jolt  Run #456  Job: build-linux               |
| PR #42 on feature-branch  Author: phatblat  Runner: mac-runner-01|
+------------------------------------------------------------------+
|   142 | error: test 'test_parse' failed                          |
|   143 |   assertion `left == right` failed                       |
+------------------------------------------------------------------+
| Esc Back  g Go to log  o Open GitHub  c Copy  ? Help             |
+------------------------------------------------------------------+
```

### 3.2 Sync Tab Layout

```
+------------------------------------------------------------------+
| Sync                                                             |
+------------------------------------------------------------------+
| +-- Sync Status -----------------------------------------------+ |
| | Status: RUNNING  [Shift+S to pause]                          | |
| | Current: Fetching jobs for phatblat/myrepo #1234             | |
| | Queue: 3 jobs pending, 12 logs pending                       | |
| +--------------------------------------------------------------+ |
|                                                                  |
| +-- Metrics ---------------------------------------------------+ |
| | Jobs synced:  142 (+23 this session)                         | |
| | Logs cached:  47 failed runs                                 | |
| | Errors:       2 (0 in last minute)                           | |
| | API calls:    4823/5000 remaining (resets 2:34:12)           | |
| +--------------------------------------------------------------+ |
|                                                                  |
| +-- Recent Activity -------------------------------------------+ |
| | ❌ 2m ago  401 Unauthorized - /repos/foo/bar/actions/runs    | |
| | ℹ️ 8m ago  Downloaded log for job #98765                     | |
| +--------------------------------------------------------------+ |
+------------------------------------------------------------------+
```

### 3.3 Status Bar Sync Indicator

Add to right side of status bar (visible from all tabs):
- `Sync: ON` (green) - Running
- `Sync: OFF` (gray) - Disabled by user
- `Sync: PAUSED` (red) - Error threshold exceeded

---

## Design Decisions

Based on user feedback:
- **Analyze tab**: Read-only in v1 (no editing of title/notes/tags)
- **Error display**: Consolidated in Sync tab activity log only
- **Sync scope**: Favorites only (not all accessible repos)

---

## Phase 4: Keyboard Interactions

### Global (all tabs)
| Key | Action |
|-----|--------|
| `Shift+S` | Toggle sync on/off |

### Log Viewer (Workflows/Runners)
| Key | Action |
|-----|--------|
| `a` | Save selection to new analysis session |

### Analyze Tab - List View
| Key | Action |
|-----|--------|
| `j/↓` | Select next session |
| `k/↑` | Select previous session |
| `Enter` | Open detail view |
| `d` | Delete session |
| `g` | Go to original log position |
| `o` | Open GitHub URL in browser |

### Analyze Tab - Detail View
| Key | Action |
|-----|--------|
| `j/↓` | Scroll excerpt down |
| `k/↑` | Scroll excerpt up |
| `Esc` | Return to list view |
| `g` | Go to original log position |
| `o` | Open GitHub URL |
| `c` | Copy excerpt to clipboard |

---

## Phase 5: Storage

### Analysis Sessions
- Path: `~/.cache/jolt/analyze/sessions.json`
- Format: JSON array of `AnalysisSession`
- No expiration (user-created content)

### Sync State (persisted)
- Add to existing `state.json`:
  - `sync_enabled: bool`
  - `jobs_synced_total: u64`
  - `logs_cached_total: u64`

### Sync Queue (resumable)
- Path: `~/.cache/jolt/sync_queue.json`
- Allows resuming sync after restart

---

## Implementation Order

### Step 1: Core Data Structures
- [ ] Create `src/state/analyze.rs` with AnalysisSession, NavigationContext, RunMetadata
- [ ] Create `src/state/sync.rs` with SyncState, SyncProgress, SyncMetrics, ErrorTracker
- [ ] Add `uuid` dependency to Cargo.toml
- [ ] Update `src/state/mod.rs` exports

### Step 2: Tab Infrastructure
- [ ] Change `Tab::Console` to `Tab::Analyze` in `src/app.rs`
- [ ] Add `Tab::Sync` variant
- [ ] Add `analyze: AnalyzeTabState` and `sync: SyncState` fields to App
- [ ] Update tab cycling logic
- [ ] Move console_messages to sync.messages

### Step 3: Analyze Tab UI
- [ ] Create `draw_analyze_tab()` in `src/ui/mod.rs`
- [ ] Implement list view rendering
- [ ] Implement detail view rendering
- [ ] Add key handlers for Analyze tab

### Step 4: Session Creation
- [ ] Add `a` key handler in log viewer
- [ ] Build NavigationContext from current view state
- [ ] Build RunMetadata from job/run data
- [ ] Extract selected log lines
- [ ] Create and persist session

### Step 5: Navigation Back
- [ ] Implement `go_to_analysis_session()`
- [ ] Rebuild navigation stack from NavigationContext
- [ ] Load data for each level
- [ ] Restore selection state

### Step 6: Sync Tab UI
- [ ] Create `draw_sync_tab()` in `src/ui/mod.rs`
- [ ] Implement status box
- [ ] Implement metrics box
- [ ] Implement activity list
- [ ] Add status bar sync indicator

### Step 7: Sync Toggle
- [ ] Add `Shift+S` global keybind
- [ ] Implement `toggle_sync()` method
- [ ] Update persisted state

### Step 8: Sync Worker
- [ ] Create `src/sync/mod.rs` with channel types
- [ ] Create `src/sync/worker.rs` with main loop
- [ ] Create `src/sync/rate_limiter.rs`
- [ ] Create `src/sync/queue.rs` with priority logic
- [ ] Spawn worker task in App::new()
- [ ] Process SyncEvents in event loop

### Step 9: Integration
- [ ] Wire up favorites priority
- [ ] Filter log downloads to failed runs only
- [ ] Test error threshold pausing
- [ ] Update help overlay

---

## Critical Files to Modify

| File | Changes |
|------|---------|
| `src/app.rs` | Tab enum, App fields, key handlers, sync channels |
| `src/state/mod.rs` | Export analyze and sync modules |
| `src/state/analyze.rs` | New file - AnalysisSession, AnalyzeTabState |
| `src/state/sync.rs` | New file - SyncState, ErrorTracker |
| `src/ui/mod.rs` | draw_analyze_tab, draw_sync_tab, status bar |
| `src/ui/tabs.rs` | Add Sync tab, remove Console |
| `src/cache/paths.rs` | analysis_sessions_path, sync_queue_path |
| `src/cache/store.rs` | read/write sessions functions |
| `src/sync/mod.rs` | New file - channel types, SyncCommand, SyncEvent |
| `src/sync/worker.rs` | New file - SyncWorker implementation |
| `src/sync/rate_limiter.rs` | New file - adaptive rate limiting |
| `Cargo.toml` | Add uuid dependency |

---

## Dependencies to Add

```toml
uuid = { version = "1.0", features = ["v4", "serde"] }
```
