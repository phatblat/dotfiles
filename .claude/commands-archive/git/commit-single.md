Commit a single file with an appropriate commit message.

Arguments: `<file_path>`

1. Verify the specified file exists and has changes:
   - Check git status for the file
   - If file not found or has no changes, fail with clear error message

2. Review the changes:
   - Read the file diff to understand what changed
   - Determine appropriate commit type (feat, fix, refactor, docs, etc.)

3. Stage and commit:
   - Stage only the specified file with `git add <file_path>`
   - Write a concise conventional commit message
   - Commit with `git commit -m "<message>"`

4. Report the commit hash and message

Do NOT:
- Stage or commit any other files
- Update documentation (this is for single file commits only)
- Use agents (handle directly)
