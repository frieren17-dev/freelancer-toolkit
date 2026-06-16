# Freelancer Toolkit Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `freelancer-toolkit` Claude Code plugin (skill + commands + hooks + MCP + agents) and publish it as an installable GitHub plugin marketplace.

**Architecture:** Everything lives in one plugin directory, `my-freelancer-plugin/`, containing all four plugin building blocks. The same directory doubles as its own marketplace via `.claude-plugin/marketplace.json` with `source: "./"`, so one GitHub repo is both the plugin and the marketplace. Hooks are Bash scripts registered in `hooks/hooks.json`; a shared `hooks/json-utils.sh` keeps stdin-payload parsing DRY across hooks. The plugin is developed as its own standalone git repo and pushed to GitHub as a public repo named `freelancer-toolkit`.

**Tech Stack:** Claude Code plugin system, JSON manifests, Markdown (SKILL.md / commands / agents), Bash hooks, GitHub MCP server (HTTP transport), git + `gh` CLI.

**Decisions locked for this plan (swap the value in the relevant file if you want a different one):**
- **MCP server bundled:** GitHub (HTTP)
- **Second hook (Lesson 5, Part 2):** Option A — log every written file to `changelog.txt`
- **Scope:** Full — build, package, and publish to GitHub (Tasks 1–13). Tasks 12–13 are the publish phase and can be deferred if you only want to build + package locally.
- **Author identity (public):** Ranniel Abueg / arca2@briarbear.ai

**Environment notes (Windows):**
- Run all `claude` / `git` / `gh` commands from the project root `C:\GitHub\ClaudeCodePlugins` unless a step says otherwise.
- Hook scripts run under **bash** even on Windows (Claude Code uses bash for hooks). Save `.sh` files with **LF** line endings — CRLF will break `#!/usr/bin/env bash`.
- The plugin is its own git repo. Commits in Tasks 1–11 go to the plugin repo at `my-freelancer-plugin/`, not the outer course repo.

---

## File Structure

All paths are under `C:\GitHub\ClaudeCodePlugins\my-freelancer-plugin\`.

```
my-freelancer-plugin/
  .claude-plugin/
    plugin.json            # Plugin metadata: name, version, description, author (object)
    marketplace.json       # Marketplace index; lists this plugin with source "./"
  skills/
    client-brief/
      SKILL.md             # client-brief-generator skill (auto-triggers on client/brief intent)
  commands/
    onboard-client.md      # /freelancer-toolkit:onboard-client — full onboarding flow
    weekly-report.md       # /freelancer-toolkit:weekly-report — weekly client report
    research-and-write.md  # /freelancer-toolkit:research-and-write — research → write → review
  agents/
    research-agent.md      # Subagent: find + summarize 3–5 credible sources
    review-agent.md        # Subagent: score draft for SEO/accuracy/quality
  hooks/
    hooks.json             # Registers PostToolUse hooks for Write|Edit
    json-utils.sh          # Shared helper: extract file_path from a hook JSON payload
    quality-check.sh       # PostToolUse: word count + placeholder check on content files
    log-changes.sh         # PostToolUse: append written file path to changelog.txt
  .mcp.json                # GitHub MCP server config (HTTP, token via env var)
  .gitignore               # Ignore runtime output (client-briefs/, content/, reports/, changelog.txt)
  README.md                # What it does, install, MCP/hook setup, command reference
```

**Why this layout:** Each building block sits in its own conventional folder so the plugin loader auto-discovers it (no `components` key in `plugin.json`). Hook payload parsing is factored into `json-utils.sh` so `quality-check.sh` and `log-changes.sh` don't duplicate JSON extraction. Runtime artifacts the commands/hooks generate (client briefs, drafts, reports, changelog) are git-ignored so they never get published with the plugin.

---

## Task 0: Prerequisites

**Files:** none (verification only)

- [ ] **Step 1: Verify the required tools are installed**

Run:
```bash
claude --version
git --version
gh --version
bash --version
```
Expected: each prints a version with no "command not found". If `gh` is missing, install GitHub CLI before Task 12 (it is only needed for publishing).

- [ ] **Step 2: Confirm the working directory**

Run:
```bash
pwd
```
Expected: `C:/GitHub/ClaudeCodePlugins` (or the Windows equivalent). All later paths are relative to here.

---

## Task 1: Plugin skeleton + metadata

**Files:**
- Create: `my-freelancer-plugin/.claude-plugin/plugin.json`
- Create dirs: `my-freelancer-plugin/{skills/client-brief,commands,agents,hooks}`

- [ ] **Step 1: Confirm validation fails before the plugin exists (the failing test)**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: FAIL — the directory / `plugin.json` does not exist yet.

- [ ] **Step 2: Create the directory skeleton**

Run:
```bash
mkdir -p my-freelancer-plugin/.claude-plugin \
         my-freelancer-plugin/skills/client-brief \
         my-freelancer-plugin/commands \
         my-freelancer-plugin/agents \
         my-freelancer-plugin/hooks
