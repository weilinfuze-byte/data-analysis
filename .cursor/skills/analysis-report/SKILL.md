---
name: analysis-report
description: Writing norms for data analysis attribution reports. Use after analysis to produce the formal deliverable — ensures conclusion-first structure, clear filters, sourced data.
---

# Attribution Report — Writing Norms

## Relationship to other skills

- `/analysis-method`: *how* to analyze (methodology)
- `/analysis-report`: *how* to write (the deliverable)
- Recommended flow: analyze first → write report second

---

## Document tool integration

This skill is opinionated about producing a clean written deliverable but is
**format-agnostic**: the actual docs destination (Google Docs, Notion, Feishu,
internal CMS, etc.) is your choice.

The structural norms in this file apply regardless of destination. If your
team uses a CLI-based doc tool, drop tool-specific tips below.

### Optional: tool-specific tips

Below are hard-won tips from using a CLI-based doc tool. Copy the pattern for
your own tooling if useful.

#### Passing content into a CLI doc tool

| Method | Works? | Notes |
|--------|--------|-------|
| `--markdown "$(cat file.md)"` | **Yes** | Recommended, one-shot |
| `--markdown -` (stdin) | **Often No** | `-` may be parsed as literal markdown |
| `--markdown @file` | **Often No** | `@file` may be parsed as literal markdown |

#### Image upload

- `![](path)` may be recognized but *only* for HTTP URLs, not local paths
- For local images, use the tool's upload command separately
- Image upload commands are often append-only — can't target a position; plan
  your document so images always land at the end of their section

#### Create flow

**Text-only report**:

```bash
doc-tool create --title "Report" --markdown "$(cat report.md)"
```

**Mixed text + images**: because image upload is append-only, you must split
the markdown at each image position and alternate text-append + image-insert.
Local `![alt](path)` tags in markdown should be removed first (or the tool
will try to HTTP-fetch and warn).

---

## Workflow: draft locally, then publish

When the report has multiple charts, **draft locally first, then write to the
final doc**. Don't simultaneously think about structure and fight with the
doc tool's live UI.

Recommended flow:

1. **Draft the skeleton locally**
   - Write conclusions, section order, and the question each chart answers
   - Use markdown to reserve chart positions with explicit placeholders

2. **Generate the charts**
   - One question per chart — avoid cramming
   - Manually inspect each: title, legend, occlusion, annotations, colors, readability

3. **Publish the final**
   - Write section-by-section in reading order
   - If a section's prose is followed by a chart, insert the chart right there
     before continuing to the next section
   - Don't append everything and then go back to backfill images

### Why draft locally first

- The destination doc tool is for publishing, not for iterating structure
- Charts need manual verification — don't assume the first output is final
- Locally you can compare against the SQL and results files without context
  switching — reduces alignment mistakes

### One chart, one question

Charts serve conclusions, not decoration. A single chart should answer exactly
one question:

- KPI card: "did the top-level metric grow?"
- Grouped bar: "how did the mix change?"
- Stacked area: "who is contributing to revenue?"
- Waterfall: "what factors decomposed this outcome?"

If a chart needs a paragraph of explanation, it's carrying too many questions.

### Conclusions go *above* the chart (critical)

**Every chart or table must have its conclusion written above it, not below.**
Readers go top-to-bottom: they should hit the conclusion first, then the chart
to verify.

Correct order:
1. Conclusion / interpretation
2. Chart or table

Wrong order:
1. Chart or table
2. Conclusion

### Chart and table shouldn't duplicate information

If the chart already shows the data, the table shouldn't repeat it. They should
be complementary:

- **Chart**: trends, direct comparisons, visual patterns (e.g. retention bars)
- **Table**: data the chart doesn't show (numerator, denominator, additional
  metrics like conversion / cancel rates)

Concrete example: a retention bar chart already shows D1/D2/D3 for three arms;
the accompanying table should only add downstream conversion / cancel rate —
don't re-list retention numbers.

### Layered analysis needs a prose preamble

Layered analysis (Layer 1 → 2 → 3) must include a one-sentence preamble
explaining "why we're layering this way and in what order." Readers landing on
3.1 / 3.2 can't tell why.

Example:

```
All three arms show no overall difference because ~55% of users who denied
notifications diluted the signal. Therefore we layer:

All users → split by notification permission → within "allowed", split by paid status
```

### Chart hierarchy matches analysis hierarchy

If the analysis framework is Layer 1 → Layer 2 → Layer 3, charts must match
each layer:

- A Layer 2 chart can't show Layer 3 data
- Each layer's chart shows only that layer's splits

### Experiment reports must show all arms

In A/B reports, all arms must be shown — you can't pick two and hide the rest.
Even arms with small deltas must appear; let the reader judge.

### Significance-summary table doesn't own a top-level section

The significance summary is the closing of the results section; it belongs as
a sub-section (e.g. 3.4), not as its own top-level chapter. A standalone
chapter for it breaks reading flow and repeats content.

### Conclusions and recommendations must be separated

"Observations" and "recommendations" cannot mingle in the same list. Readers
need to distinguish "what the data says" from "what the analyst judges."
Recommended structure:

```
### Conclusions
1. Data fact A
2. Data fact B

### Recommendations
| Priority | Action | Expected impact |
```

