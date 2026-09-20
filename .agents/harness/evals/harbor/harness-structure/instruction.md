# Harness Structure Verification

Verify that the shared agent harness has the expected directory structure and that key files exist with valid content.

## Required Structure

The harness must have:

1. **Files:**
   - `README.md` - explains the harness purpose and contains inventory information
   - `instructions.md` - agent operating rules (non-empty)

2. **Directories:**
   - `adapters/` - harness adapters (must contain at least one adapter)
   - `commands/` - command definitions
   - `agents/` - specialist agent definitions
   - `hooks/` - hook definitions

3. **Content Validation:**
   - README.md must contain "Inventory" section
   - README.md must list "Commands:" count
   - instructions.md must be non-empty
   - At least one adapter directory must exist under adapters/

All checks should pass for the harness structure to be considered valid.