```

- [ ] **Step 3: Create `plugin.json`**

File: `my-freelancer-plugin/.claude-plugin/plugin.json`
```json
{
  "name": "freelancer-toolkit",
  "version": "1.0.0",
  "description": "A freelancer's toolkit for client onboarding, content creation, and project management",
  "author": {
    "name": "Ranniel Abueg",
    "email": "arca2@briarbear.ai"
  }
}
```
Note: `author` MUST be an object (name + email). Do NOT add a `components` key — files are auto-discovered.

- [ ] **Step 4: Run validation to verify it now passes**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS (no errors; warnings about empty folders are OK).

- [ ] **Step 5: Initialize the plugin's own git repo and commit**

Run:
```bash
cd my-freelancer-plugin
git init
git add .claude-plugin/plugin.json
git commit -m "chore: scaffold freelancer-toolkit plugin skeleton"
cd ..
```
(Optional tidy step: append `my-freelancer-plugin/` to the outer `C:\GitHub\ClaudeCodePlugins\.gitignore` so the course repo ignores this nested repo.)

---

## Task 2: client-brief-generator skill

**Files:**
- Create: `my-freelancer-plugin/skills/client-brief/SKILL.md`

- [ ] **Step 1: Write the skill**

File: `my-freelancer-plugin/skills/client-brief/SKILL.md`
```markdown
---
name: client-brief-generator
description: Generates a comprehensive client brief for freelance projects. Use when the user mentions onboarding a new client, starting a new project, or creating a client brief.
---

# Client Brief Generator

When this skill triggers, gather the information below and produce a formatted client brief.

## Required information

Ask for anything the user has not already provided. Ask in small batches, not all ten at once.

1. **Client / Brand name**
2. **Industry** — what sector they operate in
3. **Services needed** — what they are hiring you for
4. **Target audience** — who they want to reach
5. **Brand voice** — professional, casual, playful, authoritative, etc.
6. **Platforms** — where content will be published
7. **Budget range** — if disclosed (otherwise record "Not disclosed")
8. **Timeline** — key deadlines and milestones
9. **Competitors** — 2–3 to reference
10. **Success metrics** — how the work will be measured

## Output

Produce the brief as a clean Markdown table with two columns: **Field** and **Detail**. Below the table, add a short "Notes & next steps" section with 3–5 bullets.

Save the brief to `client-briefs/<client-name>-brief.md`, where `<client-name>` is lowercased with spaces replaced by hyphens. Create the `client-briefs/` folder if it does not exist. After saving, tell the user the exact file path.
```

- [ ] **Step 2: Validate (catches frontmatter errors)**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS. The skill must have `name` and `description` in YAML frontmatter.

- [ ] **Step 3: Commit**

```bash
cd my-freelancer-plugin
git add skills/client-brief/SKILL.md
git commit -m "feat: add client-brief-generator skill"
cd ..
```

---

## Task 3: onboard-client command

**Files:**
- Create: `my-freelancer-plugin/commands/onboard-client.md`

- [ ] **Step 1: Write the command**

File: `my-freelancer-plugin/commands/onboard-client.md`
```markdown
---
description: Walk through new client onboarding — gather info, generate a brief, create project folders, and summarize next steps.
---

# Onboard Client

Walk the user through onboarding a new freelance client.

1. Ask for the **client name** and the **services** they need (ask both up front; ask follow-ups only if needed).
2. Use the `client-brief-generator` skill to gather the remaining brief details and produce the brief.
3. Create this project folder structure (only the folders that do not already exist):
   - `client-briefs/`
   - `content/drafts/`
   - `content/published/`
   - `reports/`
