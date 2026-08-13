# rpt.rpt_content_resblock_detail_flow_di

> 小区详情页内容流量中间表。从底层曝光/点击表捞出小区详情头部+底部推荐内容埋点，仅贝壳 App。
> as of 2026-08-13, source: 内容生态指标体系/content_resblock_detail_flow.sql + 82883 card_type 枚举确认

| 元信息 | 值 |
|--------|----|
| 中文名 | 小区详情页内容流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app` |
| 场景 | `resblock_detail_recom` |
| uicode | `communitydetailv2` |
| 工厂表单 | 库选 `rpt` 后只填 `content_resblock_detail_flow_di` |
| 项目 SQL | `内容生态指标体系/content_resblock_detail_flow.sql` |
| 枚举探查 | `内容生态指标体系/resblock_detail_source_card_enum.sql` |

## 用途

- 小区详情页内容卡片曝光/点击 UV、PV、UCTR
- 下游内容生态分发（`resblock_detail_recom`）**优先扫本表**

## 底表

| 类型 | evt_id | 表 |
|------|--------|-----|
| 头部点击 | `28738` | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 底部点击 | `82884` | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 头部曝光 | `28737` | `rpt.rpt_comm_log_beike_exp_detail_di`（`site` 写 `'beike'`，`is_dau` 置空） |
| 底部曝光 | `82883` | `rpt.rpt_comm_log_beike_exp_detail_di`（同上） |

## 埋点口径（2026-08-13 confirmed）

| 模块 | 曝光 | 点击 | action 过滤 |
|------|------|------|-------------|
| 头部推荐 | `28737` | `28738` | `$.source_type` ∈ 视频 / 街访 / 解读 / 探房 |
| 底部推荐 | `82883` | `82884` | **剔除** `$.card_type` ∈ `xinfang_project_name` / `ershou_house` / `resblock` / `resblock_rankinglist` |

底部保留示例（2026-08-13 枚举）：`resblock_video` / `bizcircle_video` / `district_hangqing` / `bizcircle_hangqing` / `resblock_comment` 等。

## action 预解析字段

| 表字段 | 含义 | action key |
|--------|------|------------|
| `source_type` | 头部推荐内容类型 | `$.source_type` |
| `card_type` | 底部推荐内容类型 | `$.card_type` |

头部事件通常有 `source_type`；底部有 `card_type`；缺省列为 null。

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「小区详情页」内容相关埋点明细，仅贝壳 App（uicode=communitydetailv2）。覆盖头部+底部推荐：曝光 28737/82883、点击 28738/82884；28737/28738 限 source_type∈视频/街访/解读/探房；82883/82884 取 card_type 全量并剔除 xinfang_project_name/ershou_house/resblock/resblock_rankinglist。事件明细不聚合，日增。

## 加工逻辑

先 `uicode`+`evt` 收窄 → 按头部白名单 / 底部剔除规则 `UNION ALL` 分流。模板见 [templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md)。
