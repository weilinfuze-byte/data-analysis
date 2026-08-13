# 内容卡片周报 · 整体 / 分场景日指标（Locked）

> as of 2026-08-13
> 项目 SQL：
> - 整体：`内容生态指标体系/weekly_feed_scene_metrics.sql`
> - 分场景：`内容生态指标体系/weekly_feed_by_scene_metrics.sql`
> 周报表：`内容生态指标体系/内容生态_用户层面_周报_分场景.xlsx`

## 触发

周报 / 看板取数：内容feed、首页feed内容卡、搜索结果页内容卡的曝光/点击/消费，按日输出后算周度日均。

## 默认范围

| 项 | 值 |
|----|-----|
| 站点/端 | beike / app |
| 城市 | `city_code = 110000`（北京） |
| 窗口 | `pt between '${-7d_pt}' and '${-1d_pt}'`（按需扩窗） |
| UV 去重键 | **duid** |

## 场景口径

| scene | 中间表 | 曝光 | 点击 | PV |
|-------|--------|------|------|-----|
| `content_feed` | `rpt.rpt_content_feed_flow_di` | 94408 / 68193 | 94409 / 68194 | `fb_expo_id × duid` |
| `homepage_feed` | `rpt.rpt_homepage_feed_flow_di` | **40400 ∩ 54872** + 内容 `card_type` 白名单 | 40397 + 同白名单 | `count(1)` |
| `search_result` | `rpt.rpt_content_search_result_flow_di` | 80326（`contentFeed`/`contentCardModule`）∪ 93750 | 80327 同 module ∪ 93751 | `fb_expo_id × duid` |

首页内容 `card_type` 白名单（与 `workflow.sql` 一致）：

```
预算找房, 特色找房, 通勤找房, 低价找房,
买房故事, 商圈测评, 小区梯度, 小区测评,
二手房源视频, 业主vlog, 业主自荐,
小区周边单一模块_4205/4272/4267/4202/4269/4265,
土拍视频, 楼市新政,
装修案例, 装修图片, 装修户型解读, 装修小区案例集,
综合feed装修案例, 家装案例专辑,
户改图文, 户改视频
```

## 整体 vs 分场景

| 维度 | 整体 (`overall`) | 分场景 |
|------|------------------|--------|
| 曝光/点击 UV | 三场景 `UNION ALL` 后 `count(DISTINCT duid)`（**非分场景相加**） | 各场景各自 `count(DISTINCT duid)` |
| 曝光/点击 PV | 分场景 PV **之和** | 各场景各自口径 |
| 内容消费 | **不限 source**；详情页全量页面曝光 | 按 `action.source` 归因 |

### 内容消费页面曝光（Locked，同 content_detail_daily_traffic）

```sql
AND (
     (lower(uicode) = 'community/shipindetail' AND evt_id = '57827')
  OR (lower(uicode) = 'new_kandian_article' AND evt_id = '83538')
  OR (
         lower(uicode) IN (
             'hangqing_content_app','csxx_light','csxx_3ddetailpage'
             ,'lightshadow','overall','panorama1'
         )
     AND evt_id = '1,3'
  )
)
```

- `consume_uv` = `count(DISTINCT duid)`
- `consume_pv` = `count(1)`
- 分场景 source：`kandian`/`kanidian` → content_feed；`homepage_feed` → homepage_feed；`search` → search_result

## 输出字段（按日）

`active_date` [/ `scene`] / `expo_uv` / `click_uv` / `uctr` / `consume_uv` / `consume_pv` / `expo_pv` / `click_pv` / `pctr` / `avg_expo_per_user` / `avg_click_per_user`

## 周报 Excel 展示（Locked）

- 横轴：周度，周五–周四；如 M8W1 = 07.31–08.06，数值 = **周内日均**（UCTR/PCTR = 日率算术平均）
- 左上角：`北京市`
- 纵轴两段：
  1. **用户层面** · 分发：曝光 UV / 点击 UV / UCTR；消费：消费 UV
  2. **用户×物料层面** · 分发：曝光 PV / 点击 PV / PCTR / 人均曝光 / 人均点击；消费：消费 PV
- 分场景：每个场景一个 sheet（内容feed / 首页feed / 搜索结果页）

## 注意

- 搜索「内容卡片」= 竖卡+横卡（`contentFeed` + `contentCardModule` + 旧 93750/93751），不是仅横卡模板
- 禁止整体 UV 用三场景 UV 相加
- 中间表已限定 beike/app；下游必带 `pt` 与异常 `duid` 过滤
