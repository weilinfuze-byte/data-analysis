# Content routing rules

> Read this file first before adding or modifying skill content to decide
> where it goes.

## Decision flow before adding anything

1. **Does the AI already know this?** — generic statistics, generic SQL
   syntax, standard frameworks → **don't add**
2. **Which layer?** — business understanding / data structure / analysis
   method? See directory definitions below
3. **Which surface?** — iOS / Web / Cross-platform? Put platform-specific
   docs in the right folder
4. **Any duplication in existing files?** — read the target file first,
   confirm no semantic overlap before writing
5. **Any bidirectional links?** — tables, events, metrics involved need
   two-way links maintained

## Confirmation rule for SQL collaboration

When writing SQL with the user, treat newly discovered company-specific data
knowledge as a candidate dictionary update, but **do not update the Skill
without user confirmation**.

Trigger this flow when a query introduces or corrects any of:

- `uicode` → page name
- `evt_id` → business meaning
- table name, table Chinese name, fields, partition fields, owner, permissions
- metric numerator / denominator / filter conditions
- reusable JOIN path or SQL template
- recurring pitfall

Workflow:

1. Keep working on the SQL.
2. Record candidate learnings in the response or todo notes.
3. Before editing Skill files, ask the user to confirm the exact wording.
4. After confirmation, update the proper file and sync installed Skill if needed.

Recommended prompt:

> 这次 SQL 里新增了 `{thing}`，我准备把它记录为 `{meaning}`，是否确认写入 Skill？

## Directory definitions

### `business/` — business understanding + institutional knowledge

**Put here**:
- Product definitions, user journeys, business models, feature definitions,
  user-segmentation logic
- **Institutional knowledge**: pricing strategy, package structure, LTV
  coefficients, baseline metric values, channel characteristics — context
  the AI can't know and isn't in the data either

**Don't put here**: table schemas, field names, SQL, filter conditions

**Split by surface / topic**: `platform-app.md`, `web.md`, `pricing.md`,
`{your-other-product-lines}.md`

**Timestamp rule**: business data that changes over time (prices,
coefficients, baselines) must be annotated with a timestamp:
```
<!-- as of 2026-03 -->
Weekly: first week $1.99, renewal $6.99/week
Week-to-month: first week $1.99, renewal $12.99/4 weeks
```

**Examples**:
- "Companion App includes Flashcard, EP, Voice Chat" ✓
- "Users segmented into Segment_A_Only / Segment_B_Only / Cross_User" ✓
- "Weekly-package LTV coefficient 29.358 (as of 2026-03)" ✓
- `WHERE LOWER(device.category) = 'desktop'` ✗ (that's the data layer)

### `tables/` — table structure

**Put here**: table names, field names, field types, JOIN relationships,
table-to-table comparisons, usage caveats, filter conditions

**Don't put here**: metric formulas, business explanations

**Split by table**: each table with detailed field definitions gets its own
file, and is indexed in `tables.md`

**Bidirectional link requirement**: at the bottom of each table file, list
the metrics that reference this table, linking back to `metrics.md`

### `events/` — event dictionary

**Put here**: event_name, meaning, event_params, use cases

**Don't put here**: full SQL, analysis methodology

**Split by surface**: `mobile.md`, `web.md`. Cross-platform events are
defined once and linked from the other side

**Bidirectional link requirement**: key events annotated with "used by
metric: xxx", linked to `metrics.md`

**Event tier rule**:

| Tier | Criteria | Treatment |
|------|----------|-----------|
| **Core** | Appears in core metrics (`metrics.md`), funnels, A/B test denominators | Must record, annotate linked metrics |
| **Secondary** | Used in specific analyses but not in daily metrics | Record on demand; add when first used |
| **Discovery** | Many, fast-changing, rarely used | Don't record; query the warehouse directly (`SELECT DISTINCT event_name WHERE event_name LIKE '%keyword%'`) |

**Before adding an event ask yourself**: which metric formula does this
event appear in? If you can't answer, it probably doesn't need recording.

### `metrics/` — metric definitions + standard SQL

**Put here**: metric name, aliases, formula, numerator, denominator,
sliceable dimensions, caveats, **the canonical SQL for this metric**

**Don't put here**: generic SQL patterns (variable declarations, CTE
structure, etc. — the AI already knows them)

**Split by topic**: `metrics/active.md`, `metrics/funnel.md`,
`metrics/monetization.md`, `metrics/retention.md`. `metrics.md` is the index.

**Bidirectional link requirement**: every metric annotated with the tables
it uses (link to `tables/`) and the events it uses (link to `events/`)

