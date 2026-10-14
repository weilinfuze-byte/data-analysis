# rpt.rpt_content_search_result_flow_di

> 搜索结果页内容卡片流量中间表。首页搜索与二手搜索同一张表，用 `uicode` 区分。
> as of 2026-10-14, source: 内容生态指标体系/中间表/search_result_flow.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 搜索结果页内容流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app` |
| uicode | `zonghesousuo/jieguo`（首页搜索）、`ershousousuo/jieguo`（二手搜索） |
| 工厂表单 | 库选 `rpt` 后只填 `content_search_result_flow_di` |
| 项目 SQL | `内容生态指标体系/中间表/search_result_flow.sql` |

## 用途

- 搜索结果页**所有内容卡片**曝光/点击明细
- `tab_name` / `module_type` 已预解析落表，无需重复 `get_json_object`
- 下游分发/消费分析优先扫本表

## 底表

| 类型 | evt_id | 表 |
|------|--------|-----|
| 点击 / 页览 | `80327`, `93751`, `1,3`, `1,4` | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 曝光 | `80326`, `93750` | `rpt.rpt_comm_log_beike_exp_detail_di` |

## 内容卡片口径（Locked）

| 场景 | tab_name | module_type | 曝光 | 点击 | 说明 |
|------|----------|-------------|------|------|------|
| 综合-底部竖卡 | `综合` | `contentFeed` | 80326 | 80327 | |
| 综合-横卡 | `综合` | `contentCardModule` | 80326 | 80327 | **0806+** 更新 app 后横卡迁入 80326/80327 |
| 内容 tab | `内容` / `评测` | `contentFeed` | 80326 | 80327 | **0709+** 评测 tab 改名为内容；历史保留 `评测` |
| 旧横卡 | `综合` | `contentCardModule` | 93750 | 93751 | **0806 前**；落表固定赋值 |
| 页览 | — | — | — | `1,3` / `1,4` | 行为表，非卡片 |

过滤键：`get_json_object(action, '$.tab_name')`、`get_json_object(action, '$.module_type')`。

## action 预解析字段

竖卡与横卡 **action key 不同**，按 **evt_id** 区分：

| 表字段 | 80326 / 80327 | 93750 / 93751 |
|--------|---------------|---------------|
| `content_id` | `$.fb_item_id` | `$.content_id` |
| 其余 | card_type / share_media / action_date / fb_expo_id / content_title / beike_id / agent_ucid 同名 |

**一级分类 `item_type`（2026-10-14）**：先取 `$.show_card_type`；空值（`NULL` / `''` / `-911` / `null`）再回退：

| evt | 回退 key |
|-----|----------|
| 93750 / 93751 | `$.fb_item_type` |
| 其他（含 80326 / 80327） | `$.item_type` |

这三套 key 不是同一套枚举（2026-10-13 底表探查）：

| key | 在搜索 80326 上 | 枚举 |
|-----|-----------------|------|
| `$.show_card_type` | 约 1.5% 有值 | 推荐现行一级：经纪人视频、主理人内容-视频、行情数据、二手日照等 |
| `$.fb_item_type` | 约 1.4% 有值 | 推荐旧一级：经纪人视频、`ershou_house`、`xinfang_frame_id`、行情数据等 |
| `$.item_type` | 约 96% 有值 | 搜索结果类型：二手在售房源、二手小区、新房户型、小区点评、二导新户型卡等 |
| `$.card_type` | 约 1.9% 有值 | 二级中文名：实勘视频、房源卡片、二手小区日照分析等 |

93750 / 93751 的 `show_card_type`、`item_type` 基本为空，`fb_item_type` 也几乎为空，旧横卡回退后一级分类仍可能为空；有值的是 `card_type`。

点后推「二导新户型卡」认的是底表 `$.item_type`，不要用本表落表列 `item_type` 去筛（有 `show_card_type` 时该列已被换成推荐一级）。

93750/93751 落表固定 `tab_name=综合`、`module_type=contentCardModule`。

**Tez 解析位置**：过滤用 `get_json_object` 写在 UNION 分支 WHERE；落表字段写在最终 INSERT SELECT。

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「搜索结果页」所有内容卡片相关埋点明细，仅贝壳 App（首页搜索 zonghesousuo/jieguo、二手搜索 ershousousuo/jieguo，用 uicode 区分）。覆盖：综合 tab 内容竖卡/横卡、内容 tab（含历史评测 tab）、0806 前旧横卡 93750/93751、页览 1,3/1,4。tab_name、module_type 及内容参数字段已从 action 预解析落表。一级分类 item_type 先取 show_card_type，空则 93750/93751 用 fb_item_type、其余用 item_type。content_id 按 evt_id 统一两套 action key。

## 加工逻辑

同内容详情页：先 `uicode`+`evt_id` 收窄 → `UNION ALL` 按场景分流。模板见 [templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md)。

## 下游取数

| 场景 | 模板 |
|------|------|
| 内容横卡 expo/click UV·PV·UCTR·PCTR | [templates/search_content_card_ctr.md](../templates/search_content_card_ctr.md) |

横卡 PV 硬规则：`fb_expo_id × duid` 去重，不是 `count(1)`。

只要首页搜索时加 `lower(uicode) = 'zonghesousuo/jieguo'`。2026-10-14 起新分区含二手搜索；现有周报、横卡 CTR、分发 SQL 若未加这层过滤，回刷后「搜索」会变成两个页面之和。

## 验数清单（落表后）

1. **范围**：`evt_id` 仅 80326/80327/93750/93751/1,3/1,4；`uicode IN (zonghesousuo/jieguo, ershousousuo/jieguo)`；`site=beike` `dp=app`。未回刷的历史分区仍只有首页搜索
2. **口径组合**：`tab_name × module_type × evt_id` 只出现预期组合（综合+contentFeed/contentCardModule；内容/评测+contentFeed；页览 tab/module 空）
3. **对账**：按 evt_id 与底表同条件 count，中间表 PV 应对齐
4. **解析质量**：80326/80327 与 93750/93751 的 `content_id`/`item_type` 填充率；抽查明细核对 action key 映射
5. **版本节点**：0709 评测→内容；0806 横卡 93750→80326+contentCardModule
