# rpt.rpt_content_search_result_flow_di

> 搜索结果页内容卡片流量中间表。
> as of 2026-08-05, source: 内容生态指标体系/search_result_flow.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 搜索结果页内容流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app` |
| uicode | `zonghesousuo/jieguo` |
| 工厂表单 | 库选 `rpt` 后只填 `content_search_result_flow_di` |
| 项目 SQL | `内容生态指标体系/search_result_flow.sql` |

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
| `item_type` | `$.item_type` | `$.fb_item_type` |
| `content_id` | `$.fb_item_id` | `$.content_id` |
| 其余 | card_type / share_media / action_date / fb_expo_id / content_title / beike_id / agent_ucid 同名 |

93750/93751 落表固定 `tab_name=综合`、`module_type=contentCardModule`。

**Tez 解析位置**：过滤用 `get_json_object` 写在 UNION 分支 WHERE；落表字段写在最终 INSERT SELECT。

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「搜索结果页」所有内容卡片相关埋点明细，仅贝壳 App（页面 zonghesousuo/jieguo）。覆盖：综合 tab 内容竖卡/横卡、内容 tab（含历史评测 tab）、0806 前旧横卡 93750/93751、页览 1,3/1,4。tab_name、module_type 及内容参数字段已从 action 预解析落表；80326/80327 与 93750/93751 两套埋点参数名不同，ETL 已按 evt_id 统一。

## 加工逻辑

同内容详情页：先 `uicode`+`evt_id` 收窄 → `UNION ALL` 按场景分流。模板见 [templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md)。

## 下游取数

| 场景 | 模板 |
|------|------|
| 内容横卡 expo/click UV·PV·UCTR·PCTR | [templates/search_content_card_ctr.md](../templates/search_content_card_ctr.md) |

横卡 PV 硬规则：`fb_expo_id × duid` 去重，不是 `count(1)`。

## 验数清单（落表后）

1. **范围**：`evt_id` 仅 80326/80327/93750/93751/1,3/1,4；`uicode=zonghesousuo/jieguo`；`site=beike` `dp=app`
2. **口径组合**：`tab_name × module_type × evt_id` 只出现预期组合（综合+contentFeed/contentCardModule；内容/评测+contentFeed；页览 tab/module 空）
3. **对账**：按 evt_id 与底表同条件 count，中间表 PV 应对齐
4. **解析质量**：80326/80327 与 93750/93751 的 `content_id`/`item_type` 填充率；抽查明细核对 action key 映射
5. **版本节点**：0709 评测→内容；0806 横卡 93750→80326+contentCardModule
