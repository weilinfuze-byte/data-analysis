# 内容生态指标

> 硬规则：以下人数 / UV 定义 verbatim 使用。
> 中间表见 [templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md)。
> 小区详情页分发优先扫 `rpt.rpt_content_resblock_detail_flow_di`。

## 去重键（2026-08 confirmed）

**所有人数 / UV 指标统一用 `duid` 去重。** 原先用 `ucid` 去重的历史口径已废弃。

| 字段 | 含义 | 说明 |
|------|------|------|
| `duid` | 设备 ID | 未登录也有；人数 / UV 去重键 |
| `ucid` | 账号 ID | 只有登录之后才有；不用于内容生态 UV |

关系：一个设备可以登录多个账号；一个账号可以在多个设备登录。

异常值过滤（JOIN / 去重前）：

```sql
and duid is not null
and duid not in ('-911','null')
```

## 分发

| 指标 | 公式 |
|------|------|
| 卡片曝光人数 UV | `COUNT(DISTINCT duid)`，卡片曝光事件；**首页feed = 40400 ∩ 54872** |
| 卡片点击人数 UV | `COUNT(DISTINCT duid)`，卡片点击事件 |
| 卡片点击率 UCTR | 点击 UV / 曝光 UV（均 duid 去重） |
| 卡片 PCTR | 点击 PV / 曝光 PV |
| 人均曝光卡片个数 | 曝光 PV / 曝光 UV |
| 人均点击卡片个数 | 点击 PV / 点击 UV |
| 首页feed物料 PCTR/UCTR | 按 `item_type`（一级）× `card_type`（二级）；曝光分母为滑动有效曝光；模板 [homepage_feed_material_ctr.md](../templates/homepage_feed_material_ctr.md) |
| 卡片曝光/点击 PV（内容feed / 搜索内容卡） | `COUNT(DISTINCT concat(nvl(fb_expo_id,''),'#',duid))` —— **fb_expo_id × duid 去重** |
| 卡片曝光/点击 PV（首页feed） | `COUNT(1)`（有效曝光后） |
| 卡片 PCTR（搜索横卡） | 点击 PV / 曝光 PV（同上 PV 口径） |

### 三场景整体（2026-08 confirmed）

覆盖：内容feed + 首页feed内容卡 + 搜索结果页内容卡（竖卡+横卡）。

| 项 | 口径 |
|----|------|
| 整体曝光/点击 UV | 三场景明细 `UNION ALL` 后 `COUNT(DISTINCT duid)`，**禁止分场景 UV 相加** |
| 整体曝光/点击 PV | 分场景 PV **之和** |
| 周报取数模板 | [templates/content_weekly_scene_metrics.md](../templates/content_weekly_scene_metrics.md) |

### 搜索结果页内容横卡（2026-08 confirmed）

- 中间表：`rpt.rpt_content_search_result_flow_di`
- 横卡 = 综合 tab + `contentCardModule`（80326/80327）∪ 旧埋点 93750/93751
- 模板：[templates/search_content_card_ctr.md](../templates/search_content_card_ctr.md)
- 周报「搜索结果页内容卡片」= **竖卡+横卡**（`contentFeed` + `contentCardModule` + 93750/93751），不是仅横卡

### 二手详情页内容（2026-08-13 confirmed）

- 中间表：`rpt.rpt_content_ershou_detail_flow_di`
- 头部：`source_type` 白名单（探房 / 业主vlog / 房源视频 / 业主讲房 / 视频）
- 底部：**剔除** `from×card_type`（二手×房源卡片、新房×新房楼盘、新房×土拍），不要用 `card_type` 白名单
- 模板：[templates/content_ecology_intermediate_flow.md](../templates/content_ecology_intermediate_flow.md) §五

## 消费

| 指标 | 公式 |
|------|------|
| 内容消费人数 UV | `COUNT(DISTINCT duid)`，内容详情页**页面曝光**（中间表 `rpt.rpt_content_detail_flow_di`） |
| 内容消费次数 PV | `COUNT(1)`，同上页面曝光 |
| 内容消费用户渗透率 | 内容消费 UV / 卡片曝光 UV |
| 内容有效消费人数 UV | `COUNT(DISTINCT duid)`，有效消费判定见业务规则 |
| 内容有效消费用户渗透率 | 有效消费 UV / 内容消费 UV |

### 内容消费页面曝光 evt（Locked）

与 [content_detail_daily_traffic](../templates/content_detail_daily_traffic.md) 一致，**不能只算图文**：

| 页面 | uicode | evt_id |
|------|--------|--------|
| 视频详情页 | community/shipindetail | 57827 |
| 图文详情页 | new_kandian_article | 83538 |
| 行情 / 日照 / 航拍 / 漫游 | hangqing_content_app 等 | `1,3` |

### 整体 vs 分场景消费（2026-08 confirmed）

| 粒度 | source 过滤 |
|------|-------------|
| **整体** | **不限** `action.source` |
| **分场景** | 必须按 source 归因：`kandian`/`kanidian`→内容feed；`homepage_feed`→首页feed；`search`→搜索结果页 |

## 周报展示（2026-08 confirmed）

- 默认城市：北京 `city_code=110000`
- 周窗口：周五–周四（例 M8W1 = 07.31–08.06）
- 周度单元格 = **日均**（UV/PV 为日算术平均；UCTR/PCTR 为日率算术平均）
- Excel 纵轴两段：**用户层面**（UV/UCTR）→ **用户×物料层面**（PV/PCTR/人均）；分场景每场景一 sheet
- SQL / 表样板见 [content_weekly_scene_metrics.md](../templates/content_weekly_scene_metrics.md)

## 互动

| 指标 | 公式 |
|------|------|
| 完读/完播人数 UV | `COUNT(DISTINCT duid)`，完读或完播 ≥90% |
| 互动人数 UV | `COUNT(DISTINCT duid)`，点赞/评论/分享等 |

## 留存 / 复访

- 去重键：`duid`
- 基准 cohort 与回访均按 `duid` 关联
- 写法同 [retention.md](retention.md)，将用户键换为 `duid`

## 注意

- 同一份报告内不可混用 `duid` 与 `ucid`
- 中间表同时保留 `duid`、`ucid` 字段；聚合 UV 时只用 `duid`
- 历史 SQL / 看板若仍写 `ucid` 去重，需按新口径改写
