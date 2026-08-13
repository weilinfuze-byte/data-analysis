# rpt.rpt_content_ershou_detail_flow_di

> 二手房源详情页内容流量中间表。从底层曝光/点击表捞出 `ershou/detail` 内容相关埋点，仅贝壳 App。
> as of 2026-08-13, source: 内容生态指标体系/content_ershou_detail_flow.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 二手房源详情页内容流量表 |
| 粒度 | 事件明细，按日分区 `pt` |
| 范围 | `site=beike`，`dp=app` |
| uicode | `ershou/detail` |
| 场景 | `ershou_detail_recom` |
| 工厂表单 | 库选 `rpt` 后只填 `content_ershou_detail_flow_di` |
| 项目 SQL | `内容生态指标体系/content_ershou_detail_flow.sql` |

## 用途

- 二手详情页内容卡片曝光/点击 UV、PV、UCTR
- 按 `source_type` / `from_val` / `card_type` / `housedel_id` 下钻
- 下游 `ershou_detail_recom` 分发**优先扫本表**，避免直接扫底表

## 底表

| 类型 | evt_id | 表 |
|------|--------|-----|
| 头部/底部点击 | `80580`, `87222` | `rpt.rpt_log_bi_user_behivor_detail_flow_di` |
| 头部/底部曝光 | `80579`, `87223` | `rpt.rpt_comm_log_beike_exp_detail_di`（`site` 写 `'beike'`，`is_dau` 置空） |

## 加工逻辑（Locked）

1. 每张底表先按 `uicode=ershou/detail` + 内容 evt 收窄 → `click_raw` / `expo_raw`
2. 再按规则 `UNION ALL` 分流（禁止嵌套 `OR`）
3. 取公共字段落明细，不聚合
4. 从 `action` 预解析 `source_type` / `from_val` / `card_type` / `housedel_id`

## 埋点口径

| 模块 | 曝光 | 点击 | action 过滤 |
|------|------|------|-------------|
| 头部推荐 | `80579` | `80580` | `$.source_type` ∈ 探房 / 业主vlog / 房源视频 / 业主讲房 / 视频 |
| 底部推荐 | `87223` | `87222` | **剔除** `from×card_type`：二手×房源卡片、新房×新房楼盘、新房×土拍 |

底部**不要**再用 `card_type` 白名单（视频类/业主自荐/…会漏小区点评、行情卡等）。

底部 `from` 取值：`内容` / `二手` / `新房`。枚举探查：`内容生态指标体系/ershou_detail_bottom_from_card_enum.sql`。

## action 预解析字段

| 表字段 | 含义 | action key |
|--------|------|------------|
| `source_type` | 头部推荐内容类型 | `$.source_type` |
| `from_val` | 底部推荐来源 | `$.from`（列名避开 SQL 关键字 `from`） |
| `card_type` | 底部推荐内容类型 | `$.card_type` |
| `housedel_id` | 房源 id | `$.housedel_id` |

头部通常有 `source_type`；底部有 `from` / `card_type`；缺省列为 null。

## 表描述（数据工厂）

> 底层曝光/点击流量表太大，本表从中捞出「二手房源详情页」内容相关埋点明细，仅贝壳 App（uicode=ershou/detail）。覆盖头部+底部推荐：曝光 80579/87223、点击 80580/87222；其中 80579/80580 限 source_type∈探房/业主vlog/房源视频/业主讲房/视频；87223/87222 剔 from×card_type ∈（二手×房源卡片、新房×新房楼盘、新房×土拍）。事件明细不聚合，日增。

## 相关

模板：[templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md) §五  
埋点：[events/beike_evt_id.md](../events/beike_evt_id.md)
