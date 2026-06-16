---
name: client-brief-generator
description: Generate a comprehensive client brief for a freelance project. Use this whenever the user is onboarding a new client, kicking off or scoping a freelance gig, or asks for a client brief, project brief, creative brief, or onboarding document — even if they don't use the word "brief" explicitly. Gathers client name, industry, services needed, target audience, brand voice, platforms, budget range, timeline, competitors, and success metrics, then produces a clean markdown table and saves it under client-briefs/.
---

# Client Brief Generator

Generate a structured, comprehensive client brief for a freelance project. The brief is the single source of truth for an engagement — what the client needs, who they're targeting, how they want to sound, where the work lives, and how success will be judged. Capturing all of this up front is what prevents scope creep, mismatched expectations, and rework later, so it's worth collecting every field before any project work begins.

## Workflow

### 1. Gather the inputs

Collect these ten fields. If the user already provided some of them in their request, extract those and **only ask for what's still missing** — don't make them repeat themselves. Ask for everything that remains in a **single batched, numbered message** so they can answer in one pass instead of being drip-fed one question at a time.

1. **Client name** — the business or person you're working for.
2. **Industry** — their sector or niche.
3. **Services needed** — what they're hiring you to do.
4. **Target audience** — who they're trying to reach.
5. **Brand voice** — tone and personality (e.g., professional, playful, bold, minimal).
6. **Platforms** — where the work will live (Instagram, LinkedIn, website, email, etc.).
7. **Budget range** — the project or retainer budget.
8. **Timeline** — start date, key milestones, and final deadline.
9. **Competitors** — who they compete with or admire.
10. **Success metrics** — how they'll measure whether the project worked (followers, leads, conversions, etc.).

If a field genuinely doesn't apply or the client doesn't know yet, record it as **"TBD"** rather than leaving it blank or guessing. A brief that quietly invents a budget or audience is worse than one that honestly flags the gap, because someone will later treat the fabricated value as fact.

### 2. Produce the brief

Format the brief as a clean two-column markdown table (Field / Details), using this exact structure:

```markdown
# Client Brief: <Client Name>

| Field | Details |
|-------|---------|
| Client Name | ... |
| Industry | ... |
| Services Needed | ... |
| Target Audience | ... |
| Brand Voice | ... |
| Platforms | ... |
| Budget Range | ... |
| Timeline | ... |
| Competitors | ... |
| Success Metrics | ... |

*Generated on <date>*
```

Keep each cell concise but complete. When a field holds multiple items (several platforms, a list of competitors), separate them with commas so the row stays readable in a single table cell.

### 3. Save it

Save the brief to `client-briefs/<client-name>-brief.md`, relative to the current working directory.

- **Slugify the client name** for the filename: lowercase it, replace spaces and punctuation with hyphens, and collapse any repeated hyphens. Example: `"Acme Co."` becomes `acme-co`, giving `client-briefs/acme-co-brief.md`.
- **Create the `client-briefs/` directory** if it doesn't already exist.
- **Don't silently overwrite.** If a brief for that client already exists, tell the user and ask whether to overwrite it or save under a new name — prior briefs may contain edits worth keeping.

After saving, confirm the exact file path and show the user the rendered table so they can review it at a glance.
