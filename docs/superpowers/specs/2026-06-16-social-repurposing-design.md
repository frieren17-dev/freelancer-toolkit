# Social Media Repurposing Workflow Design — repurpose-content

**Date:** 2026-06-16
**Plugin:** freelancer-toolkit (`my-freelancer-plugin`)
**Status:** Approved (Approach A — creator + reviewer pair)

## Goal

Turn an existing long-form content piece (a blog post/draft) into platform-native
social media posts, save them, and review them for platform fit and quality. Closes
the content loop with `/research-and-write` and the existing `content/` folders.

## Components

### 1. `agents/repurpose-agent.md` (subagent)

- **Frontmatter:** `name: repurpose-agent`, auto-delegation `description`, `tools: Read`.
- **Job:** Given source content + target platforms, produce **native** posts per
  platform following each platform's length, tone, and hashtag conventions
  (LinkedIn, X/Twitter, Instagram, extensible to others). Preserves the source's core
  message and facts; no fabrication.
- **Output:** Markdown, one section per platform, posts in copy-pasteable blocks, with
  a char count noted for length-sensitive platforms (X).

### 2. `agents/social-review-agent.md` (subagent)

- **Frontmatter:** `name: social-review-agent`, auto-delegation `description`, `tools: Read`.
- **Job:** Review the generated posts on five axes — **platform fit** (char limits,
  format), **hook strength**, **brand-voice consistency**, **hashtag relevance**, and
  **CTA presence** — plus an accuracy check against the source. Returns a per-platform
  ✅/⚠️/❌ report with an overall **score 1–10** and prioritized fixes.

### 3. `commands/repurpose-content.md` (slash command)

- **Frontmatter:** `description`, `argument-hint: [draft path] [--platforms linkedin,x,instagram]`.
- **Flow:**
  1. Resolve source from `$ARGUMENTS`; if missing, list `content/drafts/` (and
     `content/published/`) and ask which file to repurpose.
  2. Resolve target platforms — default **LinkedIn, X, Instagram**; override via
     `--platforms`.
  3. Optionally read a matching client brief from `client-briefs/` for **brand voice**
     and platforms; otherwise neutral-professional.
  4. Delegate to **repurpose-agent** → platform-native posts.
  5. Save to **`content/social/<slug>-social.md`** (create folder; ask before overwrite).
  6. Delegate to **social-review-agent** on the saved file.
  7. Show the score + top fixes; offer to apply them.

## Decisions

- **New folder `content/social/`** for output, alongside `content/drafts/` and
  `content/published/`.
- **Default platforms:** LinkedIn, X, Instagram.
- **Brand voice:** auto-used only if a matching client brief is found or named.
- **Slugify:** same rule as the rest of the plugin (lowercase, punctuation → hyphens,
  collapse repeats).
- **README:** add the two agents + command to the component table.
- **Models:** agents omit `model` and inherit the session model.

## Out of scope (YAGNI)

- Auto-posting via social APIs / MCP.
- Image, thumbnail, or video generation.
- Scheduling.

## Success criteria

- `/repurpose-content content/drafts/<slug>.md` produces native posts for the chosen
  platforms saved to `content/social/<slug>-social.md`, followed by a review report
  with a 1–10 score and actionable fixes.
- Both agents have valid frontmatter and auto-delegate on relevant requests.
