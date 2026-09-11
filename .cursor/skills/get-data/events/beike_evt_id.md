# 贝壳 evt_id 字典

> 三层组织：Locked（必记）→ Core（常用）→ Discovery（临时查数仓）

## Locked — 通用

| evt_id | 含义 | 表 |
|--------|------|-----|
| `1,3` | 页面浏览 / DAU | behavior_flow_di |
| `91912` | 底部轮播曝光（专属管家） | beike_exp |
| `91914` | 底部轮播点击（专属管家） | behavior_flow |
| `92395` | 交易页底部轮播曝光 | beike_exp |
| `92396` | 交易页底部轮播点击 | behavior_flow |
| `91989` | 消息列表曝光 | beike_exp |
| `91990` | 消息列表点击 | behavior_flow |
| `91921` | 动态主页 Tab 曝光 | beike_exp |
| `91922` | 动态主页 Tab 点击 | behavior_flow |

## Locked — P2C 工具结果卡

| evt_id | 含义 |
|--------|------|
| 92247 | 购房能力评估结果卡曝光 |
| 92259 | 房贷方案结果卡曝光 |
| 92272 | 税费计算结果卡曝光 |
| 92290 | 购房成本规划结果卡曝光 |

## Core — Feed（和平老师口径）

| feed_type | 曝光 evt_id | 滑动 evt_id | 点击 evt_id |
|-----------|-------------|-------------|-------------|
| 大首页 feed | 40400 | 54872 | 40397 等 |
| 新房首页 feed | 14093 | 60252 | — |
| 二手首页 feed | 13942 | 60251 | — |
| 个人中心 feed | 58879 | 58880 | — |
| 关注 feed | 60012 | 60012 | — |

uicode 配对：`homepage1`, `newhouse/homepage(v2)`, `homepage/ershou_homev2`, `profile2`, `guanzhu_v2`

## Core — 榜单

| evt_id | 含义 | uicode |
|--------|------|--------|
| 67893, 41032 | 曝光 | homepage_bangdan, ershou/bangdan |
| 67894, 19835 | 点击 | 同上 |

## Core — 二手详情页（示例）

| evt_id | 含义 |
|--------|------|
| 93706 | 模块曝光 |
| 93707 | 点击-修改 |
| 93708 | 点击-结果 |
| 93710 | 点击-问题 |

## Core — 小区详情（示例）

| evt_id | 含义 |
|--------|------|
| 82883, 54055 | 曝光 |
| 82884, 54054 | 点击 |

## Core — 内容生态分发（2026-07 confirmed）

> as of 2026-07-30, source: 内容渗透流量表埋点记录 + 项目 SQL 对齐

| 场景 | uicode | 曝光 evt_id | 点击 evt_id | action 限制 |
|------|--------|-------------|-------------|-------------|
| 内容Feeds | `new_kandian_homepage`, `content/kandian/recommend` | `94408`, `68193` | `94409`, `68194` | 无；中间表捞**全部 evt**，见下方 |
| 首页feed（大首页推荐） | `homepage1` | `40400` ∩ `54872` | `40397` | 曝光一律滑动有效曝光；内容卡用 `card_type` **剔除法**（见 [homepage_feed_content_card_filter.md](../docs/homepage_feed_content_card_filter.md)）；中间表 `content_tag`←`$.content_tag`（≠ 内容 feed 的 `$.content_title`） |
| 搜索结果页 | `zonghesousuo/jieguo` | 见下方 | 见下方 | `tab_name` + `module_type` |
| 二手详情页-头部+底部推荐 | `ershou/detail` | `80579`, `87223` | `80580`, `87222` | 头部 `$.source_type` 白名单；底部剔 `$.from`×`$.card_type`；中间表 `rpt.rpt_content_ershou_detail_flow_di` |
| 小区详情页-头部+底部推荐 | `communitydetailv2` | `28737`, `82883` | `28738`, `82884` | `28737/28738` 过滤 `$.source_type`；`82883/82884` 剔除 `$.card_type` |

### 内容 feed（2026-08 confirmed）

