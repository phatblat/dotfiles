# Claude CLI Initialization — Agents and MCPs

Your job is to initialize this Claude CLI environment with the appropriate **agents** and **MCPs (Modular Capability Plugins)** to support the specific tasks required by this project.

---

## Step 1: Understand the Project Context

Begin by understanding what this project is. This is critical, as not every project is a programming or software development project.

Read and analyze:

- `README.md`
- `CLAUDE.md`
- `package.json`
- Any other available high-level documentation

Scan for:

- The domain and goals of the project  
- Relevant tasks the CLI should assist with  
- Functional and non-functional requirements  
- Whether the project is code-heavy, research-focused, organizational, data-centric, etc.

---

## Step 2: MCP Setup

After you understand the project:

Review the MCP definitions in:

- `/Users/silasrhyneer/.claude/mcp-library/.mcp.json`  
- `/Users/silasrhyneer/.claude/mcp-library/CLAUDE.md`

MCPs are specialized plugins designed to help solve distinct classes of problems. Your task is to identify which MCPs are relevant to this project based on the needs you inferred in Step 1.

Select and list:

- All available MCPs  
- The subset you recommend enabling for this project

⚠️ Do **not** generate the new config yet.

---

## Step 3: Agent Setup

Review the contents of:

- `/Users/silasrhyneer/.claude/agents-library/`

Each agent in this directory performs specialized tasks (e.g., code formatting, rewriting markdown, managing notes, analyzing graphs, generating insights, etc.). Determine which of these agents should be added to the project.

Select and list:

- All available agents  
- The subset you recommend enabling for this project

⚠️ Do **not** copy the agent files yet.

---

## Step 4: Exit With a Short Plan

Exit with a concise summary containing:

- Project type and key inferred needs  
- Available MCPs and your selected subset  
- Available agents and your selected subset  
- A minimal rationale for your MCP and agent choices

---

## If Plan is Approved

1. Generate the new `.mcp.json` file by calling:

`/Users/silasrhyneer/.claude/mcp-library/generate-mcp-config.sh <selected MCP names>`

2. Copy the selected agent files into:

`.claude/agents/`

Once the CLI restarts, the selected MCPs and agents will be active, augmenting the environment.
