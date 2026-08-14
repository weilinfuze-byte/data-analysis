# rpt.rpt_content_sj_trans_detail_da

> 内容商机明细中间表。在 `rpt_asm_sj_trans_detail_da` 全字段基础上增加内容商机类型。
> as of 2026-08-14, source: 北京内容商机分大部/content_sj_trans_detail_da.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 内容商机明细中间表 |
| 全名 | `rpt.rpt_content_sj_trans_detail_da` |
| 粒度 | 商机 × 内容商机类型（`commercial_id` + `content_sj_type`） |
| 分区 | `pt`（日快照；分区内存 `occur_date = pt` 对应业务日） |
| 工厂表单 | 库选 `rpt` 后只填 `content_sj_trans_detail_da` |
| 项目 SQL | `北京内容商机分大部/content_sj_trans_detail_da.sql` |

## 用途

- 内容商机三类（展位 / 溯源 / 保护）统一明细底表
- 下游按城市 / 大部 / 内容归因聚合，避免重复写三类 UNION
- 字段与 `rpt_asm_sj_trans_detail_da` 对齐，可直接复用商机转化分析习惯

## 新增字段

| 字段 | 类型 | 含义 |
|------|------|------|
| content_sj_type | string | 内容商机类型：`booth`=展位 / `trace`=溯源 / `protect`=保护 |

## 三类口径（Locked）

| content_sj_type | 含义 | 识别规则 |
|-----------------|------|----------|
| `booth` | 展位商机 | `is_commercial_couple=1` + 内容详情页 adid 展位列表 |
| `trace` | 溯源商机 | 溯源表 uicode ∈ {视频详情, 图文详情} + `distance 1–7` + JOIN 商机明细 |
| `protect` | 保护商机 | `rpt_asm_sj_detail_di` 中 `digv_b` 内容直播保护策略 → JOIN 商机明细取全字段 |

> **不要求** `parent_scene_id` 归因内容详情页；adid / 溯源 / 保护命中即计入。

## 公共过滤（底座商机）

- ETL 读源表 `pt = '${-1d_pt}'`（da 全量快照，不限 occur_date）
- 下游查昨天商机：`pt = '${-1d_pt}'` + `occur_date = '${-1d_yyyy-MM-dd}'`
- 下游查历史商机（带看/成交匹配）：`pt = '${-1d_pt}'` + `occur_date <= '${-1d_yyyy-MM-dd}'`
- `business_name IN ('二手', '新房')`
- `is_commercial_couple = 1`
- `website_name = '贝壳'`，`client_name = 'app'`

## 与源表关系

- 字段 1–118 与 [asm_sj_trans_detail_da.md](../.cursor/skills/get-data/tables/asm_sj_trans_detail_da.md) 一致（不含分区 `pt`）
- 同一 `commercial_id` 可同时命中多类型 → **多行**（每类型一行）

## 计数口径（Locked）

| 场景 | 写法 |
|------|------|
| 分类型计数 | 按 `content_sj_type` 分组，各自 `count(DISTINCT commercial_couple_id)`，**允许重叠** |
| 内容商机总量 | 不分类型，`count(DISTINCT commercial_couple_id)` 跨类型去重 |
| 注意 | 三类数字相加 **可以大于** 总量；不要把分类型直接相加当总量 |

## 已知坑

- 保护类先由 `rpt_asm_sj_detail_di` 圈 `commercial_id`，再回 JOIN `rpt_asm_sj_trans_detail_da` 取全字段
- 溯源 `distance` 为 string，过滤写 `BETWEEN 1 AND 7`，勿 cast
- **不要求** `parent_scene_id` 归因内容页；按内容维度下钻需另 JOIN `rpt_content_detail_flow_di`
- 禁止与工厂 `is_show` / `is_deal` 混称为「商机带看/成交量」；带看/成交人店匹配见 [metrics/commerce.md](../.cursor/skills/get-data/metrics/commerce.md)
