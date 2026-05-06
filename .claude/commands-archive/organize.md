# Organize Obsidian Vault File

Organize the specified file into the correct subfolder in the Obsidian vault at ~/2ndBrain/.

## Input

The user provides a file path as an argument: $ARGUMENTS

## Steps

1. Read the file contents to understand what it is about.
2. If the filename is generic (e.g., Untitled, ERROR, single letters), rename it to a descriptive kebab-case name based on the content.
3. Determine the best target folder from the existing vault structure:
   - ai-tools/ — AI tools, LLMs, Claude, Cursor, Windsurf, ML
   - aws/ — AWS services (EC2, S3, AMIs)
   - claude-plans/ — Claude session plans and summaries
   - clippings/ — Web clippings
   - dev/ — Developer reference (git, languages, frameworks, build tools, shell, dotfiles)
   - ditto/ — Ditto company work (SDK, KMP, Android, iOS, Rust, CI/CD, incidents, releases)
   - finance/ — Trading, stocks, 401k, financial tools
   - gaming/ — Video games, game saves, gaming errors
   - geekbench/ — Geekbench benchmarks
   - harness/ — Harness CI/CD platform
   - home/ — Personal (prescriptions, appliances, family, fitness, shopping, devices)
   - infra/ — Infrastructure (Proxmox, Docker, Terraform, Tailscale, networking, VMs, certs)
   - jack/ — Jack-related projects
   - kaiser-permanente/ — Kaiser health-related
   - linear/ — Linear project management
   - linux/ — Linux notes (with asahi/ subfolder for Asahi Linux)
   - macos/ — macOS-specific (apps, system, MDM, Nix, Parallels)
   - mas-cli/ — mas CLI tool for Mac App Store
   - scrybble/ — Scrybble (reMarkable integration)
   - taxes/ — Tax documents
   - windows/ — Windows, PowerShell, Hyper-V, MSI, Windows CI runners
4. Move the file to the target folder. If it was renamed, use the new name.
5. Report what was done: original name, new name (if changed), and destination folder.

## Rules

- Wikilinks resolve by filename regardless of folder, so moves never break links.
- macOS filesystem is case-insensitive; use two-step rename if changing only case.
- If no existing folder fits, propose creating a new top-level folder and confirm with the user before proceeding.
- If the file content is ambiguous, ask the user which folder to use.
