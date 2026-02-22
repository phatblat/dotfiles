# .claude

Claude Code configuration directory containing agents, skills, hooks, and supporting infrastructure.

## Directory Structure

```
.claude/
├── agents/           # Named agent definitions (Algorithm, Architect, Engineer, etc.)
├── hooks/            # Event hooks for session lifecycle
├── skills/           # Skill modules (Research, Browser, Art, etc.)
├── lib/              # Shared utilities
├── MEMORY/           # Learning capture system
├── VoiceServer/      # Voice notification server
├── settings.json     # Configuration
└── install.sh        # Installer entry point
```

## Agents

Specialized agent definitions in `agents/` with distinct personas and expertise areas:

- **Algorithm** -- ISC tracking, verification, constraint extraction
- **Architect** -- System design, distributed systems
- **Engineer** -- TDD, implementation, Fortune 10 experience
- **Designer** -- UX/UI, accessibility, shadcn/ui
- **QATester** -- Browser automation, verification
- **Pentester** -- Security testing, vulnerability assessment
- **Artist** -- Visual content, prompt engineering
- **Intern** -- High-agency generalist problem solver
- **Researchers** -- ClaudeResearcher, CodexResearcher, GeminiResearcher, GrokResearcher, PerplexityResearcher

## Skills

Modular capability packages in `skills/` providing domain-specific workflows, tools, and context.