4. Save the brief to `client-briefs/<client-name>-brief.md` (client name lowercased and hyphenated).
5. Summarize what was created and list 3–5 concrete next steps (e.g., kickoff call, first content draft, reporting cadence).
```

- [ ] **Step 2: Validate**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS. Every command needs YAML frontmatter with a `description`.

- [ ] **Step 3: Commit**

```bash
cd my-freelancer-plugin
git add commands/onboard-client.md
git commit -m "feat: add onboard-client command"
cd ..
```

---

## Task 4: weekly-report command

**Files:**
- Create: `my-freelancer-plugin/commands/weekly-report.md`

- [ ] **Step 1: Write the command**

File: `my-freelancer-plugin/commands/weekly-report.md`
```markdown
---
description: Generate a professional weekly client report — work completed, content created, hours, blockers, and next week's plan.
---

# Weekly Report

Generate a professional weekly report for a freelance client.

Gather (or infer from the current project folders and recent work) and then produce a report containing:

1. **Work completed** this week — bullet list
2. **Content created** — list items, with paths/links where available (check `content/drafts/` and `content/published/`)
3. **Estimated hours** — a reasonable estimate, broken down by activity
4. **Blockers** — anything waiting on the client or external factors
5. **Next week's plan** — 3–5 planned items

Format as clean Markdown with a title and the report date. Save to `reports/weekly-report-<date>.md` using today's date in `YYYY-MM-DD` format. Create the `reports/` folder if needed, then tell the user the exact file path.
```

- [ ] **Step 2: Validate**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
cd my-freelancer-plugin
git add commands/weekly-report.md
git commit -m "feat: add weekly-report command"
cd ..
```

---

## Task 5: quality-check hook + shared helper + hooks.json

**Files:**
- Create: `my-freelancer-plugin/hooks/json-utils.sh`
- Create: `my-freelancer-plugin/hooks/quality-check.sh`
- Create: `my-freelancer-plugin/hooks/hooks.json`

- [ ] **Step 1: Write the shared JSON helper**

File: `my-freelancer-plugin/hooks/json-utils.sh`
```bash
#!/usr/bin/env bash
# json-utils.sh — shared helpers for the freelancer-toolkit hooks.

# Echo tool_input.file_path from a JSON hook payload passed as $1.
# Tries jq, then python3/python, then a grep/sed fallback so it works
# across environments (including Windows git-bash without jq).
extract_file_path() {
  local payload="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r '.tool_input.file_path // empty'
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$payload" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))'
  elif command -v python >/dev/null 2>&1; then
    printf '%s' "$payload" | python -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))'
  else
    printf '%s' "$payload" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed 's/.*:[[:space:]]*"//; s/"$//'
  fi
}
```

- [ ] **Step 2: Write the quality-check hook**

File: `my-freelancer-plugin/hooks/quality-check.sh`
```bash
#!/usr/bin/env bash
# quality-check.sh — PostToolUse hook.
# After Claude writes/edits a content file, warn if it's short or has placeholders.

# Resolve this script's directory so we can source the sibling helper whether
# invoked via ${CLAUDE_PLUGIN_ROOT} or run standalone for testing.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/json-utils.sh"

# Read the hook payload (JSON) from stdin.
input="$(cat)"
file_path="$(extract_file_path "$input")"

# Nothing to check without a path.
if [ -z "$file_path" ]; then
  exit 0
fi

# Only check content files.
case "$file_path" in
  *.md|*.txt|*.html) ;;
  *) exit 0 ;;
esac

# The file must exist to inspect it.
if [ ! -f "$file_path" ]; then
  exit 0
fi

# Word count.
words="$(wc -w < "$file_path" | tr -d '[:space:]')"
if [ "${words:-0}" -lt 200 ]; then
  echo "⚠️  quality-check: '$file_path' has only $words words (under 200)." >&2
fi

# Placeholder text check (case-insensitive).
if grep -Eiq 'lorem ipsum|TODO|FIXME|placeholder' "$file_path"; then
  echo "⚠️  quality-check: '$file_path' contains placeholder text (lorem ipsum / TODO / FIXME / placeholder)." >&2
fi

exit 0
```

- [ ] **Step 3: Write the hook manifest**

File: `my-freelancer-plugin/hooks/hooks.json`
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/quality-check.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 4: Ensure LF line endings on the scripts**

Run:
```bash
file my-freelancer-plugin/hooks/quality-check.sh my-freelancer-plugin/hooks/json-utils.sh
```
Expected: NOT "with CRLF line terminators". If it says CRLF, fix with:
```bash
sed -i 's/\r$//' my-freelancer-plugin/hooks/quality-check.sh my-freelancer-plugin/hooks/json-utils.sh
```

