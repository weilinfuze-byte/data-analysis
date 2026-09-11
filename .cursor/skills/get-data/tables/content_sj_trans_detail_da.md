# rpt.rpt_content_sj_trans_detail_da

> 内容商机明细中间表。在 `rpt_asm_sj_trans_detail_da` 全字段基础上增加内容商机类型。
> as of 2026-09-11, source: 北京内容商机分大部/content_sj_trans_detail_da.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 内容商机明细中间表 |
| 全名 | `rpt.rpt_content_sj_trans_detail_da` |
| 粒度 | 商机 × 内容商机类型（`commercial_id` + `content_sj_type`） |
| 分区 | `pt`（日快照 da；每分区含截至该日源表快照中的全部内容商机） |
| 工厂表单 | 库选 `rpt` 后只填 `content_sj_trans_detail_da` |
| 项目 SQL | `北京内容商机分大部/content_sj_trans_detail_da.sql` |

## 用途

- 内容商机三类（展位 / 溯源 / 保护）统一明细底表
- 下游按城市 / 大部 / 内容归因聚合，避免重复写三类 UNION
- 字段与 [asm_sj_trans_detail_da.md](asm_sj_trans_detail_da.md) 对齐，可直接复用商机转化分析习惯

## 新增字段

| 字段 | 类型 | 含义 |
|------|------|------|
| content_sj_type | string | 内容商机类型：`booth`=展位 / `trace`=溯源 / `protect`=保护 |

## 三类口径（Locked）

| content_sj_type | 含义 | 识别规则 |
|-----------------|------|----------|
| `booth` | 展位商机 | `is_commercial_couple=1` + 内容详情页 adid 展位列表（2026-09-11 更新，去重 46 个；见 ETL `content_sj_trans_detail_da.sql`） |
| `trace` | 溯源商机 | **并集**：(`app_id`/`ele_app_id` ∈ {`BU_PingTai_new_kandian_article_zixun`,`BU_PingTai_community_shipindetail_zixun`}) **或** (`uicode` ∈ {`new_kandian_article`,`community/shipindetail`}) + JOIN 商机明细；**不限 `distance`**（2026-09-11）。两口径重叠≈0，禁止互相替换 |
| `protect` | 保护商机 | `rpt_asm_sj_detail_di` 中 `digv_b` 内容直播保护策略 → JOIN 商机明细取全字段 |

> **不要求** `parent_scene_id` 归因内容详情页；adid / 溯源 / 保护命中即计入。

## 打标 vs 归因（Locked）

| 用途 | 要不要 `parent_scene_id` |
|------|--------------------------|
| 判定是否内容商机（写 `content_sj_type`） | **不要**。命中即计入 |
| 按内容 / 生产人拆 | **要**。`parent_scene_id` = `rpt_content_detail_flow_di.scene_id` → 解析 `content_id` |

禁止把「能否归因到某条内容」当成「是不是内容商机」的过滤条件。

## 公共过滤（底座商机）

- ETL 读源表 `pt = '${-1d_pt}'`（da 全量快照，不限 occur_date）
- 下游查昨天商机：`pt = '${-1d_pt}'` + `occur_date = '${-1d_yyyy-MM-dd}'`
- 下游查历史商机（带看/成交匹配）：`pt = '${-1d_pt}'` + `occur_date <= '${-1d_yyyy-MM-dd}'`
- `business_name IN ('二手', '新房')`
- `is_commercial_couple = 1`
- **不限** `website_name` / `client_name`（2026-09-11：原仅贝壳 App，已放开）

## 与源表关系

- 字段 1–118 与 [asm_sj_trans_detail_da.md](asm_sj_trans_detail_da.md) 一致（不含分区 `pt`）
- 同一 `commercial_id` 可同时命中多类型 → **多行**（每类型一行）

## 计数口径（Locked）

| 场景 | 写法 |
|------|------|
| 分类型计数 | 按 `content_sj_type` 分组，各自 `count(DISTINCT commercial_couple_id)`，**允许重叠** |
| 内容商机总量 | 不分类型，`count(DISTINCT commercial_couple_id)` 跨类型去重 |
| 注意 | 三类数字相加 **可以大于** 总量；不要把分类型直接相加当总量 |

```sql
-- 分类型（允许重叠）
count(DISTINCT CASE WHEN content_sj_type = 'booth'   THEN commercial_couple_id END) AS sj_booth_cnt
,count(DISTINCT CASE WHEN content_sj_type = 'trace'   THEN commercial_couple_id END) AS sj_trace_cnt
,count(DISTINCT CASE WHEN content_sj_type = 'protect' THEN commercial_couple_id END) AS sj_protect_cnt
-- 总量（去重）
,count(DISTINCT commercial_couple_id) AS sj_total_cnt
```

## 已知坑

- 保护类先由 `rpt_asm_sj_detail_di` 圈 `commercial_id`，再回 JOIN `rpt_asm_sj_trans_detail_da` 取全字段
- 内容商机溯源 **不限** `distance`；若其它场景要滤步长，`distance` 为 string，写 `BETWEEN` 勿 cast
- **不要求** `parent_scene_id` 归因内容页；按内容维度下钻需另 JOIN `rpt_content_detail_flow_di`
- 禁止与工厂 `is_show` / `is_deal` 混称为「商机带看/成交量」；带看/成交人店匹配见 [metrics/commerce.md](../metrics/commerce.md)

## 引用本表的指标 / 分析

- [内容商机三类](../metrics/commerce.md)
- 模板：[content_sj_from_intermediate.md](../templates/content_sj_from_intermediate.md)