> 中间表 `rpt.rpt_content_feed_flow_di`；完整规则 [tables/content_feed_flow_di.md](../tables/content_feed_flow_di.md)
>
> - 两套 uicode **并行** `IN`，不按 `active_date` 切流（0624=发版日）
> - 中间表：**不限 evt_id**（该页面全部埋点）；卡片指标下游筛 `94408/94409`、`68193/68194`
> - action key（参数表）：`fb_item_type` / `card_type` / `business_type` / `action_date` / `fb_expo_id` / `article_id` / `content_title` / `beike_id` / `agent_ucid` — 直取，无 COALESCE

### 点后推 · 二导新户型卡（2026-08 confirmed）

> 搜「点后推 / 二导新户型卡 / 搜索+二手频道页曝光点击」。走**流量底表**，不要用内容生态中间表。
> 指标 [metrics/funnel.md](../metrics/funnel.md)；模板 [templates/ershou_push_huxing_card_ctr.md](../templates/ershou_push_huxing_card_ctr.md)
> as of 2026-08-10, source: 点后推二导新户型卡/workflow.sql

| 场景 | uicode | 曝光 | 点击 | 物料过滤 |
|------|--------|------|------|----------|
| 搜索结果页 | `zonghesousuo/jieguo` | `80326` | `80327` | `get_json_object(action,'$.item_type') = '二导新户型卡'` |
| 二手首页 | 不限（evt 已定位场景） | `93280` | `93287` | 无 |

- 曝光表：`rpt.rpt_comm_log_beike_exp_detail_di`
- 点击表：`rpt.rpt_log_bi_user_behivor_detail_flow_di`
- 搜索页必须带 `uicode`；二手首页只筛 `evt_id`

### 搜索结果页内容卡片（2026-08 confirmed）

> 中间表 `rpt.rpt_content_search_result_flow_di`；完整规则 [tables/content_search_result_flow_di.md](../tables/content_search_result_flow_di.md)
>
> 内容横卡/竖卡口径走中间表。**点后推二导新户型卡**不走本表，见上一节。

| 场景 | tab_name | module_type | 曝光 | 点击 |
|------|----------|-------------|------|------|
| 综合-底部竖卡 | 综合 | contentFeed | 80326 | 80327 |
| 综合-横卡（0806+） | 综合 | contentCardModule | 80326 | 80327 |
| 内容 tab（0709+，含历史评测） | 内容 / 评测 | contentFeed | 80326 | 80327 |
| 旧横卡（0806 前） | — | — | 93750 | 93751 | 落表 tab=综合, module=contentCardModule |
| 页览 | — | — | — | 1,3 / 1,4 |

### 内容详情页曝光（2026-09 confirmed）

> 中间表 `rpt.rpt_content_detail_flow_di`；每日流量 [templates/content_detail_daily_traffic.md](../templates/content_detail_daily_traffic.md)

| 页面 | uicode | 页面曝光 evt_id |
|------|--------|----------------|
| 视频详情页 | community/shipindetail | 57827 |
| 图文详情页 | new_kandian_article | 83538 |
| 其余新二内容详情页 | hangqing_content_app / jiaoyi_gushi 等 | 1,3 |

### 小区详情页头部+底部推荐（2026-08-13 confirmed）

> 中间表 `rpt.rpt_content_resblock_detail_flow_di`；完整规则 [tables/content_resblock_detail_flow_di.md](../tables/content_resblock_detail_flow_di.md)

| 模块 | 曝光 | 点击 | action 过滤 |
|------|------|------|-------------|
| 头部推荐 | `28737` | `28738` | `$.source_type` ∈ 视频 / 街访 / 解读 / 探房 |
| 底部推荐 | `82883` | `82884` | **剔除** `$.card_type` ∈ `xinfang_project_name` / `ershou_house` / `resblock` / `resblock_rankinglist` |

### 二手详情页内容（2026-08 confirmed）

> 中间表 `rpt.rpt_content_ershou_detail_flow_di`；完整规则 [tables/content_ershou_detail_flow_di.md](../tables/content_ershou_detail_flow_di.md)

| 模块 | 曝光 | 点击 | action 过滤 |
|------|------|------|-------------|
| 头部推荐 | `80579` | `80580` | `$.source_type` IN (探房, 业主vlog, 房源视频, 业主讲房, 视频) |
| 底部推荐 | `87223` | `87222` | **剔除** `$.from`×`$.card_type`：二手×房源卡片、新房×新房楼盘、新房×土拍 |

