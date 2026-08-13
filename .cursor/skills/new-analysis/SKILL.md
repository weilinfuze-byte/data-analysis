---
name: new-analysis
description: Create a new data analysis project. When a new analysis request comes in, creates a standardized project folder with a status record and working SQL files (exploration log plus named deliverables).
---

# New Analysis Project

## Usage

`/new-analysis [project-name]`

This is the starting point of the "request → analyze → report → sink" loop.
Skills live in this repo at `.cursor/skills/` (project skills). The
companion skills are:

- `/analysis-method` — how to analyze (methodology / attribution patterns)
- `/get-data` — how to pull data (SQL rules + data dictionary)
- `/create-hive-table` — Hive 结果表 / 中间表 DDL
- `/analysis-report` — how to write the deliverable
- `/close-project` — how to sink reusable knowledge back into the skills

---

## Steps

### 1. Confirm project info

Before scaffolding, confirm with the user (ask actively if anything is missing):

- Project name (used as folder name)
- Analysis goal / problem statement
- Requester (who asked for it)
- Initial hypothesis / direction

### 2. Create project structure

In the current working directory, create at least:

```
[project-name]/
├── status.md
└── workflow.sql
```

> Filenames can be Chinese if that matches the repo (e.g. `内容生态指标体系/`).

**`status.md` is required.** `workflow.sql` is the exploration log. Named
deliverable SQL files are expected as soon as a query is reusable — do **not**
force everything into a single `workflow.sql`.

Typical layout after the project is underway:

```
[project-name]/
├── status.md                          # 口径、进度、结论（必有）
├── workflow.sql                       # 探索 / 试错，append-only
├── {scene}_flow.sql                   # 中间表 ETL（可复用交付）
├── {scene}_enum.sql                   # 枚举探查
├── {metric}_ctr.sql / weekly_*.sql    # 指标 / 周报取数
└── rpt_{table}.md                     # 可选：表说明（给工厂/同事）
```

Rules:

| File | When |
|------|------|
| `status.md` | Always. Living narrative. |
| `workflow.sql` | First queries, one-off checks, failed attempts. Append, don't rewrite history. |
| Named `.sql` | As soon as the SQL is a deliverable: 中间表 ETL、验数、周报、枚举、物料 CTR. One concern per file. |
| Don't | Dump locked ETL into `workflow.sql`. Don't create scratch files with no name/purpose. |

If the first ask is already a named deliverable (e.g. 「建房源详情页中间表」),
create `status.md` **and** that named SQL immediately; `workflow.sql` can wait
until there is exploratory SQL.

### 3. status.md template

```markdown
# [Project Name]

## Project info
- **Date**: YYYY-MM-DD
- **Requester**:
- **Problem statement**:

## Metric definitions

| Metric | Definition | Numerator | Denominator |
|--------|-----------|-----------|-------------|
|        |           |           |             |

## Key tables
-

## Analysis framework

### Dimension 1:
### Dimension 2:
### Dimension 3:

## Progress

### Step 1:
- **Status**: not started
- **Data source**:
- **Result**:
- **Key findings**:

## Conclusions & next steps
-
```

### 4. workflow.sql template

```sql
-- ============================================================
-- Project: [Project Name]
-- Created: YYYY-MM-DD
-- Convention: append SQL in chronological order, top-to-bottom.
--             Never delete history — it's how the analysis reasoning stays
--             reviewable.
-- Named deliverables (ETL / weekly / enum) live in sibling .sql files.
-- ============================================================

-- ------------------------------------------------------------
-- Query 1: [purpose]
-- Time: YYYY-MM-DD HH:MM
-- Events referenced: [event_name → business meaning]
-- ------------------------------------------------------------

-- SQL here

-- Result:
-- | col1 | col2 | col3 |
-- |------|------|------|
-- |      |      |      |
-- Key finding:

-- ------------------------------------------------------------
-- Query 2: ...
```

### 5. After creation

Tell the user:
- Project structure is in place (`status.md` + first SQL)
- Next: confirm metric definitions and analysis framework, then write SQL
- Content ecology: if an intermediate table already exists, query that first
  (see `/get-data`)

---

## Why this pattern

- `status.md` is the living narrative: what we learned, what's open, what's next.
- `workflow.sql` is the append-only paper trail for exploration.
- Named `.sql` files are the deliverables that `/close-project` will consider
  promoting into `get-data` templates / tables.

When the project closes, `/close-project` reads `status.md` plus **all**
project SQL files to decide what to sink vs. what stays project-local.
