# rpt.rpt_homepage_feed_flow_di

> 大首页 feed 流量中间表。
> as of 2026-08-27, source: 内容生态指标体系/homepage_feed_flow.sql；一级分类改为 `show_card_type`

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
- `show_card_type` / `card_type` 等已预解析落表
- 下游分发 / 物料 PCTR·UCTR 优先扫本表

## 底表

| 类型 | evt_id | 表 |
|------|--------|-----|
| 卡片点击 | `40397` | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 滑动曝光 | `54872` | `rpt.rpt_log_bi_user_behivor_detail_flow_di`（**只从行为表取**） |
| 卡片曝光 | `40400` | `rpt.rpt_comm_log_beike_exp_detail_di` |

## 曝光 / PV 口径（场景分流）

本表落 **原始** 40400/40397/54872。下游口径**按场景选**，不要一律套一种：

| 场景 | 曝光 | PV | 说明 |
|------|------|-----|------|
| 周报内容卡 / 物料 CTR（默认） | **必须** `40400 ∩ 54872` | **`fb_expo_id × duid`**（`count(distinct concat(nvl(fb_expo_id,''),'#',duid))`） | 禁止裸 `40400`；禁止只用 `count(1)` |
| 日常监控日表（`首页feed指标表/`） | **双口径**：全量 `40400` + 有效 `40400∩54872` | **双口径**：`count(1)` + `count(distinct fb_expo_id)` | UV 一律 `duid`；点击 `40397` 不限滑动 |
| AB / 内容占比实验 | 写 SQL 前问用户 | 写 SQL 前问用户 | 桶映射不写死，见 [dimensions.md](../dimensions.md) |

见 [docs/sql-style.md](../docs/sql-style.md) §8、[metrics/active.md](../metrics/active.md)。

## action 预解析字段（首页 key ≠ 搜索结果页）

| 表字段 | 含义 | action key |
|--------|------|------------|
| `item_type` | 原一级分类（兼容保留） | `$.fb_item_type` |
| `card_type` | 二级分类 | `$.card_type` |
| `share_media` | 内容体裁 | `$.type` |
| `action_date` | 发布时间 | `$.action_date` |
| `fb_expo_id` | 后端曝光唯一ID | `$.fb_expo_id` |
| `content_id` | 内容id | `$.content_id` |
| `content_tag` | 内容标签 | `$.content_tag`（2026-09-11 修正；旧版误用 `$.content_title`）。**分区注意**：已重刷分区（如 2026-09）才是新 key；未重刷分区（如 7/8 月）仍可能是旧 `content_title` 语义 |
| `beike_id` | 贝壳号id | `$.beike_id` |
| `agent_ucid` | 经纪人id | `$.agent_ucid` |
| `show_card_type` | **一级分类（现行）** | `$.show_card_type` |
| `tab_id` | tab名称 | `$.tab_id` |

- **2026-08-27**：一级分类由 `item_type`/`$.fb_item_type` 改为 `show_card_type`/`$.show_card_type`；另追加 `tab_id`（`$.tab_id`）区分 tab
- 已建表不可删字段、不可改顺序；`show_card_type`、`tab_id` **依次追加表尾**
- 已建表变更（若已有 `show_card_type` 则只 ADD `tab_id`）：
  ```sql
  ALTER TABLE rpt.rpt_homepage_feed_flow_di
  ADD COLUMNS (`tab_id` string COMMENT 'tab名称');
  ```
- 下游物料分析：一级优先 `show_card_type`，二级 `card_type`；按 tab 用 `tab_id`；勿再用 `item_type` 当一级主维度
- **空值归并（监控日表 Locked，2026-09）**：`show_card_type` 空则用 `item_type`；`tab_id` 空/`-911`/`null` 归并为 `推荐`
- **推荐 tab（周报内容卡默认）**：`tab_id = '推荐'`；只滤 40400/40397，**54872 不加 tab**。下游**直接用表列 `tab_id`**
- **内容卡判定**：剔除法（35 类黑名单）+ `item_type` 剔 `xinfang_project_name`/`ershou_house`；见 [docs/homepage_feed_content_card_filter.md](../docs/homepage_feed_content_card_filter.md)
- **AB**：完整值 `IN (...)`，禁止 LIKE；桶列表每次确认。见 [dimensions.md](../dimensions.md)
- **日常监控结果表**：`首页feed指标表/`（整体 / tab / 物料 / tab×物料）；`content_*_share` 仅落 `card_scope='all'`
- **内容点击归因商机**：`首页feed指标表/homepage_feed_content_click_sj_*.sql`；见 [metrics/commerce.md](../metrics/commerce.md)

与搜索竖卡差异：一级←`show_card_type`，`share_media`←`type`，`content_id`←`content_id`（非 `fb_item_id`）。

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「大首页 feed（homepage1）」相关埋点明细，仅贝壳 App。覆盖：卡片曝光 40400、卡片点击 40397、滑动曝光 54872。全部 feed 卡片均含，不限 card_type。一级分类为 show_card_type；tab 为 tab_id。下游曝光/PV 按场景选口径（周报有效曝光 vs 监控双口径），见上文。

## 加工逻辑

先 `uicode`+`evt_id` 收窄 → `UNION ALL`。模板见 [templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md)。物料 CTR：[templates/homepage_feed_material_ctr.md](../templates/homepage_feed_material_ctr.md)。
