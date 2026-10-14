# 搜索结果页内容流量表

| 项 | 值 |
|----|----|
| 中文名 | 搜索结果页内容流量表 |
| 英文名 | `rpt.rpt_content_search_result_flow_di` |
| 工厂表单 | 库选 `rpt` 后只填 `content_search_result_flow_di` |
| 粒度 | 事件明细（不聚合），按日分区 `pt` |
| 范围 | 仅贝壳 App（`site=beike`，`dp=app`） |

## 表描述（数据工厂可直接贴）

底层曝光/点击流量表太大，本表从中捞出「搜索结果页」所有**内容卡片**相关埋点明细，仅贝壳 App（首页搜索 `zonghesousuo/jieguo`、二手搜索 `ershousousuo/jieguo`，用 `uicode` 区分）。

一级分类 `item_type`：先取 `$.show_card_type`，空（`NULL` / `''` / `-911` / `null`）再回退——93750/93751 用 `$.fb_item_type`，其余用 `$.item_type`。

覆盖范围：
- **综合 tab**：底部内容竖卡（contentFeed）、横卡（contentCardModule，0806 后迁入 80326/80327）
- **内容 tab**：全部内容竖卡（0709 后「评测」tab 改名为「内容」，历史仍含评测 tab）
- **旧横卡**：0806 前横卡埋点 93750/93751
- **页览**：1,3 / 1,4

`tab_name`、`module_type` 及内容参数字段（content_id、content_tag 等）已从 action 预解析落表，下游可直接使用。80326/80327 与 93750/93751 两套埋点参数名不同，ETL 已按 evt_id 统一。

## 内容卡片口径

| 场景 | tab_name | module_type | 曝光 | 点击 | 说明 |
|------|----------|-------------|------|------|------|
| 综合-底部竖卡 | 综合 | contentFeed | 80326 | 80327 | |
| 综合-横卡 | 综合 | contentCardModule | 80326 | 80327 | 0806+ 更新 app |
| 内容 tab | 内容 / 评测 | contentFeed | 80326 | 80327 | 0709+ 评测改名为内容；历史保留评测 |
| 旧横卡 | 综合 | contentCardModule | 93750 | 93751 | 0806 前；落表时固定赋值 |
| 页览 | — | — | — | 1,3 / 1,4 | 行为表 |

## action 参数映射

一级分类 `item_type` 不按竖卡/横卡拆：先 `$.show_card_type`，空再按 evt 回退（见上）。`content_id` 按 evt_id 区分。

| 表字段 | 80326 / 80327 | 93750 / 93751 |
|--------|---------------|---------------|
| content_id | `$.fb_item_id` | `$.content_id` |
| 其余 | card_type / share_media / action_date / fb_expo_id / content_title / beike_id / agent_ucid 同名 |

`content_id` 区分逻辑：**只看 evt_id**，不看 module_type。

## 底表

- 点击/页览：`rpt.rpt_log_bi_user_behivor_detail_flow_di`
- 元素曝光：`rpt.rpt_comm_log_beike_exp_detail_di`（`site` 写死 `'beike'`，`is_dau` 置空）

## 相关文件

- ETL SQL：`search_result_flow.sql`
