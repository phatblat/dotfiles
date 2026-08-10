# Context Compaction Preservation

When compacting or resuming a session, preserve and carry forward:

- The complete list of modified files, with paths.
- The current Git branch and uncommitted changes.
- Pending tasks and TODO items, including blockers.
- Test commands run, results, and failures.
- Key architectural decisions and constraints made during the session.

Do not claim work is complete until the preserved task state confirms that all actionable work is finished and verification evidence is available.

# Git Commit Attribution

When creating any Git commit, append this trailer exactly once after a blank line:

Co-Authored-By: oh-my-pi <omp@can.ac>