- [ ] **Step 5: Smoke-test the hook directly (the functional test)**

Run (simulates a PostToolUse payload for a short file):
```bash
printf 'short content with a TODO\n' > /tmp/qc-test.md
echo '{"tool_input":{"file_path":"/tmp/qc-test.md"}}' | bash my-freelancer-plugin/hooks/quality-check.sh
```
Expected: prints two warnings to stderr — one about being under 200 words, one about placeholder text. Exit code 0.

- [ ] **Step 6: Validate the plugin**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS (valid `hooks.json` schema).

- [ ] **Step 7: Commit**

```bash
cd my-freelancer-plugin
git add hooks/json-utils.sh hooks/quality-check.sh hooks/hooks.json
git commit -m "feat: add quality-check PostToolUse hook"
cd ..
```

---

## Task 6: GitHub MCP server config

**Files:**
- Create: `my-freelancer-plugin/.mcp.json`

- [ ] **Step 1: Write the MCP config**

File: `my-freelancer-plugin/.mcp.json` (plugin root — NOT inside a subfolder)
```json
{
  "github": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/",
    "headers": {
      "Authorization": "Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}"
    }
  }
}
```
Note: the secret is referenced via the `${GITHUB_PERSONAL_ACCESS_TOKEN}` environment variable — no token is stored in the file. (Setup instructions go in the README in Task 10.)

- [ ] **Step 2: Validate**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
cd my-freelancer-plugin
git add .mcp.json
git commit -m "feat: bundle GitHub MCP server config"
cd ..
```

---

## Task 7: log-changes hook (Lesson 5, Part 2 — Option A)

**Files:**
- Create: `my-freelancer-plugin/hooks/log-changes.sh`
- Modify: `my-freelancer-plugin/hooks/hooks.json`

- [ ] **Step 1: Write the log-changes hook**

File: `my-freelancer-plugin/hooks/log-changes.sh`
```bash
#!/usr/bin/env bash
# log-changes.sh — PostToolUse hook.
# Appends the path of every file Claude writes/edits to changelog.txt.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/json-utils.sh"

input="$(cat)"
file_path="$(extract_file_path "$input")"

if [ -n "$file_path" ]; then
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "$ts  $file_path" >> changelog.txt
fi

exit 0
```

- [ ] **Step 2: Register it in `hooks.json` (replace the whole file)**

File: `my-freelancer-plugin/hooks/hooks.json`
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/quality-check.sh\"",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/log-changes.sh\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 3: Fix line endings if needed**

Run:
```bash
file my-freelancer-plugin/hooks/log-changes.sh
```
Expected: not CRLF. If CRLF: `sed -i 's/\r$//' my-freelancer-plugin/hooks/log-changes.sh`

- [ ] **Step 4: Smoke-test the hook (functional test)**

Run:
```bash
echo '{"tool_input":{"file_path":"/tmp/qc-test.md"}}' | bash my-freelancer-plugin/hooks/log-changes.sh
cat changelog.txt
```
Expected: `changelog.txt` now contains a line with a timestamp and `/tmp/qc-test.md`. (This `changelog.txt` is git-ignored in Task 8.)

- [ ] **Step 5: Validate**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd my-freelancer-plugin
git add hooks/log-changes.sh hooks/hooks.json
git commit -m "feat: add log-changes PostToolUse hook"
cd ..
```

---

## Task 8: Research + review agents and the research-and-write command

**Files:**
- Create: `my-freelancer-plugin/agents/research-agent.md`
- Create: `my-freelancer-plugin/agents/review-agent.md`
- Create: `my-freelancer-plugin/commands/research-and-write.md`
- Create: `my-freelancer-plugin/.gitignore`

- [ ] **Step 1: Write the research agent**

File: `my-freelancer-plugin/agents/research-agent.md`
```markdown
---
name: research-agent
description: Researches a topic by finding 3–5 credible sources and summarizing the key points for a writer to use.
model: sonnet
---

You are a research assistant for content writing.

Given a topic and optional keywords:
1. Use web search to find 3–5 credible, recent sources (prefer primary sources, established publications, and official docs).
2. For each source capture: title, URL, and 2–4 bullet-point takeaways.
3. Note any conflicting claims or gaps you noticed.

Return a concise Markdown summary: a short overview paragraph, then a "Sources" list with takeaways under each. Do NOT write the article — only gather and summarize.
```

