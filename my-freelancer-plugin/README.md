# freelancer-toolkit

A freelancer's toolkit for **client onboarding, content creation, and project management** — packaged as a Claude Code plugin.

It bundles everything a solo freelancer or small studio reaches for repeatedly, so Claude can run the busywork end-to-end:

- **Onboard a client** in one command — collect a structured brief and scaffold the project folders.
- **Produce content** — research-backed blog posts, then repurpose them into platform-native social posts, each with an automatic quality review.
- **Report progress** — generate a clean, client-ready weekly status report.
- **Stay connected to GitHub** — an optional MCP server for issues, PRs, and repos.

Under the hood it ships a **skill**, four **slash commands**, four **subagents**, two **hooks**, and one **MCP server**.

---

## What's inside

| Component | Name | What it does |
|-----------|------|--------------|
| Skill | `client-brief-generator` | Gathers 10 client/project fields and produces a clean markdown brief saved to `client-briefs/`. |
| Command | `/onboard-client` | Full client onboarding: brief + project folder scaffolding + next steps. |
| Command | `/weekly-report` | Generates a professional weekly status report into `reports/`. |
| Command | `/research-and-write` | Researches a topic, writes an 800–1200-word blog post into `content/drafts/`, then reviews it. Orchestrates the research-agent + review-agent. |
| Command | `/repurpose-content` | Repurposes a draft into platform-native social posts (LinkedIn, X, Instagram, …) saved to `content/social/`, then reviews them. Orchestrates the repurpose-agent + social-review-agent. |
| Agent | `research-agent` | Finds 3–5 credible sources on a topic and returns a structured digest (title, URL, publisher, date, summary, key facts). |
| Agent | `review-agent` | Reviews a draft for SEO and factual accuracy, scores its quality 1–10, and lists prioritized fixes. |
| Agent | `repurpose-agent` | Repurposes a content piece into platform-native social posts (LinkedIn, X, Instagram, …), honoring each platform's length, tone, and hashtag conventions. |
| Agent | `social-review-agent` | Reviews repurposed social posts for platform fit, hook strength, brand voice, hashtags, and CTA; scores them 1–10 with fixes. |
| Hook | `quality-check.sh` (PostToolUse) | After every Write/Edit, warns on thin content (<200 words) or placeholder text (`lorem ipsum`/`TODO`) in `.md`/`.txt`/`.html` files. |
| Hook | `log-changes.sh` (PostToolUse) | After every Write, appends a timestamped line for the created file to `changelog.txt`. |
| MCP server | `github` | Connects Claude to GitHub (issues, PRs, repos) via the remote GitHub MCP server. See [How MCP works](#how-mcp-works-github). |

### Requirements

- **Claude Code** (the plugin manifests validate against `claude plugin validate`).
- **A `bash` shell** for the hooks. On Windows this is provided by Git Bash; macOS/Linux have it natively. `jq` is optional — the hooks fall back to a built-in parser if it's missing.
- **A GitHub Personal Access Token** *only if* you want the `github` MCP server (everything else works without it).

---

## Installation

This repository is also a **Claude Code marketplace** (it ships a `.claude-plugin/marketplace.json` named `freelancer-toolkit-marketplace`), so you can install the plugin directly from it.

### Option A — install from the marketplace (recommended)

```text
# 1. Register this repo as a marketplace (GitHub shorthand, git URL, or local path all work)
/plugin marketplace add <owner>/<repo>
#   e.g. local checkout:  /plugin marketplace add C:/GitHub/ClaudeCodePlugins

# 2. Install the plugin
/plugin install freelancer-toolkit@freelancer-toolkit-marketplace

# 3. Reload
/reload-plugins        # or restart Claude Code
```

You can also just run `/plugin` to open the interactive plugin manager and install it from there.

### Option B — local development

If you're hacking on the plugin in this repo, point Claude Code at the local marketplace and install as above, then re-run `/reload-plugins` after each change to pick up edits.

After installation, run `/help` — the four slash commands below should appear, namespaced under the plugin if needed (e.g. `/freelancer-toolkit:onboard-client`).

> The `github` MCP server needs two environment variables before it will connect. That's optional and covered in [How MCP works](#how-mcp-works-github).

---

## Slash commands

All four commands are conversational — if you omit an argument, Claude asks for what it needs. Each one tells you exactly which files it created.

### `/onboard-client [client name]`

End-to-end onboarding for a new client.

- **What it does:** collects a full client brief (via the `client-brief-generator` skill), scaffolds the standard project folders, saves the brief, and lists tailored next steps.
- **Creates:** `client-briefs/`, `content/drafts/`, `content/published/`, `reports/` (only if missing), and `client-briefs/<client-slug>-brief.md`.
- **Example:**
  ```text
  /onboard-client Acme Co.
  ```
  Claude batches any missing brief questions into one message, writes `client-briefs/acme-co-brief.md`, and finishes with 3–5 concrete next steps.

### `/weekly-report [optional: week-ending date or quick notes]`

A polished, client-ready weekly status report.

- **What it does:** gathers work completed, content created, estimated hours, blockers, and next week's plan — pre-filling from your notes and the `content/`/`reports/` folders where it can — then formats and saves the report.
- **Creates:** `reports/weekly-report-<YYYY-MM-DD>.md`.
- **Example:**
  ```text
  /weekly-report shipped landing page, 3 LinkedIn posts, ~12h, blocked on logo assets
  ```

### `/research-and-write [topic]`

Produces a researched, reviewed blog post. **Orchestrates two agents.**

- **Flow:** `research-agent` gathers 3–5 credible sources → Claude writes an **800–1200-word** post grounded in them → saves it → `review-agent` scores it 1–10 on SEO, accuracy, and quality, with prioritized fixes → offers to apply them.
- **Creates:** `content/drafts/<topic-slug>.md`.
- **Example:**
  ```text
  /research-and-write the rise of remote work in 2026
  ```

### `/repurpose-content [draft path] [--platforms linkedin,x,instagram]`

Turns an existing piece into platform-native social posts. **Orchestrates two agents.**

- **Flow:** reads the source draft (if you omit the path, it lists `content/drafts/` and asks) → optionally pulls **brand voice** from a matching brief in `client-briefs/` → `repurpose-agent` writes native posts per platform → saves them → `social-review-agent` scores them 1–10 and lists fixes → offers to apply them.
- **Platforms:** defaults to **LinkedIn, X, Instagram**; override with `--platforms`.
- **Creates:** `content/social/<source-slug>-social.md`.
- **Example:**
  ```text
  /repurpose-content content/drafts/remote-work.md --platforms linkedin,x
  ```

> **The content pipeline:** `/research-and-write` → produces a draft → `/repurpose-content` → turns that same draft into social posts. The two commands are designed to chain.

### About the agents

The four agents (`research-agent`, `review-agent`, `repurpose-agent`, `social-review-agent`) are **subagents** the commands delegate to automatically — you don't normally invoke them by hand. Because each has a descriptive trigger, Claude may also auto-delegate to them when a relevant request comes up outside the commands (e.g. "review this draft for SEO").

---

## How hooks work

Hooks let the plugin run a script automatically in response to Claude's actions — no prompting required. Both of this plugin's hooks are **`PostToolUse`** hooks: they fire *after* a tool call completes.

They're registered in **`hooks/hooks.json`**, which maps a tool **matcher** to a command. Each command is invoked through `bash` and uses the **`${CLAUDE_PLUGIN_ROOT}`** variable, which Claude Code expands to the plugin's install directory — so the scripts are found no matter where the plugin lives:

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit", "hooks": [
        { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/quality-check.sh\"", "timeout": 10 } ] },
      { "matcher": "Write", "hooks": [
        { "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/log-changes.sh\"", "timeout": 10 } ] }
    ]
  }
}
```

Each hook receives the tool-call payload (JSON) on **stdin** and reads the affected file path from it.

### `quality-check.sh` — content quality guardrail

- **Fires after:** `Write` or `Edit`.
- **Checks:** for `.md` / `.txt` / `.html` files, it warns if the file has **fewer than 200 words** or contains **placeholder text** (`lorem ipsum` or `TODO`).
- **Behavior:** issues are written to **stderr** and the hook exits with code **2**, which feeds the warning back to Claude so it can fix the file. The write already happened — exit 2 does not undo it. Non-content files are ignored silently.

### `log-changes.sh` — change log

- **Fires after:** `Write` (file creation/overwrite).
- **Does:** appends a timestamped, tab-separated line — `<ISO-8601 timestamp>  Write  <file path>` — to **`changelog.txt`** in your project root (`${CLAUDE_PROJECT_DIR}`, falling back to the current directory).
- **Behavior:** best-effort and always exits `0`, so logging never blocks Claude's work.

### Customizing or disabling the hooks

- **Disable one:** remove its matcher block from `hooks/hooks.json` (then `/reload-plugins`).
- **Tune `quality-check.sh`:** change the 200-word threshold, the file extensions, or flip the final `exit 2` to `exit 0` to make warnings non-blocking (the script documents this inline).
- **Change the log location/format:** edit `log-changes.sh`.

---

## How MCP works (`github`)

MCP (Model Context Protocol) lets Claude talk to external services through a server. This plugin ships **one** MCP server, `github`, defined in `.mcp.json` at the plugin root (auto-discovered by Claude Code). It connects Claude to GitHub so it can work with issues, pull requests, and repositories.

The config deliberately contains **no secrets** — the URL and token are read from environment variables at runtime:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "${GITHUB_URL}",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
    }
  }
}
```

