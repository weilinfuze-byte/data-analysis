# 主理人内容 · 分发日指标（Locked）

> as of 2026-09-11 confirmed  
> 项目 SQL：  
> - 中间表版 `主理人视频详情页曝光/curator_distribution_daily.sql`（优先 · 仅整体）  
> - 组织切片 `主理人视频详情页曝光/curator_distribution_by_org.sql`（整体 + 大部/大区/区域/门店）  
> - 底表版 `主理人视频详情页曝光/curator_distribution_daily_base.sql`（中间表权限/分区不全时 · 仅整体）

## 触发

给业务方分发主理人内容日指标：卡片曝光/点击 UV·PV、UCTR/PCTR（**暂不含详情页曝光**）。
要按组织看时用 `curator_distribution_by_org.sql`。

## 组织切片（by_org）

| 项 | 口径 |
|----|------|
| JOIN | 内容 `im_ucid` = 员工 `employee_ucid`（**禁止** `admin_ucid`） |
| 输出列 | `城市` / `大部` / `大区` / `区域` / `门店` / `经纪人姓名` |
| 分层 | `GROUPING SETS`：全市 → +大部 → +大区 → +区域 → +门店 → +经纪人；上层未展开维填 `'all'` |
| 字段映射 | 大部=`marketing_name`；大区=`region_name`；区域=`area_name`；门店=`shop_name`；经纪人=`employee_name`；城市固定`北京` |
| 未匹配 | 无 `im_ucid` / 员工未命中 → `未匹配` |

## 默认范围

| 项 | 值 |
|----|-----|
| 站点/端 | beike / app |
| 城市 | 北京：供给表 `cast(city_id AS string) = '110000'`（本模板约定）；流量 `city_code = 110000`（不擅自 cast） |
| 窗口 | 默认昨天 `pt = '${-1d_pt}'`（日维度单行）；近 N 天改 `between` |
| UV | **duid** 去重 |
| 卡片 PV | 有 `fb_expo_id`：`count(DISTINCT concat(fb_expo_id,'#',duid))`；二手/小区无 fb_expo_id 时用 `scene_id#client_time#evt_id#content_id` 兜底（对齐周报 `count(1)`） |
| 场景 | **五场景整体**（内容feed + 首页feed 全 tab + 搜索内容卡 + 二手详情内容卡 + 小区详情内容卡）；不分场景输出 |

## 主理人内容池

```sql
array_contains(t1.content_tag, 'curator_content')
```

**不限 `status`**（含未上线 / 下架等；与生产量盘点常用 `status=4` 不同）。

供给表：`rpt.rpt_feed_content_analyze_table`（平台表）。见 [feed_content_analyze_table.md](../tables/feed_content_analyze_table.md)。

## 指标

| 输出列 | 口径 |
|--------|------|
| 卡片曝光人数 / 次数 | 五场景 UNION 后 expo：`duid` / PV key |
| 卡片点击人数 / 次数 | 同上 click |
| uctr / pctr | 点击 UV÷曝光 UV；点击 PV÷曝光 PV |

> 2026-09-11：**暂不含**详情页曝光；需要时再加回曝光底表 57827/83538。

整体 UV = 五场景 `UNION ALL` 后 `count(DISTINCT duid)`，**禁止**分场景 UV 相加。

## 场景埋点

| scene | 曝光 | 点击 | 备注 |
|-------|------|------|------|
| content_feed | 94408 / 68193 | 94409 / 68194 | uicode：`new_kandian_homepage` / `content/kandian/recommend` |
| homepage_feed | **40400 ∩ 54872** | 40397 | **不限 tab**；54872 仍只做滑动用户集合 |
| search_result | 80326（module∈contentFeed/contentCardModule）∪ 93750 | 80327 同 module ∪ 93751 | 竖卡+横卡 |
| ershou_detail | 80579 / 87223 | 80580 / 87222 | 头部 source_type 白名单；**底部与首页 feed 内容卡同一套剔除法**（`card_type` 非空 + 35 类黑名单 + `item_type`/`fb_item_type` 剔房源楼盘） |
| resblock_detail | 28737 / 82883 | 28738 / 82884 | 中间表已过滤；底表版复刻头部 source_type / 底部 card_type 剔除 |

## content_id action key

| 场景 | key | 中间表 |
|------|-----|--------|
| 内容feed | `$.article_id` | 落表列 `content_id` |
| 首页feed | `$.content_id` | 落表列 `content_id` |
| 搜索 80326/80327 | `$.fb_item_id` | 落表列 `content_id` |
| 搜索旧 93750/93751 | `$.content_id` | 落表列 `content_id` |
| **二手详情 / 小区详情** | **`$.content_id`**（2026-09-11 用户确认） | **未落表**，中间表版仍 `get_json_object(action,'$.content_id')` |

> 详情页曝光（视频 `$.video_id` / 图文 `$.content_id`，曝光底表 57827/83538）**暂不纳入**本模板输出。

已落表字段禁止再 `get_json_object`；未落表字段可从 `action` 解析。先解析成列再 `INNER JOIN` 主理人池，**禁止** `JOIN ON get_json_object(...)`。

## 选用哪份 SQL

| 条件 | 用 |
|------|----|
| 中间表有权限且只要整体 | `curator_distribution_daily.sql` |
| 要整体 + 大部/大区/区域/门店 | `curator_distribution_by_org.sql` |
| 业务方无中间表权限 / 要自洽可跑 | `curator_distribution_daily_base.sql` |

口径对齐，只换数据源。

## 工厂注意

- **禁止**文件头写 `-- ====...` 分隔线（查询侧会报错）；只用普通 `--` 说明。见 [sql-style.md](../docs/sql-style.md) §注释
- 直接查数中文列用反引号 `` AS `卡片曝光人数` ``
