# 内容详情页每日流量（Locked）

> 从中间表 `rpt.rpt_content_detail_flow_di` 聚合，不扫底表。
> 项目 SQL：`内容生态指标体系/content_detail_daily_traffic.sql`

## 输出

`active_date` / `page_name` / `pv` / `uv`（`duid` 去重）+ `整体` 行

## 过滤

- `pt = '${-1d_pt}'`
- 城市：`city_code = 110000`（北京，按需替换）
- `duid is not null and duid not in ('-911','null')`

## 页面曝光 evt_id（Locked）

| page_name | uicode | evt_id |
|-----------|--------|--------|
| 视频详情页 | community/shipindetail | 57827 |
| 图文详情页 | new_kandian_article | 83538 |
| 行情数据 | hangqing_content_app | 1,3 |
| 新房日照 | csxx_light | 1,3 |
| 新房航拍 | csxx_3ddetailpage | 1,3 |
| 二手日照 | lightshadow | 1,3 |
| 二手航拍 | overall | 1,3 |
| 小区漫游 | panorama1 | 1,3 |

```sql
AND (
      (lower(uicode) = 'community/shipindetail' AND evt_id = '57827')
   OR (lower(uicode) = 'new_kandian_article' AND evt_id = '83538')
   OR (
          lower(uicode) IN (
              'hangqing_content_app'
              ,'csxx_light'
              ,'csxx_3ddetailpage'
              ,'lightshadow'
              ,'overall'
              ,'panorama1'
          )
      AND evt_id = '1,3'
   )
)
```

## page_name CASE

```sql
CASE
     WHEN lower(uicode) = 'community/shipindetail' THEN '视频详情页'
     WHEN lower(uicode) = 'new_kandian_article' THEN '图文详情页'
     WHEN lower(uicode) = 'hangqing_content_app' THEN '行情数据'
     WHEN lower(uicode) = 'csxx_light' THEN '新房日照'
     WHEN lower(uicode) = 'csxx_3ddetailpage' THEN '新房航拍'
     WHEN lower(uicode) = 'lightshadow' THEN '二手日照'
     WHEN lower(uicode) = 'overall' THEN '二手航拍'
     WHEN lower(uicode) = 'panorama1' THEN '小区漫游'
 END
```