You provide two values: `GITHUB_URL` (the server endpoint) and `GITHUB_TOKEN` (your credential).

### Step 1 — Get a GitHub Personal Access Token (`GITHUB_TOKEN`)

1. Go to **GitHub → Settings → Developer settings → Personal access tokens**
   (direct link: <https://github.com/settings/personal-access-tokens>).
2. Click **Generate new token**. A **fine-grained** token is recommended.
3. Set an **expiration** and choose the **repositories** the token may access.
4. Grant the **minimum permissions** you actually need, for example:
   - **Contents:** Read-only (read code/files) — or Read & write if you want Claude to commit.
   - **Issues:** Read & write (create/update issues).
   - **Pull requests:** Read & write (open/review PRs).
   - **Metadata:** Read-only (required; auto-selected).
5. Click **Generate token** and **copy it immediately** — GitHub shows it only once. It looks like `github_pat_...` (fine-grained) or `ghp_...` (classic).

> Treat this token like a password. Anyone who has it can act as you on the repos it covers.

### Step 2 — Note the server URL (`GITHUB_URL`)

Use the official remote GitHub MCP server endpoint:

```text
https://api.githubcopilot.com/mcp/
```

### Step 3 — Set the environment variables

Claude Code reads these from the environment it launches in, so set them **persistently** and then **restart Claude Code**.

**Windows (PowerShell)** — persist for future sessions with `setx`:

```powershell
setx GITHUB_URL "https://api.githubcopilot.com/mcp/"
setx GITHUB_TOKEN "github_pat_your_token_here"
```

`setx` writes to your user environment but does **not** affect the current terminal. Open a **new** terminal (and restart Claude Code) afterward. To also set them in the current session immediately:

```powershell
$env:GITHUB_URL = "https://api.githubcopilot.com/mcp/"
$env:GITHUB_TOKEN = "github_pat_your_token_here"
```

**macOS / Linux (bash/zsh)** — add to `~/.zshrc` or `~/.bashrc`:

```bash
export GITHUB_URL="https://api.githubcopilot.com/mcp/"
export GITHUB_TOKEN="github_pat_your_token_here"
```

Then reload your shell (`source ~/.zshrc`) and restart Claude Code.

### Step 4 — Verify

Restart Claude Code and run `/mcp`. The `github` server should show as **connected**. If it shows an auth error, re-check that `GITHUB_TOKEN` is set in the environment Claude Code launched from and that the token hasn't expired.

### Environment variables reference

| Variable | Required | Example | Notes |
|----------|----------|---------|-------|
| `GITHUB_URL` | Yes | `https://api.githubcopilot.com/mcp/` | The MCP server endpoint. |
| `GITHUB_TOKEN` | Yes | `github_pat_…` / `ghp_…` | Your Personal Access Token. Sent as `Authorization: Bearer …`. |

---

## Files this plugin creates in your workspace

Relative to your current working directory:

| Path | Created by | Contents |
|------|-----------|----------|
| `client-briefs/<slug>-brief.md` | `/onboard-client`, `client-brief-generator` | The client brief table. |
| `content/drafts/<slug>.md` | `/research-and-write` | Blog post drafts. |
| `content/social/<slug>-social.md` | `/repurpose-content` | Platform-native social posts. |
| `content/published/` | `/onboard-client` (scaffold) | Where you move finished content. |
| `reports/weekly-report-<date>.md` | `/weekly-report` | Weekly status reports. |
| `changelog.txt` | `log-changes.sh` hook | Timestamped log of files Claude created. |

---

## Security notes

- **Never commit your token.** It lives only in environment variables; `.mcp.json` references them by name and contains no secrets, so it's safe to commit.
- If a token is ever exposed, **revoke it** at GitHub → Settings → Developer settings and generate a new one.
- Prefer **fine-grained tokens** scoped to only the repos and permissions you need, with a short expiration.

---

## Plugin structure

```text
my-freelancer-plugin/
├── .claude-plugin/
│   └── plugin.json              # plugin manifest (name, version, author)
├── .mcp.json                    # github MCP server (env-var driven)
├── agents/
│   ├── research-agent.md
│   ├── review-agent.md
│   ├── repurpose-agent.md
│   └── social-review-agent.md
├── commands/
│   ├── onboard-client.md
│   ├── weekly-report.md
│   ├── research-and-write.md
│   └── repurpose-content.md
├── hooks/
│   ├── hooks.json               # registers the two PostToolUse hooks
│   ├── quality-check.sh
│   └── log-changes.sh
├── skills/
│   └── client-brief-generator/
│       └── SKILL.md
└── README.md
```

> The marketplace manifest (`.claude-plugin/marketplace.json`) lives at the **repository root**, one level above this plugin — it's a marketplace-level file that lists the plugin, not part of the plugin itself.
