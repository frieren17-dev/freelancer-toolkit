---
description: Research a topic, write an 800–1200-word blog post grounded in credible sources, then review it. Uses the research-agent to gather sources and the review-agent to score the draft on SEO, accuracy, and quality.
argument-hint: [topic]
---

# Research and Write a Blog Post

Produce a researched, reviewed blog post from a single topic. Work through these
steps in order, keeping the user informed as you go.

## 1. Resolve the topic

If a topic was passed as an argument, use it: **$ARGUMENTS**. Otherwise, ask the user
what topic they want a post about (and any angle or audience preference) before
continuing.

## 2. Research

Delegate to the **research-agent** subagent to gather **3–5 credible sources** on the
topic. Pass it the topic (and any angle the user specified). Wait for its research
digest before writing anything — the post must be grounded in what it returns, not in
assumptions.

If the research-agent reports it could find fewer than 3 credible sources, tell the
user and ask whether to proceed, broaden the topic, or stop.

## 3. Write the post

Using **only** the facts from the research digest, write an **800–1200-word** blog
post. Structure it as:

- An **SEO-friendly title** (H1) that includes the primary keyword.
- A short **meta description** (~150–160 characters) right under the title, e.g.
  `> **Meta description:** ...`.
- An **intro** with a hook that frames why the topic matters.
- **Body sections** with clear `##` / `###` headings and short, scannable paragraphs.
- A **conclusion** with a takeaway or call to action.
- A **## Sources** list at the end, linking every source you drew on.

Cite sources inline where you state a specific fact, stat, or quote. **Do not fabricate**
facts, statistics, quotes, or sources — if the research doesn't cover something, leave
it out or note the gap.

## 4. Save the draft

Save the post to `content/drafts/<topic-slug>.md`, relative to the current working
directory:

- **Slugify the topic** for the filename: lowercase it, replace spaces and punctuation
  with hyphens, and collapse repeated hyphens (e.g. "Remote Work Trends" →
  `remote-work-trends`).
- **Create the `content/drafts/` folder** if it doesn't already exist.
- **Don't silently overwrite.** If a draft with that name exists, ask whether to
  overwrite or save under a new name.

Confirm the exact saved file path.

## 5. Review

Delegate to the **review-agent** subagent to review the saved draft. Pass it the path
to the file you just saved. It will return an SEO / accuracy / quality report with an
overall **score out of 10** and a prioritized list of fixes.

## 6. Report and offer to revise

Show the user:

- The saved file path.
- The review-agent's **score** and its **top prioritized fixes**.

Then offer to apply the suggested fixes. If the user agrees, revise the draft, save it
back to the same path, and briefly summarize what changed.