### matplotlib Chinese fonts (macOS)

```python
plt.rcParams.update({'font.family': 'Heiti TC'})
```

`PingFang HK` doesn't always resolve in matplotlib; `Heiti TC` is more reliable.

### Short-term vs. long-term framing (critical)

Reports must distinguish:
- **Short-term structural metrics**: ARPPU, conversion rate, price-tier share
- **Long-term business outcomes**: LTV, retention, renewal, long-tail retention

**Never derive long-term strategy directly from a short-term ARPPU shift.**

Correct phrasing:
- OK: "Short-package mix is up, which mechanically compresses current-window ARPPU"
- Not OK: "Therefore long-term revenue will decline"
- Long-term claims require: "Needs confirmation via LTV / renewal / upgrade
  data before drawing a conclusion"

Examples:
- ✅ "Short-package mix is up → short-term ARPPU is lower; long-term impact
  needs LTV validation"
- ❌ "Short-package mix is up → ARPPU will keep falling"

### Recommended order for an exec-facing business report

1. Core conclusions
2. Analysis background
3. Strategy / business context
4. Overall landscape
5. Segment split
6. Core attribution decomposition
7. Summary and follow-ups

---

## Report structure template

### I. Core conclusions (must be first)

Conclusion-first. Reader should know the answer in 30 seconds. Include:

1. **Problem location**: one sentence stating the root cause
2. **Key data**: 2-3 key numbers in a table (with numerator + denominator)
3. **Confirmed issues**: each verified issue listed explicitly
4. **Ruled-out hypotheses**: each eliminated hypothesis listed (avoids
   re-investigation later)
5. **Recommendations**: actionable items

---

### II. Analysis background

Readers who weren't part of the analysis must understand context. **Must
include all of**:

1. **Business context**: why this analysis — experiment setup, business change
2. **Events / metrics**: key event names and their business meaning
3. **Data sources**: which tables
4. **Filters**: complete list of all filters applied — including but not
   limited to:
   - Date range (start_date ~ end_date)
   - Platform (iOS / Android / Web)
   - User segment (new / all / specific)
   - App version
   - Country / language
   - Exclusions (internal users, test data)
5. **Metric definitions**: precise numerator and denominator

**Example**:
```
Filters:
- Date range: 2026-01-19 ~ 2026-02-03
- Platform: iOS (ios_apple + ios_stripe)
- User segment: pure new (user_type = 'new_registered_user')
- App version: >= 4.9.7
- Language: en-us
- Device: mobile
- Excluded: internal users (matched by internal email domain)
```

---

### III. Funnel / path analysis

Locate the problem from macro to micro:

1. **Baseline funnel**: end-to-end conversion (impression → click → submit → success)
2. **Path decomposition**: split by key dimension (entry, payment method, etc.)
3. **Problem location**: which step, which branch

**Format**:
- Every funnel step must show numerator, denominator, conversion rate
- Use a table; support treatment/control side-by-side
- Mark significant deltas (bold or color)

---

### IV. Root-cause analysis

For the located problem step, investigate from multiple angles:

- Each angle is its own sub-section
- Each sub-section: purpose → data (table) → finding / conclusion
- Common angles: controlled comparison, user destination, time distribution,
  device dimension, retry behavior
- Key findings highlighted

---

### Appendix A: Analysis SQL

All SQL used, annotated by purpose, matching the body. Fully executable
(including variable declarations and filters), in body order.

---

## Writing norms

### Principles

1. **Conclusion first**: put core conclusions in chapter 1
2. **Data-backed**: every conclusion cites data
3. **Numerator + denominator**: every percent comes with both
4. **Side-by-side comparison**: treatment and control in the same table
5. **Mark the deltas**: bold significant differences for fast scanning
6. **Filter transparency**: list every filter in the background section — no omissions

### Format

- Tables for data comparison (not free-text lists of numbers)
- Key findings highlighted with callouts
- Clear numbering (1, 2, 3 → 1.1, 1.2)
- SQL in code blocks in the appendix

### Avoid

- Stream-of-consciousness ("first I looked at A, then I looked at B")
- Data without conclusions
- Vague language ("seems", "possibly") — make a judgment
- Leaving out ruled-out hypotheses (as important as the confirmed ones)
- Missing filters (reader can't verify definitions match)

### Self-audit checklist (run this before delivery)

After the draft is done, run a quality self-audit (you can delegate this to an
agent):

| Check | Meaning |
|-------|---------|
| **Group sums = total** | Rows in every grouped table sum to the stated total. Mismatch = double-counting or missing segments |
| **Same metric across tables agrees** | The same number across different sections must match. Mismatch = definition confusion |
| **Unified dedup key** | Every count uses the same dedup key (e.g. user_id vs. user_pseudo_id). Must be consistent *and* stated |
| **Definition labels complete** | Every percent has numerator + denominator; merged definitions (e.g. "never-paid + trial-only") explain why they're merged |
| **Trap check** | Any circular reasoning, Simpson's paradox, or mean-trap? Re-read the project-level CLAUDE.md defense rules |

> Real case: an agent self-audit caught user_id (12,109) vs. pseudo_id (13,687)
> mixing — a 13% definition split that invalidated all downstream percentages.
> After fixing, the audit passed.
