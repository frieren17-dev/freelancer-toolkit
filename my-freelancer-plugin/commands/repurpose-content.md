---
description: Repurpose an existing blog post or draft into platform-native social media posts (LinkedIn, X, Instagram, …), save them to content/social/, then review them. Uses the repurpose-agent to write the posts and the social-review-agent to score them.
argument-hint: "[draft path] [--platforms linkedin,x,instagram]"
---

# Repurpose Content into Social Posts

Turn an existing content piece into platform-native social media posts, save them, and
review them. Work through these steps in order, keeping the user informed as you go.

## 1. Resolve the source content

Parse **$ARGUMENTS**:

- If it contains a file path, read that file as the source content.
- If no path was given, list the markdown files in `content/drafts/` (and
  `content/published/` if it exists) and ask the user which one to repurpose. If those
  folders are empty or missing, ask the user to paste the content or run
  `/research-and-write` first.

## 2. Resolve the target platforms

- Default to **LinkedIn, X (Twitter), and Instagram**.
- If `--platforms` is present in the arguments, use that comma-separated list instead
  (e.g. `--platforms linkedin,instagram`).

## 3. Resolve brand voice (optional)

If the source draft is tied to a client, or the user names one, look for a matching
brief in `client-briefs/` and use its **Brand Voice** (and **Platforms**, if the user
didn't specify any) to guide tone. If there's no brief, use a clear, professional-but-
human default — don't guess at a brand voice.

## 4. Generate the posts

Delegate to the **repurpose-agent** subagent. Pass it:

- the source content,
- the target platforms, and
- the brand voice, if you found one.

Wait for its posts before continuing. The posts must stay faithful to the source — do
not introduce facts, stats, or quotes that aren't in the original.

## 5. Save the posts

Save the repurposed posts to `content/social/<source-slug>-social.md`, relative to the
current working directory:

- **Derive the slug** from the source filename or title (lowercase; spaces and
  punctuation → hyphens; collapse repeated hyphens). Example: source
  `content/drafts/remote-work-trends.md` → `content/social/remote-work-trends-social.md`.
- **Create the `content/social/` folder** if it doesn't already exist.
- **Don't silently overwrite.** If that file exists, ask whether to overwrite or save
  under a new name.

Confirm the exact saved file path.

## 6. Review

Delegate to the **social-review-agent** subagent to review the saved file. It returns a
per-platform report with an overall **score out of 10** and a prioritized list of fixes.

## 7. Report and offer to revise

Show the user:

- The saved file path.
- The social-review-agent's **score** and its **top prioritized fixes**.

Then offer to apply the suggested fixes. If the user agrees, revise the posts, save
them back to the same path, and briefly summarize what changed.
