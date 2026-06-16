---
description: Onboard a new freelance client end-to-end — collect their details, generate a client brief, scaffold the project folders, save the brief, and lay out next steps.
argument-hint: [client name]
---

# Onboard New Client

Run a complete onboarding flow for a new freelance client. Work through these steps in order, keeping the user informed as you go.

## 1. Identify the client

If a client name was passed as an argument, use it: **$ARGUMENTS**. Otherwise, ask for the client's name and the services they need before continuing.

## 2. Generate the client brief

Use the **client-brief-generator** skill to gather the full set of brief fields (client name, industry, services needed, target audience, brand voice, platforms, budget range, timeline, competitors, success metrics) and produce the markdown table. Only ask for fields that haven't already been provided, and batch the remaining questions into a single message so the user can answer in one pass.

## 3. Scaffold the project workspace

Create the standard freelance project folder structure in the current working directory. Create each folder only if it doesn't already exist (don't wipe anything that's there):

- `client-briefs/`
- `content/drafts/`
- `content/published/`
- `reports/`

## 4. Save the brief

Save the generated brief to `client-briefs/<client-name>-brief.md`, slugifying the client name (lowercase, spaces and punctuation replaced with hyphens — e.g. "Acme Co." becomes `acme-co`). If a brief for that client already exists, ask before overwriting rather than clobbering prior work.

## 5. Summarize next steps

Finish with a short, friendly summary that includes:

- Confirmation that the brief was saved, with its file path.
- The folders that were created (or that already existed).
- 3–5 concrete next steps to kick off the engagement — tailored to the services the client asked for (e.g. draft a content calendar, schedule a kickoff call, set up the first deliverable).
