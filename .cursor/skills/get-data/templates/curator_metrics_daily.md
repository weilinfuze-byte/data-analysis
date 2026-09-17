# 主理人内容 · 生产 / 消费日指标（Locked）

> as of 2026-09-11 confirmed  
> 项目 SQL：`主理人视频详情页曝光/curator_metrics.sql`  
> 与分发日指标不同：本模板偏**生产盘点 + 详情页消费**；分发见 [curator_distribution_daily.md](curator_distribution_daily.md)。

## 触发

周表 / 周报要「投稿主理人、内容生产量、内容浏览人数/次数」时用本口径。

## 默认范围

| 项 | 值 |
|----|-----|
| 城市 | 北京：供给 `cast(city_id AS string) = '110000'`（本模板约定）；流量 `city_code = 110000` |
| 窗口 | 默认近 7 天：`pt` / `active_date` = `${-7d}`～`${-1d}` |
| 主理人池 | `array_contains(content_tag, 'curator_content')` + **`status = 4`**（生产盘点；≠ 分发日指标的不限 status） |
| 首发日 | `min(to_date(publish_time))`；剔 `publish_time` 空 / `1970%` |

## 指标口径

| 输出列 | 口径 |
|--------|------|
| 当日生产量 | 当日 `first_publish_date` 的 `content_id` 去重 |
| 累计内容生产量 | 截至 `stat_date` 累计上线 `content_id` 去重 |
| 累计投稿主理人数 | 截至 `stat_date` 累计投稿 `beikehao_id` 去重（勿再叫「活跃主理人」） |
| 内容浏览人数 UV | 当日详情页页面曝光 `duid` 去重 |
| 内容浏览次数 PV | 当日详情页页面曝光 `count(1)` |
| 浏览次数/人数 | `consume_pv / consume_uv` |

## 消费页面（Locked）

**视频 + 图文**，不能只算视频：

| 页面 | uicode | evt_id |
|------|--------|--------|
| 视频详情 | `community/shipindetail` | `57827` |
| 图文详情 | `new_kandian_article` | `83538` |

- 底表优先：`rpt.rpt_content_detail_flow_di`
- 内容键：`coalesce($.content_id, $.article_id, $.id)` = 供给 `content_id`
- 只统计 **已上线** 主理人内容：`active_date >= first_publish_date`

## Excel 周汇总

| 列 | 聚合 |
|----|------|
| 累计投稿主理人数 / 累计内容生产量 | 取当周 `stat_date` **最后一天** |
| 当日生产量 / 浏览人数 / 浏览次数 | 当周 **AVERAGE（日均）** |
| 人均浏览 | `日均浏览次数 / 日均浏览人数`（或对日级 `consume_pv/consume_uv` 再 AVERAGE） |

## 与分发模板差异

| 项 | 本模板（生产/消费） | 分发日指标 |
|----|---------------------|------------|
| status | `= 4` | **不限** |
| 指标 | 生产量 + 详情页浏览 | 五场景卡片曝光/点击 |
| 详情页曝光 | **计入**（57827/83538） | 暂不含 |
