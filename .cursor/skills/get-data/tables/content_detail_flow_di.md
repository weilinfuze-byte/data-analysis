# rpt.rpt_content_detail_flow_di

> 新二内容详情页流量中间表。从底层曝光/点击表捞出新二内容详情相关埋点，仅贝壳 App。**不含家装**。
> as of 2026-09-11, source: 内容生态指标体系/content_detail_flow.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 内容详情页流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app`；新二内容详情页 |
| 工厂表单 | 库选 `rpt` 后只填 `content_detail_flow_di` |
| 项目 SQL | `内容生态指标体系/content_detail_flow.sql` |

## 用途

- 新二内容详情页消费 UV/PV、留存/复访、来源归因
- 下游分析**优先扫本表**，避免直接扫 `behavior_flow_di` / `beike_exp_detail_di`

## 底表

| 类型 | 表 |
|------|-----|
| 页览+点击 | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 元素曝光 | `rpt.rpt_comm_log_beike_exp_detail_di`（`site` 写 `'beike'`，`is_dau` 置空） |

## 加工逻辑（Locked）

1. 每张底表按新二内容详情 `uicode IN (...)` 一次性收窄 → `click_raw` / `expo_raw`
2. `UNION ALL` 合并行为+曝光，**不限** `action.source`（入口归因留给下游）
3. 取两表公共字段落明细，不聚合
4. **不要**使用 `hive.cte.materialize.threshold`（本集群不支持）

## 页面 uicode（中间表收录）

| 页面 | uicode | 备注 |
|------|--------|------|
| 视频详情页 | `community/shipindetail` | |
| 图文详情页 | `new_kandian_article` | |
| 行情数据 | `hangqing_content_app` | |
| 交易故事 | `jiaoyi_gushi` | |
| 二手日照原生 | `sunshine_content` | APP 原生 |
| 相似的人 | `usershowing_detail` | |
| 新房日照 | `csxx_light` | H5 |
| 新房航拍 | `csxx_3ddetailpage` | H5 |
| 二手日照 | `lightshadow` | H5 |
| 二手航拍 | `overall` | H5 |
| 小区漫游 | `panorama1` | H5 |

**不含**家装物料详情（如 `jiazhuang_video_page_h5` / `ai_case_page` / 设计师物料等）。

> 2026-09-16 对照产品截图：上表详情页 uicode **已全部覆盖**。截图备注里的 `homepage1` / `new_kandian_homepage` / `zonghesousuo_jieguo` 等是**入口 source**，不是详情页 uicode；中间表按详情 uicode 收窄、不限 source，从这些入口进详情的流量仍会进表。

## 下游可选 source 限制（参考，非中间表过滤）

分场景 / 入口对账时再加；整体消费可不限。

| 页面 | 常见 `action.source` |
|------|----------------------|
| 新房日照 / 新房航拍 | `zonghesousuo_jieguo` / `homepage1` / `new_kandian_homepage` |
| 二手日照 / 二手航拍 | `c_resblock_detail` / `c_house_detail` |
| 小区漫游 | `zonghesousuo_jieguo` / `homepage1` / `new_kandian_homepage` / `c_resblock_detail` |

`source` 取自 `get_json_object(action, '$.source')`。

## 页面曝光 evt_id（查数/聚合用）

从中间表算每日流量时：

| 页面 | 页面曝光 evt_id |
|------|----------------|
| 视频详情页 | `57827` |
| 图文详情页 | `83538` |
| 其余新二详情页 | `1,3` |

详见 [templates/content_detail_daily_traffic.md](../templates/content_detail_daily_traffic.md)。

## 核心字段

与 `behavior_flow_di` / `beike_exp_detail_di` 公共字段对齐；`is_dau` 仅行为表有，曝光侧置空。  
SELECT：`t1.dp` 透传；行为表 `t1.site`；曝光表 `'beike' AS site`（见 [sql-style.md](../docs/sql-style.md) §7.1）。

## 解析 content_id（Locked）

| 页面 | action key | 说明 |
|------|------------|------|
| 视频详情页 `community/shipindetail` | `$.video_id` | **就是内容 id**，不要用 `$.article_id` |
| 图文详情页 `new_kandian_article` | `$.content_id` | |

视频详情页：

```sql
get_json_object(t1.action, '$.video_id') AS content_id
```

图文详情页：

```sql
get_json_object(t1.action, '$.content_id') AS content_id
```

JOIN 时先解析成列再等值关联，**禁止** `JOIN ON get_json_object(...)`。

## 内容商机归因

商机 `parent_scene_id` = 本表 `scene_id`（页面曝光 evt）。**仅用于按内容下钻**，不是内容商机类型判定条件。见 [content_sj_trans_detail_da.md](content_sj_trans_detail_da.md)。

## 验数清单（中间表上线后）

用 **1 个 pt**（通常昨天），按层过，不要一上来全国全量对账：

| 层 | 查什么 | 通过标准 |
|----|--------|----------|
| ① 跑通 | `count(1)` / duid_uv / ucid_uv | 有分区、row_cnt>0、uv ≪ row_cnt |
| ② 边界 | `GROUP BY uicode`；`site,dp` | 仅字典列出的 11 个 uicode；site=beike、dp=app |
| ③ 对账 | 中间表 PV vs 底表同口径（先视频/图文） | PV 一致（或差极小） |
| ④ 下游 | `content_detail_daily_traffic` / `evt_id` 分布 | 视频 57827、图文 83538、其余主 `1,3`；整体 UV ≤ 分页面 UV 之和 |

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「新二内容详情页」相关埋点明细，仅贝壳 App。按 uicode 收录视频/图文/行情/交易故事/日照航拍漫游/相似的人等新二详情页；**不含家装**；**不限**入口 source，分场景归因由下游自行过滤。

## 引用本表的指标 / 分析

- [内容消费 UV/PV](../metrics/content-ecology.md#消费)
- [内容商机归因](../metrics/commerce.md)
