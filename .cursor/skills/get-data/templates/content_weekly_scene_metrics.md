# 内容卡片周报 · 整体 / 分场景日指标（Locked）

> as of 2026-08-13
> 项目 SQL：`内容生态指标体系/weekly_feed_scene_metrics.sql`（**仅日明细**）  
> Excel：`内容生态指标体系/generate_weekly_report_excel.py`（**周度日均**）  
> 周报表：`内容生态指标体系/内容生态_用户层面_周报_分场景.xlsx`

## 触发

周报 / 看板取数：内容feed、首页feed内容卡、搜索结果页内容卡的曝光/点击/消费，按日输出后算周度日均。

## 默认范围

| 项 | 值 |
|----|-----|
| 站点/端 | beike / app |
| 城市 | `city_code = 110000`（北京） |
| 窗口 | `pt between '${-7d_pt}' and '${-1d_pt}'`（SQL 仅出日明细；周均见 Excel 脚本） |
| UV 去重键 | **duid** |

## 场景口径

| scene | 中间表 | 曝光 | 点击 | PV |
|-------|--------|------|------|-----|
| `content_feed` | `rpt.rpt_content_feed_flow_di` | 94408 / 68193 | 94409 / 68194 | `fb_expo_id × duid` |
| `homepage_feed` | `rpt.rpt_homepage_feed_flow_di` | **40400 ∩ 54872** + `tab_id = '推荐'` + **card_type 剔除法** | 40397 + 同 tab / 剔除法 | **`fb_expo_id × duid`**（推荐场景；勿再用 `count(1)`） |
| `search_result` | `rpt.rpt_content_search_result_flow_di` | 80326（`contentFeed`/`contentCardModule`）∪ 93750 | 80327 同 module ∪ 93751 | `fb_expo_id × duid` |

首页 feed 内容卡 **`card_type` 剔除法**（禁止白名单）：`card_type IS NOT NULL` 且不在 35 类非内容黑名单；名单外新类型算内容。完整名单见 [docs/homepage_feed_content_card_filter.md](../docs/homepage_feed_content_card_filter.md)。

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

## 输出与周报流程（Locked）

| 步骤 | 产物 | 说明 |
|------|------|------|
| 1. SQL | `weekly_feed_scene_metrics.sql` | **仅日粒度** `active_date × scene`；窗口默认近 7 天（`pt between '${-7d_pt}' and '${-1d_pt}'`） |
| 2. 导出 | 工厂下载 `.xlsx` | 列：`active_date, scene, expo_uv, …` |
| 3. Excel | `generate_weekly_report_excel.py` | 合并日明细 → 按**周五–周四**算**周度日均** → 写入 `内容生态_用户层面_周报_整体.xlsx` / `分场景.xlsx` |

```bash
python3 内容生态指标体系/generate_weekly_report_excel.py /path/to/export.xlsx
```

- **周度日均**（在 Excel 脚本内计算，SQL 不做）：
  - UV / PV 等计数：周内各日**算术平均**
  - UCTR / PCTR / 人均曝光 / 人均点击：各日率**算术平均**
- 横轴：最近 5 个完整周（周五–周四），表头为 `MM.DD-MM.DD`

## 注意

- 搜索「内容卡片」= 竖卡+横卡（`contentFeed` + `contentCardModule` + 旧 93750/93751），不是仅横卡模板
- 禁止整体 UV 用三场景 UV 相加
- 中间表已限定 beike/app；下游必带 `pt` 与异常 `duid` 过滤
