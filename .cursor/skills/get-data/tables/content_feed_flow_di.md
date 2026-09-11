# rpt.rpt_content_feed_flow_di

> 内容 feed 页面流量中间表。
> as of 2026-08-05, source: 内容生态指标体系/content_feed_flow.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 内容feed流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app` |
| uicode | `new_kandian_homepage`（0624 发版后升级用户）、`content/kandian/recommend`（未升级 App） |
| 工厂表单 | 库选 `rpt` 后只填 `content_feed_flow_di` |
| 项目 SQL | `内容生态指标体系/content_feed_flow.sql` |

## 用途

- 内容 feed 页面**全部埋点**明细（不限 evt_id）
- 内容参数已预解析落表，下游可直接用
- 下游分发/消费分析优先扫本表，避免扫底层全量流量表

## 底表

| 类型 | 收窄条件 | 表 |
|------|----------|-----|
| 行为（全部 evt） | `uicode IN (...)`，**不限 evt_id** | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 曝光（全部 evt） | `uicode IN (...)`，**不限 evt_id**；`site` 写死 `'beike'`，`is_dau` 置空 | `rpt.rpt_comm_log_beike_exp_detail_di` |

## uicode（Locked，新旧并行）

| 版本 | uicode | 说明 |
|------|--------|------|
| 新版 | `new_kandian_homepage` | 0624 App 发版后升级用户 |
| 旧版 | `content/kandian/recommend` | 未升级 App 用户同日仍上报 |

**禁止**用 `active_date` 切两套 uicode。见 [docs/app-version-uicode-migration.md](../docs/app-version-uicode-migration.md)。

## 常见 evt_id（非穷举；落表含该 uicode 下全部）

| 事件 | evt_id | 说明 |
|------|--------|------|
| 卡片曝光（新） | `94408` | 多见于 `new_kandian_homepage` |
| 卡片点击（新） | `94409` | |
| 卡片曝光（旧） | `68193` | 多见于 `content/kandian/recommend` |
| 卡片点击（旧） | `68194` | |
| 页览等 | `1,3` / `1,4` 等 | 行为表，按实际上报 |

算卡片曝光/点击 UV 时下游自行 `WHERE evt_id IN (...)`。

## action 预解析字段

> 来源：《内容生态》埋点参数表 · 内容 feeds 列。`0806` 为发版说明，**不是** JSON key 后缀。

| 表字段 | 含义 | action key |
|--------|------|------------|
| `item_type` | 一级分类 | `$.fb_item_type` |
| `card_type` | 二级分类 | `$.card_type` |
| `share_media` | 内容体裁 | `$.business_type` |
| `action_date` | 发布时间 | `$.action_date` |
| `fb_expo_id` | 后端曝光唯一ID | `$.fb_expo_id` |
| `content_id` | 内容id | `$.article_id` |
| `content_tag` | 埋点展示文案（≠ 存量表供给侧 tag） | `$.content_title`；主理人识别见 [feed_content_analyze_table.md](feed_content_analyze_table.md) |
| `beike_id` | 贝壳号id | `$.beike_id` |
| `agent_ucid` | 经纪人id | `$.agent_ucid` |

参数表只列一套 key → **直接** `get_json_object`，**不要** `COALESCE` / 按 evt `CASE`。无内容参数的 evt（如页览）对应列为 null。

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「内容 feed」页面全部埋点明细，仅贝壳 App（页面 new_kandian_homepage / content/kandian/recommend）。覆盖：0624 发版后新版页面 new_kandian_homepage、未升级 App 仍走旧版 content/kandian/recommend；两套 uicode 并行纳入（不按 active_date 切流），该页面下全部 evt（含卡片曝光/点击 94408/94409、68193/68194、页览等），下游按 evt_id 自行筛选。内容参数字段（item_type、content_id、content_tag 等）已从 action 按参数表 key 预解析落表；无内容参数的 evt 对应列为 null。

## 加工逻辑

仅按 uicode `IN` 收窄 → 行为/曝光 `UNION ALL` → 最终 SELECT 解析 action。模板见 [templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md)。
