# rpt.rpt_content_detail_flow_di

> 内容详情页流量中间表。从底层曝光/点击表捞出内容详情相关埋点，仅贝壳 App。
> as of 2026-08-05, source: 内容生态指标体系/content_detail_flow.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 内容详情页流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app` |
| 工厂表单 | 库选 `rpt` 后只填 `content_detail_flow_di` |
| 项目 SQL | `内容生态指标体系/content_detail_flow.sql` |

## 用途

- 内容详情页消费 UV/PV、留存/复访、来源归因
- 下游分析**优先扫本表**，避免直接扫 `behavior_flow_di` / `beike_exp_detail_di`

## 底表

| 类型 | 表 |
|------|-----|
| 页览+点击 | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 元素曝光 | `rpt.rpt_comm_log_beike_exp_detail_di`（`site` 写 `'beike'`，`is_dau` 置空） |

## 加工逻辑（Locked）

1. 每张底表先按内容详情 `uicode IN (...)` 一次性收窄 → `click_raw` / `expo_raw`
2. 再按规则 `UNION ALL` 分流（禁止嵌套 `OR`）
3. 取两表公共字段落明细，不聚合
4. **不要**使用 `hive.cte.materialize.threshold`（本集群不支持）

## 页面与 source 规则

| 页面 | uicode | `action.source` 限制 |
|------|--------|----------------------|
| 视频详情页 | `community/shipindetail` | 不限 |
| 图文详情页 | `new_kandian_article` | 不限 |
| 行情数据 | `hangqing_content_app` | 不限 |
| 新房日照 | `csxx_light` | `zonghesousuo_jieguo` / `homepage1` / `new_kandian_homepage` |
| 新房航拍 | `csxx_3ddetailpage` | 同上 |
| 二手日照 | `lightshadow` | `c_resblock_detail` / `c_house_detail` |
| 二手航拍 | `overall` | 同上 |
| 小区漫游 | `panorama1` | `zonghesousuo_jieguo` / `homepage1` / `new_kandian_homepage` / `c_resblock_detail` |

`source` 取自 `get_json_object(action, '$.source')`。

## 页面曝光 evt_id（查数/聚合用）

从中间表算每日流量时：

| 页面 | 页面曝光 evt_id |
|------|----------------|
| 视频详情页 | `57827` |
| 图文详情页 | `83538` |
| 行情 / 日照 / 航拍 / 漫游 | `1,3` |

详见 [templates/content_detail_daily_traffic.md](../templates/content_detail_daily_traffic.md)。

## 核心字段

与 `behavior_flow_di` / `beike_exp_detail_di` 公共字段对齐；`is_dau` 仅行为表有，曝光侧置空。  
SELECT：`t1.dp` 透传；行为表 `t1.site`；曝光表 `'beike' AS site`（见 [sql-style.md](../docs/sql-style.md) §7.1）。

## 验数清单（中间表上线后）

用 **1 个 pt**（通常昨天），按层过，不要一上来全国全量对账：

| 层 | 查什么 | 通过标准 |
|----|--------|----------|
| ① 跑通 | `count(1)` / duid_uv / ucid_uv | 有分区、row_cnt>0、uv ≪ row_cnt |
| ② 边界 | `GROUP BY uicode`；`site,dp`；有 source 限制页的 `$.source` | 仅 8 个 uicode；site=beike、dp=app；source 无漏网 |
| ③ 对账 | 中间表 PV vs 底表同口径（先视频/图文，再 1 个有 source 页） | PV 一致（或差极小） |
| ④ 下游 | `content_detail_daily_traffic` / `evt_id` 分布 | 视频 57827、图文 83538、其余主 `1,3`；整体 UV ≤ 分页面 UV 之和 |

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「内容详情页」相关埋点明细，仅贝壳 App。覆盖：视频/图文/行情/新房日照/新房航拍/二手日照/二手航拍/小区漫游。其中新房日照/航拍限综搜、大首页、新看点；二手日照/航拍限小区详情、房源详情；小区漫游限综搜、大首页、新看点、小区详情；视频/图文/行情不限来源。
