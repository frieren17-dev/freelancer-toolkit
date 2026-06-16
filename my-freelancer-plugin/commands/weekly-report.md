---
description: Generate a professional weekly freelance status report — work completed, content created, estimated hours, blockers, and next week's plan — and save it to reports/.
argument-hint: [optional: week-ending date or quick notes]
---

# Weekly Report

Generate a polished, professional weekly status report for this week's freelance work.

## 1. Gather the inputs

Collect the following. If the user passed notes as arguments (**$ARGUMENTS**), or there's relevant context in the conversation or in the project's `content/` and `reports/` folders, use it to pre-fill what you can — then ask the user to confirm and fill any gaps rather than inventing details:

- **Work completed** — tasks and deliverables finished this week.
- **Content created** — pieces produced, with platform/format (e.g. "3 LinkedIn posts, 1 blog draft").
- **Estimated hours** — rough hours worked this week.
- **Blockers** — anything that slowed progress or needs the client's input.
- **Next week's plan** — what's planned for the coming week.

## 2. Format the report

Produce a clean, client-ready markdown report using this structure:

```markdown
# Weekly Report — <date>

## Work Completed
- ...

## Content Created
- ...

## Estimated Hours
...

## Blockers
- ...  (write "None" if there were no blockers)

## Next Week's Plan
- ...
```

Keep the tone professional and concise — this is something the client reads.

## 3. Save the report

Save the report to `reports/weekly-report-<date>.md`, where `<date>` is today's date in `YYYY-MM-DD` format. Create the `reports/` folder if it doesn't exist. If a report already exists for today's date, ask before overwriting. Confirm the exact saved file path when you're done.
