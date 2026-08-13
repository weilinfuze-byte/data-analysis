# 首页feed · 一级/二级物料 PCTR & UCTR（Locked）

> as of 2026-08-05。完整 SQL：`内容生态指标体系/homepage_feed_material_ctr.sql`
> 中间表：[tables/homepage_feed_flow_di.md](../tables/homepage_feed_flow_di.md)

## 口径（硬规则）

| 项 | 定义 |
|----|------|
| 曝光 | `40400 ∩ 54872`（滑动有效曝光）；禁止裸用 40400 |
| 点击 | `evt_id = 40397` |
| 一级物料 | `item_type` |
| 二级物料 | `card_type` |
| 去重键 | **duid**（内容生态 / Feed 漏斗统一） |
| PCTR | 点击 PV / 有效曝光 PV |
| UCTR | 点击 UV / 有效曝光 UV |
| 排序 | `ORDER BY expo_pv DESC` |

物料维度：54872 无卡片级字段 → 先建滑动用户集合，再对 40400 `INNER JOIN` 后按物料聚合。

## CTE 结构（勿改）

```sql
WITH scroll_user AS (
    SELECT active_date, duid
    FROM rpt.rpt_homepage_feed_flow_di t1
    WHERE pt = '${-1d_pt}'
      AND evt_id = '54872'
      AND duid IS NOT NULL
      AND duid NOT IN ('-911', 'null')
    GROUP BY active_date, duid
)
,expo AS (
    SELECT
        t1.active_date
        ,t1.item_type          -- Query2 可去掉 card_type
        ,t1.card_type
        ,COUNT(1) AS expo_pv
        ,COUNT(DISTINCT t1.duid) AS expo_uv
    FROM rpt.rpt_homepage_feed_flow_di t1
    INNER JOIN scroll_user t2
      ON t1.active_date = t2.active_date
     AND t1.duid = t2.duid
    WHERE t1.pt = '${-1d_pt}'
      AND t1.evt_id = '40400'
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('-911', 'null')
    GROUP BY t1.active_date, t1.item_type, t1.card_type
)
,click AS (
    SELECT
        t1.active_date
        ,t1.item_type
        ,t1.card_type
        ,COUNT(1) AS click_pv
        ,COUNT(DISTINCT t1.duid) AS click_uv
    FROM rpt.rpt_homepage_feed_flow_di t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.evt_id = '40397'
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('-911', 'null')
    GROUP BY t1.active_date, t1.item_type, t1.card_type
)
SELECT
    t1.active_date
    ,t1.item_type
    ,t1.card_type
    ,t1.expo_pv
    ,nvl(t2.click_pv, 0) AS click_pv
    ,CASE WHEN t1.expo_pv = 0 THEN 0
          ELSE nvl(t2.click_pv, 0) * 1.0 / t1.expo_pv END AS pctr
    ,t1.expo_uv
    ,nvl(t2.click_uv, 0) AS click_uv
    ,CASE WHEN t1.expo_uv = 0 THEN 0
          ELSE nvl(t2.click_uv, 0) * 1.0 / t1.expo_uv END AS uctr
FROM expo t1
LEFT JOIN click t2
  ON t1.active_date = t2.active_date
 AND nvl(t1.item_type, '') = nvl(t2.item_type, '')
 AND nvl(t1.card_type, '') = nvl(t2.card_type, '')
ORDER BY t1.expo_pv DESC
```

Query2：去掉 `card_type` 分组与 JOIN 条件，仅按 `item_type`。