底部不要用 `card_type` 白名单。`from` 取值：`内容` / `二手` / `新房`。

### 首页feed滑动曝光规则（强约束，2026-08-05）

> **凡计算首页 feed「曝光」**（UV / PV / PCTR·UCTR 分母 / 渗透），**一律**用滑动有效曝光，**禁止**裸用 `40400`。

- 有效曝光 = 当日卡片曝光 `40400` ∩ 当日滑动 `54872`（按 `active_date` + **duid** JOIN）
- 去重键：**duid**（内容生态统一口径，见 [metrics/content-ecology.md](../metrics/content-ecology.md)）
- 滑动事件：`evt_id='54872'`；**仅从行为表**取（或中间表 `rpt.rpt_homepage_feed_flow_di` 中已落的 54872）
- 物料维度（`show_card_type` / `card_type`）：先建滑动用户集合，再对 `40400` 明细 `INNER JOIN` 后按物料聚合（54872 本身无卡片级字段）；**一级分类用 `show_card_type`，勿用 `item_type`**
- 中间表可同时存 40400/40397/54872 原始事件；**下游算曝光指标时仍必须做交集**
- 物料 CTR 模板：[templates/homepage_feed_material_ctr.md](../templates/homepage_feed_material_ctr.md)

## Discovery

新 evt_id 不在本文件时，在数仓查询：

```sql
SELECT DISTINCT evt_id, uicode
FROM rpt.rpt_log_bi_user_behivor_detail_flow_di
WHERE pt = '${-1d_pt}'
  AND lower(uicode) LIKE '%{keyword}%'
LIMIT 100
```

## JSON action 过滤（非 evt_id）

| 键 | 示例值 | 用途 |
|----|--------|------|
| $.tab_name | 综合 / 内容 / 评测；交易专家 | 搜索结果页一级 tab；动态主页 Tab |
| $.module_type | contentFeed / contentCardModule | 搜索结果页内容卡片；综合竖卡/内容tab vs 0806+横卡 |
| $.source | zonghesousuo_jieguo / homepage1 / c_resblock_detail 等 | 内容详情页入口归因 |
| $.business_type | 交易专家 / osa_jiaoyizhuanjia | 入口过滤 |
| $.strategy_info | policy_issuance | 专属管家入口 |
| $.ab_test_sign | ab979-1315-4079 | AB 分组 |
| $.ab_test | ab1292-1632-5134 | 房源详情 AB |
| $.source_type | 探房/业主vlog/房源视频/业主讲房/视频；视频/街访/解读/探房 | 二手详情**头部**白名单；小区详情页头部推荐 |
| $.from | 内容 / 二手 / 新房 | 二手详情页**底部**推荐来源；落表列名 `from_val` |
| $.card_type | 视频类/业主自荐/小区点评/房源卡片/新房楼盘/土拍 等；小区详情底部剔除 xinfang_project_name/ershou_house/resblock/resblock_rankinglist | 首页feed；二手详情底部与 `$.from` 组合剔除；小区详情底部剔除 |
| $.item_type | 二导新户型卡 | 搜索结果页 80326/80327 点后推物料；≠ 首页feed 一级 `$.show_card_type`（旧 `$.fb_item_type`） |
| $.show_card_type | （枚举见埋点表） | 首页feed **一级分类**；落表 `show_card_type` |
| $.tab_id | 推荐 / … | 首页feed tab；落表 `tab_id`；周报内容卡默认 **`= '推荐'`**（仅 40400/40397；54872 不加）；AB 是否限 tab **每次确认** |
| $.content_tag | （标签串） | 首页feed 中间表落表 `content_tag`（2026-09-11；旧 ETL 误用 `$.content_title`） |
| $.content_title | （展示文案） | 内容 feed 中间表落表 `content_tag`；**不是**首页feed 现行 key |
| $.fb_combine_ab_test_id | `reco_rule-c006-…` 等完整串 | 首页feed 推荐规则/AB；**完整值 IN**，禁止 LIKE；桶映射不写死，每次确认。见 [dimensions.md](../dimensions.md) |
| $.fb_combine_service_id | 如 `c006` | 是否过滤每次确认 |
