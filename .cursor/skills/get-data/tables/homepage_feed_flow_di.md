# rpt.rpt_homepage_feed_flow_di

> 大首页 feed 流量中间表。
> as of 2026-08-05, source: 内容生态指标体系/homepage_feed_flow.sql + 埋点参数表首页列（0806）

| 元信息 | 值 |
|--------|----|
| 中文名 | 首页feed流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app` |
| uicode | `homepage1` |
| 工厂表单 | 库选 `rpt` 后只填 `homepage_feed_flow_di` |
| 项目 SQL | `内容生态指标体系/homepage_feed_flow.sql` |

## 用途

- 首页 feed **全部卡片**曝光 / 点击 / 滑动明细
- `item_type` / `card_type` 等已预解析落表
- 下游分发 / 物料 PCTR·UCTR 优先扫本表

## 底表

| 类型 | evt_id | 表 |
|------|--------|-----|
| 卡片点击 | `40397` | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 滑动曝光 | `54872` | `rpt.rpt_log_bi_user_behivor_detail_flow_di`（**只从行为表取**） |
| 卡片曝光 | `40400` | `rpt.rpt_comm_log_beike_exp_detail_di` |

## 曝光硬规则

本表落 **原始** 40400/40397/54872。下游**凡算曝光**（UV/PV/PCTR·UCTR 分母）必须 `40400 ∩ 54872`，禁止裸用 40400。见 [docs/sql-style.md](../docs/sql-style.md) §8、[metrics/active.md](../metrics/active.md)。

## action 预解析字段（首页 key ≠ 搜索结果页）

| 表字段 | 含义 | action key |
|--------|------|------------|
| `item_type` | 一级分类 | `$.fb_item_type` |
| `card_type` | 二级分类 | `$.card_type` |
| `share_media` | 内容体裁 | `$.type` |
| `action_date` | 发布时间 | `$.action_date` |
| `fb_expo_id` | 后端曝光唯一ID | `$.fb_expo_id` |
| `content_id` | 内容id | `$.content_id` |
| `content_tag` | 内容标签 | `$.content_title` |
| `beike_id` | 贝壳号id | `$.beike_id` |
| `agent_ucid` | 经纪人id | `$.agent_ucid` |

与搜索竖卡差异：`item_type`←`fb_item_type`，`share_media`←`type`，`content_id`←`content_id`（非 `fb_item_id`）。

字段顺序：先 `item_type`，再 `card_type`。

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「大首页 feed（homepage1）」相关埋点明细，仅贝壳 App。覆盖：卡片曝光 40400、卡片点击 40397、滑动曝光 54872。全部 feed 卡片均含，不限 card_type。下游算曝光须做 40400∩54872。

## 加工逻辑

先 `uicode`+`evt_id` 收窄 → `UNION ALL`。模板见 [templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md)。物料 CTR：[templates/homepage_feed_material_ctr.md](../templates/homepage_feed_material_ctr.md)。