### `templates/` — locked SQL templates

**Put here**: alignment-sealed canonical SQL. Executed as-is, only the
marked parameters get substituted.

**Don't put here**:
- Methodology, analysis frameworks (generic — AI already knows; anything
  specific to your business goes in `business/` or `tables/`)
- Standard SQL for a metric (that goes in `metrics/`)
- Report templates (that's in the `analysis-report` skill)
- Freely modifiable SQL snippets (not "locked" — no need to preserve)

**Locking rule**: every template file starts with "⚠️ Locked template:
execute as-is, only modify marked parameters". The trigger scenario must
be registered in `SKILL.md`, otherwise the AI won't know to read it.

**Example current files**:
- `ab_test_sql.md` — A/B test framework (iOS + Web)

### `docs/` — usage documentation

**Put here**: this file (content-routing), FAQ, SQL style guide, internal table search, etc.

| File | Purpose |
|------|---------|
| [sql-style.md](sql-style.md) | SELECT 逗号前置、表别名 t1/t2、英文列名、LEFT JOIN |
| [internal-table-search.md](internal-table-search.md) | 内部表检索 SSO / 查字段流程 |

## Deprecated directories

| Directory | Reason |
|-----------|--------|
| ~~`golden-queries/`~~ | Metric SQL goes in `metrics/`; generic patterns aren't stored (AI knows them) |
| ~~`corrections/`~~ | Fix the error in the source data-dictionary file directly |
| ~~`pending_metrics.md`~~ | New metrics go into `metrics/` directly; no staging |

## Bidirectional linking convention

When adding or modifying metrics, tables, events, maintain two-way links:

```
metrics.md, one metric entry:
  Tables: [orders](tables/orders.md)
  Events: [Solve_Success](events/mobile.md#activity-events)

tables/orders.md, bottom section:
  ## Metrics referencing this table
  - [D0 subscription rate](../metrics.md#d0-subscription-rate)
  - [Paying users](../metrics.md#paying-users)

events/mobile.md, one event row:
  | Solve_Success | Solve success | → [Solve UV](../metrics.md#solve-uv) |
```

Not required to backfill all at once — just maintain whatever you touch.

## Context layers reference

> Inspired by OpenAI Harness Engineering — Data Agent's layers of context

| Layer | Meaning | Directory |
|-------|---------|-----------|
| 1. Table Usage | Schema, fields | `tables/` |
| 2. Human Annotations | Field meanings, caveats, usage patterns | Inline in `tables/*.md` |
| 3. Institutional Knowledge | Pricing, coefficients, baselines, business strategy | `business/` |
| 4. Locked SQL | Alignment-sealed queries | `templates/` |
| 5. Runtime Context | The current conversation | The conversation itself |

## Pre-add checklist

Before adding content, go through:

- [ ] This knowledge is NOT something the AI already knows (it's specific to your business)
- [ ] The target file has no semantically duplicate content
- [ ] Placed in the correct directory (per definitions above)
- [ ] Time-varying data has a timestamp
- [ ] Affected metric ↔ table ↔ event links updated
- [ ] Cross-surface content defined once, linked from the other side

## Periodic grooming

### Triggers

- Quarter-end / half-year-end
- Any single file > 300 lines
- Any single directory > 8 files
- After a `/close-project` sink, a directory visibly bloated
- Using a directory and noticing the index is inaccurate / content is stale

### Grooming checklist

**Is this directory still in use?**
- [ ] Is the index (`SKILL.md` / `tables.md` / `metrics.md`) still
      referencing it?
- [ ] Unreferenced directory → delete and record in "Deprecated directories"

**Has the staging area accumulated stale content?**
- [ ] `pending_*.md` / `tmp_*.md` — are any entries obsolete?
- [ ] High-value entries graduate to a proper file; delete the rest; if it
      could've been written directly into a proper file, don't use staging
      next time

**Is the index complete?**
- [ ] "Auto-read never" directories like `templates/` — does `SKILL.md`
      specify their trigger scenarios?
- [ ] New files have upward backlinks to the index?

**Is the index duplicating the detail files?**
- [ ] `tables.md` "other tables" section: a table with its own file
      shouldn't have its fields re-listed in the index
- [ ] A single-line entry in `tables.md` / `events.md` > 3 lines — split
      into its own file

**Are bidirectional links in sync?**
- [ ] Table's "Metrics referencing this table" — backfilled after adding a
      new metric?
- [ ] Event's "used by metric: xxx" — synced?

**Trash files**
- [ ] `.DS_Store` and similar — add to `.gitignore`