- [ ] **Step 2: Write the review agent**

File: `my-freelancer-plugin/agents/review-agent.md`
```markdown
---
name: review-agent
description: Reviews a draft blog post for SEO, factual accuracy, and overall quality, returning scores and concrete fixes.
model: sonnet
---

You are an editorial reviewer for SEO blog content.

Given a draft (path or text):
1. Evaluate **SEO** — title, keyword usage, headings, meta-readiness, structure.
2. Evaluate **accuracy** — claims that seem unsupported or need a citation.
3. Evaluate **quality** — clarity, flow, tone, and value to the reader.

Return:
- Four scores out of 10: SEO, Accuracy, Quality, and an Overall score.
- A short prioritized list of concrete fixes (most impactful first), referencing exact sentences or sections.

Do NOT rewrite the whole post — recommend changes.
```

- [ ] **Step 3: Write the research-and-write command**

File: `my-freelancer-plugin/commands/research-and-write.md`
```markdown
---
description: Research a topic with sources, write an 800–1200 word SEO blog post, then review it for quality.
---

# Research and Write

Produce a researched, reviewed blog post on the topic the user provides.

1. Ask for the **topic** and the **target keyword(s)** if not provided.
2. Dispatch the `research-agent` to find 3–5 credible sources and summarize the key points.
3. Using the research, write an **800–1200 word** SEO-optimized blog post: a clear H1, scannable H2/H3 sections, the target keyword used naturally in the title, intro, and a few headings, and a short conclusion with a call to action.
4. Save the draft to `content/drafts/<slug>.md` (slug = lowercased, hyphenated title). Create the folder if needed.
5. Dispatch the `review-agent` to score the draft (SEO, accuracy, quality, overall) and list concrete improvements.
6. Apply the high-value fixes from the review, then show the user the final draft path and the review summary.
```

- [ ] **Step 4: Add `.gitignore` so runtime output is never published**

File: `my-freelancer-plugin/.gitignore`
```
# Runtime output generated by the plugin's commands/hooks — not part of the plugin.
client-briefs/
content/
reports/
changelog.txt
```

- [ ] **Step 5: Validate**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS. Agents need `name` + `description` frontmatter; the command needs `description`.

- [ ] **Step 6: Commit**

```bash
cd my-freelancer-plugin
git add agents/research-agent.md agents/review-agent.md commands/research-and-write.md .gitignore
git commit -m "feat: add research/review agents and research-and-write command"
cd ..
```

---

## Task 9: marketplace.json

**Files:**
- Create: `my-freelancer-plugin/.claude-plugin/marketplace.json`

- [ ] **Step 1: Write the marketplace index**

File: `my-freelancer-plugin/.claude-plugin/marketplace.json`
```json
{
  "name": "freelancer-toolkit-marketplace",
  "owner": {
    "name": "Ranniel Abueg",
    "email": "arca2@briarbear.ai"
  },
  "metadata": {
    "description": "Freelancer toolkit plugin marketplace"
  },
  "plugins": [
    {
      "name": "freelancer-toolkit",
      "description": "A freelancer's toolkit for client onboarding, content creation, and project management",
      "source": "./"
    }
  ]
}
```
Note: `source: "./"` means "this same repo is the plugin" — so one GitHub repo serves as both marketplace and plugin.

- [ ] **Step 2: Validate**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS, including the marketplace manifest.

- [ ] **Step 3: Commit**

```bash
cd my-freelancer-plugin
git add .claude-plugin/marketplace.json
git commit -m "feat: add marketplace.json (repo doubles as its own marketplace)"
cd ..
```

---

## Task 10: README.md

**Files:**
- Create: `my-freelancer-plugin/README.md`

- [ ] **Step 1: Write the README**

