---
name: close-project
description: Close out a project or summarize session context. Sinks reusable knowledge into skills at the end of a project, or summarizes in-flight context mid-conversation.
---

# Close Project / Context Summary

Usage:
- `/close-project [project-name]` — formal project closeout, sinks knowledge into skills
- `/close-project` — summarize current context (what's done, what's pending, what we tripped on); no formal project required

---

## Mode

| Condition | Mode | What to run |
|-----------|------|-------------|
| Project name given + analysis folder exists in this repo | **Project closeout** | Full steps 1–8 |
| No project name / no project folder | **Context summary** | Step 2 (identify sinkables) + emit context summary |

**Sink location (hard rule in this repo):** write reusable knowledge into **this repository's** `.cursor/skills/` (usually `.cursor/skills/get-data/` and `.cursor/skills/analysis-method/`). Do **not** write to `~/.cursor/skills/` here — that copy is personal and will not reach colleagues. After the user confirms a sink, remind them to commit and push.

### Context-summary output format

```markdown
## Completed this session
- [what got done, key conclusions]

## Sunk to skills
- [which files were written]

## Still open
- [unfinished items]

## Gotchas
- [corrections, rule changes discovered]
```

---

## Project closeout — steps

### 1. Read the project files

Read the project's `status.md`, `workflow.sql` if present, and **all other
project `.sql` files** (ETL, weekly, enum, validation, CTR). Extract:

- Key findings and conclusions
- Tables / fields / JOIN paths used
- New metric definitions discovered
- Gotchas / corrections

### 2. Classify sinkables

Walk the checklist and confirm each item with the user before writing:

| Type | Test | Target |
|------|------|--------|
| **New table / field / join path** | Used in project but not in `tables/*.md` | `tables/*.md` (follow content-routing) |
| **New metric definition** | Project defined a reusable formula | Directly into `metrics/*.md` (no staging files) |
| **Metric SQL fill-in** | Metric exists in `metrics/*.md` but is missing a full SQL template | Append SQL to the metric's definition |
| **New event** | Used but not in `events/*.md` | `events/mobile.md` or `events/web.md` |
| **Business knowledge** | Prices, coefficients, baselines AI can't know | `business/*.md` |
| **Cross-project insight / strategy** | Analysis conclusion reusable across projects | Your team's knowledge base (wiki / Notion / Obsidian) |
| **Behavior rule** | Rule that changes *how* the AI works (e.g. "don't default to full history") | the relevant skill under `.cursor/skills/` |
| **Analysis trap / anti-pattern** | Logical error made during analysis (circular reasoning, Simpson's Paradox, etc.) | `.cursor/skills/analysis-method/` |
| **Locked SQL template** | Alignment-sealed SQL; use as-is, never modified | `templates/` + register trigger-scenario in the skill's SKILL.md |

### 3. Confirm and write

For each sinkable:
- Show a summary + the target file
- Wait for user confirmation
- **Read the target file first** to check for semantic duplicates before writing

**Uncertain items**: mark them as "待沉淀" in the project's status.md and move on. Don't force a classification.

### 4. Update project status

Append a closure record to `status.md`:

```markdown
## Closure log (YYYY-MM-DD)

### Sunk
- [content] → [target file]

### Deferred
- [content] (reason: to-confirm / to-discuss)
```

### 5. Update the task tracker

Mark the corresponding task in your task tracker (e.g. `your-task-tracker/`) as
complete with the date.

### 6. Update the "active projects" board

If you maintain a running list of in-flight projects (recommended), move this
project from "active" to "done" and add:

- Core tables, key concepts/fields, SQL location (for future fast re-entry)
- Important patterns or easy-to-trip-on findings from the project
- Completion date

### 7. Permission / settings audit

Look back through this session for Bash commands or tool calls the user had to
approve manually. Decide which (if any) should be auto-authorized going forward:

**Auto-add candidates**:
- Local, reversible, no-side-effect operations (`ls`, `cp`, `mkdir`, most `git` subcommands)
- High-frequency MCP tools (warehouse CLI, docs-tool read, etc.)

**Don't auto-add**:
- Operations with external side effects (`git push`, send-message, file deletion)
- One-off commands tied to a specific path (keeps settings file clean)

**Execution**:
- Show the user the proposed additions with reasoning
- After confirmation, write to `.claude/settings.local.json`
- Prune any now-obsolete one-off entries

### 8. Trigger periodic grooming?

If any of these got hit during the sink:

- Some file grew past 300 lines
- Some directory grew past 8 files
- The index you used to find something was wrong / stale
- A deprecated directory still exists

Then suggest the user run the grooming checklist in
`get-data/docs/content-routing.md` ("Periodic grooming"). Don't force it mid-closure
— put it on the task list for a dedicated grooming session.

---

## Rules

- **All steps run, none skipped**. Step 7 (permission audit) is the one most
  easily forgotten — run it *before* the final summary.
- **Show before write**. Never auto-write a sinkable; show the proposed content
  and target, then wait.
- **Follow content-routing**. Use `get-data/docs/content-routing.md` to pick
  where things go.
- **No duplicates**. Always read the target file first to check for semantic
  overlap.
- **Maintain backlinks**. Respect the bidirectional linking convention in
  content-routing (metric ↔ table ↔ event).
