# rpt.rpt_log_bi_user_uicode_flow_di

> 页面级 DAU/MAU/停留。历史 SQL 引用 **41** 次。月报、渗透分析核心表。

## 用途

- MAU（按月 `count(distinct duid)`）
- 各业务线流量渗透
- 页面停留时长
- `is_dau = 1` 过滤日活用户

## 必带过滤

```sql
WHERE pt BETWEEN '{start_pt}' AND '{end_pt}'
  AND is_dau = 1
  AND dp IN ('app', 'xcx')
```

## 常用字段

| 字段 | 说明 |
|------|------|
| stat_date | 统计日期 |
| duid | 设备 ID |
| uicode | 页面标识 |
| business_name | 业务线（二手、新房、家装…） |
| site | beike / lianjia |
| city_code, city_name | 城市 |
| is_dau | 是否 DAU（=1 过滤） |

## MAU 聚合模式

```sql
SELECT substr(stat_date, 1, 7) AS active_mm,
       COUNT(DISTINCT duid) AS MAU
FROM rpt.rpt_log_bi_user_uicode_flow_di
WHERE pt BETWEEN '20241201000000' AND '20241231000000'
  AND is_dau = 1
GROUP BY 1
```

## 排除页面

月报中常排除搜索引导页：

```sql
AND uicode NOT IN ('matrix/bigcsearchguide', 'matrix/searchguide', 'search_guide')
```

## 城市 JOIN

常与 `dim.dim_beautyhome_city_expand` 关联扩展城市列表。
