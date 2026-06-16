# Content Workflow Design — research-and-write

**Date:** 2026-06-16
**Plugin:** freelancer-toolkit (`my-freelancer-plugin`)
**Status:** Approved

## Goal

Add a research-backed blog-writing workflow to the plugin: two subagents plus a
slash command that orchestrates them to produce and review an 800–1200-word blog
post grounded in credible sources.

## Components

### 1. `agents/research-agent.md` (subagent)

- **Frontmatter:** `name: research-agent`, auto-delegation `description`,
  `tools: WebSearch, WebFetch` (read-only research; no file writes).
- **Job:** Given a topic, find **3–5 credible sources** and return a structured
  digest — for each source: title, URL, publisher/author, date, a 2–4 sentence
  summary, and key facts. Prefers primary/authoritative sources; flags weak ones.
- **Output:** Returns the digest as its final message; the command consumes it.

### 2. `agents/review-agent.md` (subagent)

- **Frontmatter:** `name: review-agent`, auto-delegation `description`,
  `tools: Read, WebSearch, WebFetch` (reads the draft; can spot-check claims).
- **Job:** Review a draft on three axes:
  - **SEO** — title, keyword usage, headings, meta description, length, structure.
  - **Accuracy** — claims supported by cited sources; no fabrication.
  - **Quality** — overall **score 1–10** with a prioritized list of concrete fixes.
- **Output:** A structured review report.

### 3. `commands/research-and-write.md` (slash command)

- **Frontmatter:** `description`, `argument-hint: [topic]`.
- **Flow:**
  1. Resolve topic from `$ARGUMENTS` (ask if missing).
  2. Delegate to **research-agent** → 3–5 sourced summaries.
  3. Write an **800–1200-word** post grounded in those sources (SEO title, intro,
     H2/H3 sections, conclusion, Sources list).
  4. Save to **`content/drafts/<topic-slug>.md`** (slugify; create folder; ask
     before overwriting).
  5. Delegate to **review-agent** on the saved draft.
  6. Present the score + suggestions; offer to apply the fixes.

## Decisions

- **Save location:** `content/drafts/` — consistent with `/onboard-client` and the
  existing folder convention.
- **Slugify:** lowercase, spaces/punctuation → hyphens, collapse repeats (same rule
  as the client-brief skill).
- **README:** add the two agents + new command to the component table.
- **Models:** agents omit `model` and inherit the session model.

## Out of scope (YAGNI)

- Auto-publishing to `content/published/`.
- Auto-revise loop that rewrites until the score clears a threshold.
- Posting via the GitHub MCP server.

## Success criteria

- `/research-and-write "<topic>"` produces a saved 800–1200-word draft grounded in
  3–5 real sources, followed by a review report with a 1–10 score and actionable
  fixes.
- Both agents have valid frontmatter and auto-delegate on relevant requests.
