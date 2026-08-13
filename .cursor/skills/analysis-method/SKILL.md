---
name: analysis-method
description: Data analysis methodology. Covers attribution analysis, dimensional decomposition, funnel breakdown, controlled comparison, and known traps (circular reasoning, Simpson's paradox, ITT). Triggered when analyzing conversion-rate drops, A/B test results, retention differences, paid-rate problems, or any "why did this metric move" question.
---

# Attribution Analysis Methodology

## Core framework

```
Define problem → Decompose path → Generate hypotheses → Slice by dimension → Verify/eliminate → Locate root cause
```

---

## Six approaches

### 1. Funnel decomposition

**Question**: which step is broken?

**How**:
1. Draw the full path (impression → click → submit → success)
2. Compute conversion at every step (numerator / denominator)
3. Find the cliff

**SQL pattern**:
```sql
SELECT
  group_dim,
  COUNT(DISTINCT CASE WHEN event_a THEN user_id END) AS step1,
  COUNT(DISTINCT CASE WHEN event_b THEN user_id END) AS step2,
  ROUND(step2 * 100.0 / NULLIF(step1, 0), 2) AS cvr
FROM events GROUP BY group_dim
```

**Tips**:
- Every step needs an explicit numerator and denominator
- Locate the step first, then dive into root cause

---

### 2. Dimensional decomposition

**Question**: is everyone affected, or just one segment?

**Common dimensions**:
- User attributes: new/returning, paid/free, country
- Device attributes: iOS/Android, model, app version
- Behavior attributes: high/low activity, depth-of-use
- Time attributes: weekday/weekend, hour-of-day

**SQL pattern**:
```sql
SELECT dim, COUNT(*) AS denom, SUM(converted) AS numer,
  ROUND(SUM(converted) * 100.0 / COUNT(*), 2) AS cvr
FROM events GROUP BY dim ORDER BY cvr
```

**Read it**:
- All dimensions affected → systemic issue
- Only some dimensions → segment-specific

**Tips**:
- Big dimensions first, then drill down
- Watch sample size — small-segment swings are noise

---

### 3. Time distribution

**Question**: when does it happen / how long does the user wait before failing?

**Three angles**:
- Inter-event interval: how long does A → B take? (process complexity)
- Time bucketing: which time bucket loses the most users? (failure point)
- Trend: sudden vs. gradual

**SQL pattern**:
```sql
SELECT group_dim,
  AVG(interval_seconds) AS mean,
  APPROX_QUANTILES(interval_seconds, 100)[OFFSET(50)] AS median,
  COUNTIF(interval_seconds < 5) * 100.0 / COUNT(*) AS pct_under_5s
FROM event_pairs GROUP BY group_dim
```

**Time bucketing**:
```sql
SELECT group_dim,
  CASE
    WHEN interval < 5 THEN '1.<5s'
    WHEN interval < 10 THEN '2.5-10s'
    WHEN interval < 30 THEN '3.10-30s'
    ELSE '4.>30s'
  END AS bucket,
  COUNT(*) AS n
FROM pairs GROUP BY 1, 2
```

**Tips**:
- Compare two cohorts' distributions; the bucket with the largest delta is the issue
- Median is more robust than mean against outliers

---

### 4. Controlled comparison

**Question**: compare against what? What's the delta?

**Comparison types**:
- A/B experiment arms: random assignment, controlled variable
- Time-over-time: YoY / WoW
- User-segment: high-converters vs. low-converters
- Industry benchmarks

**Principle**: hold everything constant except the one factor under test.

**Tips**:
- A/B comparisons require random assignment
- YoY comparisons must account for holidays, seasonality

---

### 5. Behavior sequencing

**Question**: what did the user do *next*?

**What to look at**:
- Next event after the drop-off: did they leave or retry?
- Full path: are there abnormal patterns?
- Final destination: did they ever convert eventually?

**SQL pattern**:
```sql
SELECT group_dim, next_event, COUNT(*) AS n
FROM (
  SELECT *,
    LEAD(event_name) OVER (PARTITION BY user_id ORDER BY ts) AS next_event
  FROM events
)
WHERE event_name = 'drop_off_event'
GROUP BY 1, 2 ORDER BY n DESC
```

**Read it**:
- Retry → there's intent, but they hit a wall
- Error event → technical issue
- Exit → genuine give-up

**Tips**:
- Constrain the time window (e.g. within 5 minutes)
- Exclude system-triggered events

---

### 6. Process of elimination

**Question**: which hypotheses can we rule out?

**How**:
1. List all hypotheses exhaustively
2. Design a verification check for each
3. Test each with data
4. Eliminate the failures; what's left is the root cause

**Decision criterion**:
```
If hypothesis A is true → we should observe phenomenon X
Phenomenon X is absent → A is false → eliminate
```

**Tips**:
- Hypotheses should be MECE (mutually exclusive, collectively exhaustive)
- Test the most likely first
- Every conclusion must have data backing it

---

## Special techniques

### Tip 1: discover relevant events via user-sequence exploration

**When**: you know roughly which step has the problem, but you don't know which
events are emitted there.

**How**:
1. Pick a few exemplar users
2. Pull every event for those users in the relevant time window
3. Read the sequence; spot useful events you didn't know existed

**SQL**:
```sql
-- Step 1: find exemplar users
WITH target_users AS (
  SELECT user_id FROM events
  WHERE event_name = 'target_event' LIMIT 10
)
-- Step 2: pull full event stream
SELECT user_id, event_name, event_time, event_params
FROM events e
JOIN target_users t USING(user_id)
ORDER BY user_id, event_time
```

**Verify candidate events**:
```sql
SELECT group_dim, event_name, COUNT(*) AS n
FROM events
WHERE event_name IN ('candidate_event_1', 'candidate_event_2')
GROUP BY 1, 2
```

**Tips**:
- Look at multiple users to find patterns
- Pay attention to fields inside `event_params` (failure reasons, etc.)
- After identifying useful events, do the proper aggregation

---

### Tip 2: mining `event_params`

**SQL (BigQuery)**:
```sql
-- Discover keys
SELECT ep.key, COUNT(*),
  ARRAY_AGG(DISTINCT ep.value.string_value LIMIT 5) AS samples
FROM events e
CROSS JOIN UNNEST(e.event_params) AS ep
WHERE event_name = 'target_event'
GROUP BY 1 ORDER BY 2 DESC

-- Extract a specific param
SELECT group_dim,
  (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'reason') AS reason,
  COUNT(*)
FROM events WHERE event_name = 'target_event'
GROUP BY 1, 2
```

---

### Tip 3: cohort comparison (converted vs. churned)

**SQL**:
```sql
SELECT outcome,
  AVG(session_duration) AS avg_duration,
  AVG(feature_uses) AS avg_uses
FROM (
  SELECT user_id,
    CASE WHEN converted THEN 'converted' ELSE 'churned' END AS outcome
  FROM users
) JOIN features USING(user_id)
GROUP BY 1
```

---

## Working rules

### Stop and discuss after each step

After completing each dimensional cut or finding a key signal, **stop and
discuss next direction with the user**. Don't blast through every dimension in
one run.

The cadence should be:
1. Run one dimension → show result → discuss finding
2. User confirms direction → run next dimension
3. Notice something anomalous → stop immediately, discuss whether to adjust the framework

### Track ruled-out hypotheses

Maintain a running list during the analysis to avoid re-investigating dead ends:

```
## Ruled-out hypotheses
| Hypothesis | Verification | Result | Reason eliminated |
|------------|--------------|--------|-------------------|
| e.g. device-driven | grouped by device model | no significant delta | eliminated |
```

---

## Checklist

| Check | Question |
|-------|----------|
| ☐ Quantified problem | How big is the delta? Is it significant? |
| ☐ Located the step | Which funnel step is broken? |
| ☐ Sliced by dimension | Everyone or specific segments? |
| ☐ Time analysis | When does it happen / how long is the wait? |
| ☐ Controlled comparison | Compared against what? Variables held? |
| ☐ Behavior sequence | What happens next? |
| ☐ Hypotheses exhausted | Listed every possibility? |
| ☐ Data-backed | Every conclusion has evidence? |
| ☐ **Product mechanism** | Does the candidate behavior require payment to perform? Risk of circular reasoning? |
| ☐ **Simpson's paradox** | Does the mixed-cohort result reverse when you split by sub-segments? |
| ☐ **Stopped to discuss** | Confirmed each key finding with the user? |
| ☐ **Tracked rule-outs** | Recorded eliminated hypotheses? |

---

## Common traps

### ARPPU / mean-of-ratios attribution

**Problem**: when ARPPU or any mean-of-ratios moves, the gut reaction is "the
price changed", but the real cause is often a **definition mismatch**, **mix
shift**, or **observation-window difference**.

**Four-step diagnosis**:
1. **Check the definition first**: what's the dashboard's numerator/denominator? Is there a date filter? Is it cumulative? (Real case: a dashboard with no date filter accumulated $10K of extra renewal revenue in W1 vs. W2 — that single discrepancy explained 54% of the gap.)
2. **Decompose numerator and denominator**: how much did revenue drop? How much did paying-user count drop? Which moved more, and is that what's driving ARPPU?
3. **Rule out structural bias**: does the same metric on the warehouse-wide query move the same way? If only the dashboard moves, it's a definition issue. If both move, it's real.
4. **Drill into dimensions**: by package / price / country / user-type, find the sub-segment with the biggest move.

**Key checks**:
- WoW / MoM definitions must use *aligned windows* (you can't have one side include renewals and the other side not)
- Small sub-segments produce wild ARPPU swings (e.g. 82 → 67 paying users)
- "Wide stable + narrow volatile" → suspect definition first, business second

### Circular reasoning (Aha-Moment analysis)

**Problem**: the "behavioral signal" you found is actually the same thing as
the outcome variable.

**Classic case**: free quota is 2 problems. You discover "users who solve ≥3
problems on D0 retain better." But solving ≥3 problems requires having paid
already → you've just found "paying users retain better," not an Aha Moment.

**Defense**:
1. When listing candidate behaviors, first verify each one is **achievable
   without payment / under no gating**
2. If a behavior requires payment to trigger, it's not an independent signal —
   it's a proxy for paid status
3. Look for signals **inside** the free quota (e.g. solve-and-followup,
   solve-and-give-positive-feedback)

### Simpson's paradox (mixed cohort)

**Problem**: a conclusion drawn over a mixed cohort reverses when you split by
sub-segment.

**Classic case**: overall, "users who saw the paywall churn more." Splitting by
user_type: net-new users almost all see the paywall (it's part of onboarding),
while reinstall-keep users who saw the paywall actually retain *better*. The
mixed statistic was an artifact.

**Defense**:
1. Whenever you compare user behaviors, ask: "is the cohort composition uniform?"
2. Slice by the key dimension (new/old, paid/free, channel) and re-verify the conclusion
3. Special attention to user_type mixing (net-new vs. reinstall behave very differently)

---

## 7. Abuse / abnormal-behavior quantification

**Question**: are users abusing the product mechanic (free-tier farming, bot
traffic, trial abuse)? How big is it?

**When to use**: free-tier abuse detection, bot identification, trial / quota
exploitation, abnormal high-frequency operations

**Framework (10 steps)**:

| Step | Goal | Output |
|------|------|--------|
| 1. Define & identify | What counts as "abnormal"? | e.g. "≥3 installs + zero pay + 1-2 problems each install" |
| 2. Magnitude | Total + frequency distribution | Abnormal-user count, frequency tiers (3-5 / 6-10 / 10+) |
| 3. Behavior × payment × frequency cross-tab | Differentiate sub-segments | 3D crosstab; identify "high-risk" vs. "normal returning" |
| 4. Pattern consistency | Verify each instance follows the same pattern | e.g. solve-count distribution per install — do they "use up free quota then leave"? |
| 5. Cumulative impact | Lifetime impact | Total free-tier consumed, per-user average |
| 6. Baseline comparison | Confirm "abnormal" vs. "normal" delta | Normal vs. abnormal user comparison table |
| 7. Resource share | % of total resources | e.g. % of total API calls |
| 8. Trend | Is it growing? | Daily / weekly trend; sets priority |
| 9. Extreme-case profiling | Top-N user behaviors | Determine if scripted/automated |
| 10. Risk tier + recommendations | P0–P3 + suggested actions | Severity tier mapped to intervention strategy |

**Key principles**:
- **Don't sledgehammer**: even an "abnormal" cohort contains normal users (e.g. 19.6% of "reinstall users" actually pay), so always cross-analyze before acting
- **Magnitude first, strategy second**: confirm the absolute size and resource share before deciding it's worth fixing
- **Pattern verification before aggregation**: don't just look at the totals — verify pattern consistency per instance (e.g. solve-count per install)

---

## Scenario quick-lookup

| Scenario | Approach to try first |
|----------|----------------------|
| Conversion-rate drop | Funnel decomposition → time-over-time |
| A/B attribution | Controlled comparison → funnel → time distribution |
| Retention drop | Dimensional decomposition → behavior sequencing |
| Paid-rate gap | Funnel decomposition → time distribution |
| **ARPPU / mean-of-ratios shift** | **Definition check → decompose num/denom → rule out structural bias → drill** |
| Aha-Moment search | Cohort comparison → **rule out circular reasoning** → **split by sub-segment** |
| Abuse / free-tier farming | **Abnormal-behavior quantification** (define + crosstab + pattern + impact) |
| "Don't know which events to look at" | User-sequence exploration |

---

## Experiment-analysis defenses

> The following rules came out of real experiment-analysis errors. Run through
> them before every A/B analysis.

### 1. Identify the confounder: who actually got the treatment?

Experiment effects can be diluted by users who never received the treatment.
Before analyzing, ask: **how many users in the denominator could actually
receive the treatment?**

If there's a sub-segment that *cannot* be affected (e.g. users with notifications
disabled in a push experiment), you must split by that variable — otherwise the
real effect is washed out.

How to do it:
1. Find the variable that determines "actually treated"
2. Split, then look at treatment vs. control within each side
3. The "couldn't be affected" sub-segment doubles as an AA validation — if it
   shows a delta there, your randomization is broken

> Real case: a push experiment showed <0.6pp delta across all three arms. After
> splitting by notification permission, the "allowed-notifications" segment
> showed +2pp and significant; the "denied" segment showed no delta (passes AA).

### 2. Validate proxy variables

When you use one event/field as a proxy for a state (e.g. using
`PushShown_Success` as a proxy for "has notification permission"), **always
cross-validate** coverage and accuracy with a known ground-truth signal.
Skipping this step bakes in segmentation errors.

How to do it:
1. Find a ground-truth signal (or the closest available)
2. Build a crosstab: proxy=1 ∧ truth=1 / proxy=1 ∧ truth=0 / etc.
3. Confirm both coverage (recall) and accuracy (precision) are high enough

> Real case: in a push experiment, `Notification_Click_Allow` covered 86.8% of
> registered users (usable as proxy); `Popup_EnableNotification_Click` only
> overlapped 13% (not usable). Also, `Notification_SystemAlert_Allow_Clicked`
> (40 UV) and `Noti_SystemAlert_Allow_Clicked` (48K UV) differ by one prefix —
> almost picked the wrong one.

### 3. Decide the analysis framework before running queries

Define the layered framework first (e.g. Layer 1 overall → Layer 2 confounder
→ Layer 3 business dimensions), confirm what each layer measures, *then* write
SQL. If you slice on the fly, you'll thrash and re-do work.

> Real case: a push experiment was first sliced by solve-count tiers (too
> granular, no signal). Restructured around notification-permission × paid-status
> in 3 layers — ran cleanly the first time.

### 4. Use ITT, not post-hoc filtering (avoid self-selection bias)

A/B effect judgments must use **treatment vs. control overall** (Intent-to-Treat,
ITT). You **cannot** post-hoc compare "users who did X vs. users who didn't do X."

**Why**:
- "Did X" is not a randomly assigned variable — users self-selected
- People who actively try a new feature are inherently more engaged, more
  curious, more likely to retain anyway
- The "lift" you compute from post-hoc segmentation is almost entirely the
  pre-existing difference between those two crowds — not the causal effect of
  the treatment

**The correct approach**:
1. Compare the **overall** metrics for treatment vs. control (regardless of
   whether each user actually touched / used the feature)
2. That delta is the true causal effect of the treatment
3. Even if uptake is low, this is the true at-scale impact the treatment delivers

**When you *can* use "exposed vs. unexposed" comparisons**:
- Descriptive analysis ("what does the exposed user look like?") — but the
  conclusion can only be "correlation," not "causal"
- **Never** to argue that the treatment worked

**Real case (Mini-Feature Experiment X)**:
- Post-hoc: "users who played Mini-Feature retained 38.6% D1 vs. 12.6% non-players (+26pp)" — looks huge
- ITT: experiment arm D1 12.97% vs. control D1 12.88% = **+0.09pp** (basically nothing)
- **The truth**: those 100 users who played were already-high-retention users — no causal link to the feature

> Before every A/B analysis, ask yourself: "are my two compared groups
> **randomly assigned**?" If not, the conclusion can only be correlational.

### 5. Feature funnels can only be sliced *within* the treatment arm

A new feature (and its instrumentation) **only fires in the treatment arm** —
the control arm doesn't have the feature, so the events don't emit. Therefore
funnels like `FeatureAppear → Impression → Toggle` are **inherently
treatment-arm internal** (slice by sub-dimension), not treatment-vs-control.

When analyzing, distinguish two lenses:
- **Treatment vs. control**: measures the **causal impact** of the feature on
  **core metrics** (retention, paid, follow-up, etc.)
- **Within-treatment funnel**: describes **feature-usage depth itself** (UV
  penetration, PV conversion, per-user frequency); can be sliced by grade /
  channel / subject to see who likes it

If you want to further split "users vs. non-users," remember: **this is not
causal** (users self-selected). It's descriptive (see rule 4).

### 6. Entry-point analysis: high exposure ≠ high conversion

When evaluating new feature entry points (icons, banners, cards, popups, etc.),
**looking only at click UV is severely misleading**. You must look at the
**click → core-action conversion rate** for each entry, not just the click
volume.

**Core principle**:
- High-exposure entries (homepage icon, banner): attract many "casual tap"
  low-intent users — clicking ≠ wanting
- Active entries (menu cards, search, sub-pages): less reach but the user came
  with explicit intent — clicking basically equals using
- **Same feature, different entries: click-to-core-action conversion can differ
  by 8x**

**The correct approach**:
1. Compute "click → core-action UV" conversion separately for each entry
2. Compare which entry has the highest **quality** (not which has the most clicks)
3. For "high-exposure low-conversion" entries, distinguish UX issue (fixable
   helps) from intent issue (users didn't want it; fix won't help)

**Telling intent vs. UX apart**:
- Same downstream funnel conversion (e.g. Play_Start → Play_End) → UX issue
- Entry-level conversion radically different → intent issue (different entries
  attract different crowds)

**Real case (Mini-Feature experiment, T3 arm)**:
- Icon entry (homepage): 117 UV clicks → 12 UV started = **11% conversion**
- Card entry (Study tab): 17 UV clicks → 15 UV started = **88% conversion**
- 8x gap + identical downstream funnel → not UX, it's intent: icon attracts
  "casual tap"; card catches "actively looking"
- Wrong conclusion: "icon entry works well" (UV-only view) → push more icon placement
- Right conclusion: "icon is for awareness only; conversion needs intent-built entries"

> When evaluating an entry, ask first: "what fraction of the people who clicked
> actually completed the core action?"

---

## Quality / negative-feedback attribution methodology (17 rules)

> Useful for "why did the user give negative feedback", "why did the model
> answer wrong", "product-quality issue attribution" — root-causing user
> complaints from a model-scored output stream.

### A. Data layer (skip this and the rest is hallucination)

1. **Multi-image captures: always look at all of them.** When `multi_picture_key_array` is non-empty, the primary image is often only part of the question. Charts, equations, sub-questions hide in the additional images. Looking only at the primary → wrong attribution → falsely conclude "user didn't capture it."
2. **Look at the answer JSON's component type.** Top-level keys may be `final_answer` / `chart_steps_single` / `question_multiple` / `question_single`. Different components have different semantics — extract via regex `^\{\s*"([a-zA-Z_]+)"`.
3. **Look at the full steps, not just final_answer.** `questions_step_style.data.questions[*].steps[*]` has the model's reasoning. The final answer states the result; steps reveal the **intermediate state** of how the model read the image (e.g. the slope step writes "passes through (0,0),(3,-2)" → exposes a misread; the reflection step writes "8 units to the left" → off by one grid).
4. **`feedback_description` is gold.** What the user actually wrote (e.g. "Answer in this case was only graphs 1 and 4") often gives you the correct answer directly.
5. **OCR text completeness heuristics**:
   - Length <50 chars + browser-chrome content → user only captured the navbar
   - Visible typos ("duught/neacher/mew") → poor OCR quality
   - Says "Refer to the figure" but `crop_is_skip=true` / no diagram → either OCR missed the figure OR user didn't capture it
   - "Part N of M" + depends on "previous results" → context missing

### B. Cross-validation (don't conclude without two-source corroboration)

6. **Image × OCR × answer triangulation**:
   - Image alone = only judges image completeness
   - OCR alone = only judges text accuracy
   - Answer alone = only judges output reasonableness
   - Triangulating = locates which step (vision / OCR / reasoning) failed
7. **Source-code semantic check.** When you suspect a field/flag/label, *grep the source* — don't guess from the name. Mistaking `crop_is_skip` for "user crop behavior" is the canonical version of this trap (it's actually emitted from the OCR pipeline as a Mathpix strategy signal).
8. **Cross-reference experiment assignments.** "Feature is fully shipped but bug still appears" → check the experiment definition + the source code's `isFlagXXX()` coverage + the user's actual experiment-arm in the events. Several "ghost" bugs were resolved by discovering 25% of traffic took a different code path than expected.

### C. Heuristic signals

9. **User behavior traces are gold.** Images often show:
   - Pre-checked options (filled blue circle, ✓) → user has a selection signal; the model should explicitly correct it
   - Pre-filled numbers, drawn coordinates → the user's wrong attempt
   - Page-jump traces, multi-part progress ("Part 6 of 9") → context-missing signal
10. **Model self-meta-comments.** Answers often contain meta-flags the model itself raised — scan keywords:
    - `Insufficient information` / `Unable to provide accurate answer` → model openly says data is incomplete
    - `Pre-filled answer ... is incorrect` / `This does not match` → model questions the pre-filled answer in image
    - `Assume ... is` + a specific number → model is guessing (data is missing)
11. **Subject × error-type priors**:
    - geometry + coordinate/label-read error → grid-snapping / diameter-radius confusion
    - chemistry + molecule-count question → SMILES rendering
    - prob & stat / accounting / economics + long completed text → domain-concept issue
    - MCQ + step-by-step explanation → answering off-options

### D. Clustering layer (single cases can't escape these)

12. **Sample images within a cluster.** For each cluster, sample 5–10 cases and inspect — confirm they really share a root cause. If the cluster is dirty, engineering attribution fails.
13. **Cluster by `user_pseudo_id` (last 30 days) / `picture_key sha` / `prompt_code` (last 7 days).** The hallmark of an engineering bug is multiple independent users hitting the same symptom — invisible from a single case.
14. **"Same pattern × N cases" is the threshold for engineering attribution.** A single case shouldn't be attributed to engineering; ≥3 cases of the same pattern → actively check source + experiments.

### E. Meta principles

15. **"Why did the user complain" ≠ "what did the model get wrong."** Cases where the model was correct but the user still rated it badly (no diagram drawn, the user themselves was wrong but the model didn't flag it, the user didn't understand the question) deserve their own bucket — these are **UX problems**, not algorithm problems.
16. **Hypothesis → verify → revise** loop: form bold hypotheses, falsify with data/code; if wrong, return to data — don't double down.
17. **Field semantics are not literal.** Names are written by humans and go stale; trust the emit-site source code over the field name.

---

## Closing notes

This methodology file represents the *durable* methods, not the conclusions
of any specific analysis. When you discover a new pattern through analysis:

1. If it's a **rule that prevents a class of mistakes** → add to the relevant
   "Defenses" section above (and consider whether it's also worth adding to
   `CLAUDE.md` for guaranteed loading)
2. If it's a **new analysis approach** → add a new section in "Six approaches"
   or "Special techniques"
3. If it's a **conclusion specific to one product/domain** → it doesn't belong
   here; put it in `business/` or your project's status doc
