# freelancer-toolkit

A **Claude Code plugin** — and the marketplace that hosts it — for client onboarding, content creation, and project management. Built for solo freelancers and small studios who want Claude to run the repetitive parts of the job end-to-end.

> This repository is both a **plugin** ([`my-freelancer-plugin/`](my-freelancer-plugin/)) and a **Claude Code marketplace** ([`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)), so you can install the plugin straight from this repo.

---

## What it does

- **Onboard a client** in one command — collect a structured brief and scaffold the project folders.
- **Produce content** — research-backed blog posts, then repurpose them into platform-native social posts, each with an automatic quality review.
- **Report progress** — generate a clean, client-ready weekly status report.
- **Stay connected to GitHub** — an optional MCP server for issues, PRs, and repos.

Under the hood it ships **1 skill**, **4 slash commands**, **4 subagents**, **2 hooks**, and **1 MCP server**. Full details live in the plugin README: **[my-freelancer-plugin/README.md](my-freelancer-plugin/README.md)**.

---

## Install

This repo is a Claude Code marketplace, so you can register it and install the plugin directly:

```text
# 1. Register this repo as a marketplace (GitHub shorthand, git URL, or local path all work)
/plugin marketplace add frieren17-dev/freelancer-toolkit

# 2. Install the plugin
/plugin install freelancer-toolkit@freelancer-toolkit-marketplace

# 3. Reload
/reload-plugins        # or restart Claude Code
```

Or run `/plugin` to open the interactive plugin manager and install it from there. After installing, run `/help` and the four commands below should appear.

---

## The commands

| Command | What it does |
|---------|--------------|
| `/onboard-client [client name]` | Collects a full client brief, scaffolds project folders, and lists tailored next steps. |
| `/research-and-write [topic]` | Researches a topic, writes an 800–1200-word blog post, then reviews it for SEO and accuracy. |
| `/repurpose-content [draft] [--platforms …]` | Turns a draft into platform-native social posts (LinkedIn, X, Instagram, …), then reviews them. |
| `/weekly-report [notes]` | Generates a polished, client-ready weekly status report. |

`/research-and-write` → `/repurpose-content` are designed to chain: write the post, then turn it into social posts.

---

## Repository layout

```text
.
├── .claude-plugin/
│   └── marketplace.json         # marketplace manifest (lists the plugin)
├── my-freelancer-plugin/        # the plugin itself
│   ├── .claude-plugin/plugin.json
│   ├── .mcp.json                # github MCP server (env-var driven, no secrets)
│   ├── agents/                  # 4 subagents
│   ├── commands/                # 4 slash commands
│   ├── hooks/                   # 2 PostToolUse hooks
│   ├── skills/                  # client-brief-generator
│   └── README.md                # ← full documentation
└── docs/superpowers/            # design specs & implementation plan
```

---

## Requirements

- **Claude Code** (manifests validate against `claude plugin validate`).
- **A `bash` shell** for the hooks — Git Bash on Windows; native on macOS/Linux. `jq` is optional.
- **A GitHub Personal Access Token** *only if* you want the `github` MCP server. Everything else works without it.

See the [plugin README](my-freelancer-plugin/README.md) for full setup, including how the hooks and the GitHub MCP server work.

---

## License

No license file is included yet — add one if you intend others to reuse this.