File: `my-freelancer-plugin/README.md`
```markdown
# Freelancer Toolkit

A Claude Code plugin that bundles a freelancer's everyday workflow — client onboarding, content creation, and weekly reporting — into one installable package. It includes a skill, three slash commands, two subagents, two hooks, and an optional GitHub MCP integration.

## What's inside

| Type | Name | What it does |
| --- | --- | --- |
| Skill | `client-brief-generator` | Auto-triggers on client/brief intent; produces a structured client brief and saves it to `client-briefs/`. |
| Command | `/freelancer-toolkit:onboard-client` | Full onboarding flow: gather info, generate a brief, scaffold project folders, list next steps. |
| Command | `/freelancer-toolkit:weekly-report` | Generates a weekly client report and saves it to `reports/`. |
| Command | `/freelancer-toolkit:research-and-write` | Researches a topic, writes an 800–1200 word SEO post, then reviews it. |
| Agent | `research-agent` | Finds and summarizes 3–5 credible sources. |
| Agent | `review-agent` | Scores a draft for SEO, accuracy, and quality. |
| Hook | `quality-check` (PostToolUse) | Warns when a written content file is short or contains placeholder text. |
| Hook | `log-changes` (PostToolUse) | Appends every written file path to `changelog.txt`. |
| MCP | `github` | Optional GitHub MCP server for repos, issues, and PRs. |

## Install

From this GitHub repo (replace `<your-username>`):

```
/plugin marketplace add <your-username>/freelancer-toolkit
/plugin install freelancer-toolkit@freelancer-toolkit-marketplace
/reload-plugins
```

Or from a local path during development:

```
/plugin marketplace add C:\GitHub\ClaudeCodePlugins\my-freelancer-plugin
/plugin install freelancer-toolkit@freelancer-toolkit-marketplace
/reload-plugins
```

## Commands

- `/freelancer-toolkit:onboard-client` — onboard a new client end to end.
- `/freelancer-toolkit:weekly-report` — produce this week's client report.
- `/freelancer-toolkit:research-and-write` — research, draft, and review a blog post.

## How the hooks work

Both hooks fire on `PostToolUse` for `Write|Edit` (registered in `hooks/hooks.json`):

- **quality-check** reads the tool payload, and for `.md`/`.txt`/`.html` files warns if the file is under 200 words or contains `lorem ipsum` / `TODO` / `FIXME` / `placeholder`.
- **log-changes** appends a timestamped line with the file path to `changelog.txt`.

Hook scripts run under bash and must keep LF line endings.

## How the MCP integration works

The plugin ships `.mcp.json` with a GitHub MCP server over HTTP. It authenticates with a personal access token read from the `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable — no secret is stored in the repo.

To enable it:
1. Create a GitHub personal access token (classic or fine-grained) with the scopes you need (e.g. `repo`).
2. Set the environment variable before launching Claude Code:
   - PowerShell: `$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_xxx"`
   - bash: `export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx`
3. Restart Claude Code. The `github` MCP tools become available. If the variable is unset, the rest of the plugin still works — only the GitHub MCP server is unavailable.

## License

MIT (or your preference).
```

- [ ] **Step 2: Validate**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
cd my-freelancer-plugin
git add README.md
git commit -m "docs: add README with install, hooks, and MCP setup"
cd ..
```

---

## Task 11: Audit + local install test

**Files:** none (verification only; fix forward if issues are found)

- [ ] **Step 1: Full validation**

Run:
```bash
claude plugin validate my-freelancer-plugin
```
Expected: PASS with no errors.

- [ ] **Step 2: Add the local marketplace inside this Claude Code session**

In the Claude Code prompt:
```
/plugin marketplace add C:\GitHub\ClaudeCodePlugins\my-freelancer-plugin
```
Expected: "Successfully added marketplace: freelancer-toolkit-marketplace".

- [ ] **Step 3: Install and reload**

```
/plugin install freelancer-toolkit@freelancer-toolkit-marketplace
/reload-plugins
```
Expected: install confirmation; reload reports the plugin's skills/commands/agents/hooks loaded.

- [ ] **Step 4: Verify the commands are registered**

```
/plugin list
```
Expected: `freelancer-toolkit` appears as enabled. The three namespaced commands are available:
```
/freelancer-toolkit:onboard-client
/freelancer-toolkit:weekly-report
/freelancer-toolkit:research-and-write
```

- [ ] **Step 5: Functional run — onboard-client**

Run `/freelancer-toolkit:onboard-client`, answer the prompts with a test client (e.g., "Acme Co", "social media management"). 
Expected: a brief saved to `client-briefs/acme-co-brief.md`, the `content/` and `reports/` folders created, and a next-steps summary. The `quality-check`/`log-changes` hooks fire on the brief write (watch for a quality warning if the brief is short; check `changelog.txt` gained a line).

- [ ] **Step 6: If anything fails, debug and fix, then re-validate**

