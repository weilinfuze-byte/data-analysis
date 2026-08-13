# 留存 / 复访 SQL 片段

> 口径定义见 [metrics/retention.md](../metrics/retention.md)。只替换日期与 uicode。

```sql
WITH dau AS (
    SELECT DISTINCT active_date, duid, uicode
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di
    WHERE pt BETWEEN '{start_pt}' AND '${-1d_pt}'
      AND evt_id = '1,3'
      AND lower(uicode) IN ({uicode_list})
      AND dp = 'app'
      AND site = 'beike'
)
SELECT
    a.active_date
    ,a.uicode
    ,COUNT(DISTINCT a.duid) AS cohort_uv
    ,COUNT(DISTINCT CASE
         WHEN DATEDIFF(b.active_date, a.active_date) BETWEEN 1 AND 7
         THEN a.duid
     END) AS retain_uv_7d
    ,COUNT(DISTINCT CASE
         WHEN DATEDIFF(b.active_date, a.active_date) BETWEEN 1 AND 7
         THEN concat(a.duid, b.active_date)
     END) AS revisit_days_1_7
FROM (SELECT DISTINCT active_date, duid, uicode FROM dau) a
LEFT JOIN (SELECT DISTINCT active_date, duid, uicode FROM dau) b
  ON a.duid = b.duid AND a.uicode = b.uicode
GROUP BY a.active_date, a.uicode
```