Re-run `claude plugin validate my-freelancer-plugin` and re-test the failing command until green. Commit any fixes:
```bash
cd my-freelancer-plugin
git add -A
git commit -m "fix: address issues found in local install test"
cd ..
```

---

## Task 12: Publish to GitHub

**Files:** none (git/GitHub operations)

- [ ] **Step 1: Confirm GitHub CLI auth**

Run:
```bash
gh auth status
```
Expected: logged in. If not, run an interactive login from the session prompt: type `! gh auth login` and follow the browser flow.

- [ ] **Step 2: Capture your GitHub username (used for the install command later)**

Run:
```bash
gh api user -q .login
```
Expected: prints your GitHub login (e.g., `ranniel-abueg`). Note it for Task 13.

- [ ] **Step 3: Confirm the plugin repo has all commits**

Run:
```bash
cd my-freelancer-plugin
git status
git log --oneline
cd ..
```
Expected: clean working tree; commits from Tasks 1–11 present. Runtime folders (`client-briefs/`, `content/`, `reports/`, `changelog.txt`) are untracked/ignored.

- [ ] **Step 4: Create the public repo and push**

Run:
```bash
cd my-freelancer-plugin
gh repo create freelancer-toolkit --public --source=. --remote=origin --push
cd ..
```
Expected: a new public repo `freelancer-toolkit` is created and `main` is pushed. Print the URL.

- [ ] **Step 5: Verify the remote contents**

Run:
```bash
cd my-freelancer-plugin
gh repo view --web
cd ..
```
Expected: the repo shows `.claude-plugin/`, `skills/`, `commands/`, `agents/`, `hooks/`, `.mcp.json`, and `README.md`. No client data or `changelog.txt`.

---

## Task 13: Test install from GitHub

**Files:** none (end-to-end verification)

- [ ] **Step 1: Add the marketplace from GitHub in a fresh Claude Code session**

Open a new Claude Code session and run (use the username from Task 12, Step 2):
```
/plugin marketplace add <your-username>/freelancer-toolkit
```
Expected: "Successfully added marketplace: freelancer-toolkit-marketplace".

- [ ] **Step 2: Install and reload**

```
/plugin install freelancer-toolkit@freelancer-toolkit-marketplace
/reload-plugins
```
Expected: install + reload succeed.

- [ ] **Step 3: Run each command end-to-end**

```
/freelancer-toolkit:onboard-client
/freelancer-toolkit:weekly-report
/freelancer-toolkit:research-and-write
```
Expected: all three run, producing the brief, the report, and a researched/reviewed draft respectively.

- [ ] **Step 4: Final checkpoint**

Confirm the goal is met: **Install → Validate → Run commands → Works from GitHub.** If anything fails, debug, fix in `my-freelancer-plugin/`, commit, push, then re-test:
```bash
cd my-freelancer-plugin
git add -A
git commit -m "fix: resolve install-from-GitHub issue"
git push
cd ..
```

---

## Spec coverage (self-review)

| Spec (Week-4-Day-2.md) | Covered by |
| --- | --- |
| Lesson 4, Step 1 — skeleton + `plugin.json` | Task 1 |
| Lesson 4, Step 2 — `client-brief-generator` skill | Task 2 |
| Lesson 4, Step 3 — `onboard-client` + `weekly-report` commands | Tasks 3, 4 |
| Lesson 4, Step 4 — `quality-check` hook + `hooks.json` | Task 5 |
| Lesson 5, Part 1 — `.mcp.json` (GitHub) + README MCP setup | Tasks 6, 10 |
| Lesson 5, Part 2 — second hook (Option A: log-changes) | Task 7 |
| Lesson 5, Part 3 — research/review agents + `research-and-write` | Task 8 |
| Lesson 6, Step 1 — audit | Task 11 |
| Lesson 6, Step 2 — `marketplace.json` | Task 9 |
| Lesson 6, Step 3 — README | Task 10 |
| Lesson 6, Step 4 — local install test | Task 11 |
| Lesson 6, Step 5 — push to GitHub | Task 12 |
| Lesson 6, Step 6 — install from GitHub | Task 13 |

**Type/name consistency check:** skill name `client-brief-generator`; agents `research-agent` / `review-agent`; commands `onboard-client` / `weekly-report` / `research-and-write`; helper function `extract_file_path` (defined in `json-utils.sh`, used by both hooks); MCP server key `github`; marketplace name `freelancer-toolkit-marketplace`; plugin name `freelancer-toolkit`. These names match everywhere they appear.
