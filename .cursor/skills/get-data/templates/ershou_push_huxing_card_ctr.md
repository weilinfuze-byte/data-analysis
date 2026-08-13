# 点后推 · 二导新户型卡 CTR（Locked）

> ⚠️ Locked template: execute as-is, only modify marked parameters.
> 走流量底表，**不要**用 `rpt.rpt_content_search_result_flow_di`。
> 项目 SQL：`点后推二导新户型卡/workflow.sql`
> as of 2026-08-10

## 触发

搜「点后推 / 二导新户型卡 / 搜索结果页+二手首页曝光点击率」。

## 口径

| 场景 | 曝光表 evt | 点击表 evt | 额外过滤 |
|------|------------|------------|----------|
| 搜索结果页 | `80326` | `80327` | `lower(uicode)='zonghesousuo/jieguo'` AND `$.item_type='二导新户型卡'` |
| 二手首页 | `93280` | `93287` | 无 uicode / item_type |

- 曝光：`rpt.rpt_comm_log_beike_exp_detail_di`
- 点击：`rpt.rpt_log_bi_user_behivor_detail_flow_di`
- UV：`COUNT(DISTINCT duid)`；PV：`COUNT(1)`
- UCTR = click_uv / expo_uv；PCTR = click_pv / expo_pv
- 曝光侧 LEFT JOIN 点击侧

## 可替换参数

| 标记 | 默认 | 说明 |
|------|------|------|
| `{pt}` | `'${-1d_pt}'` | 昨天；窗口改 `BETWEEN '${-7d_pt}' AND '${-1d_pt}'` |
| `{city}` | `110000` | 北京；全国则删掉该行 |

## SQL

```sql
WITH search_expo_agg AS (
    SELECT
        t1.active_date                         AS active_date
        ,count(DISTINCT t1.duid)               AS expo_uv
        ,count(1)                              AS expo_pv
    FROM rpt.rpt_comm_log_beike_exp_detail_di t1
    WHERE t1.pt = {pt}
      AND t1.dp = 'app'
      AND t1.city_code = {city}
      AND lower(t1.uicode) = 'zonghesousuo/jieguo'
      AND t1.evt_id = '80326'
      AND get_json_object(t1.action, '$.item_type') = '二导新户型卡'
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('-911', 'null')
    GROUP BY
        t1.active_date
)
,search_click_agg AS (
    SELECT
        t1.active_date                         AS active_date
        ,count(DISTINCT t1.duid)               AS click_uv
        ,count(1)                              AS click_pv
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
    WHERE t1.pt = {pt}
      AND t1.site = 'beike'
      AND t1.dp = 'app'
      AND t1.city_code = {city}
      AND lower(t1.uicode) = 'zonghesousuo/jieguo'
      AND t1.evt_id = '80327'
      AND get_json_object(t1.action, '$.item_type') = '二导新户型卡'
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('-911', 'null')
    GROUP BY
        t1.active_date
)
,ershou_expo_agg AS (
    SELECT
        t1.active_date                         AS active_date
        ,count(DISTINCT t1.duid)               AS expo_uv
        ,count(1)                              AS expo_pv
    FROM rpt.rpt_comm_log_beike_exp_detail_di t1
    WHERE t1.pt = {pt}
      AND t1.dp = 'app'
      AND t1.city_code = {city}
      AND t1.evt_id = '93280'
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('-911', 'null')
    GROUP BY
        t1.active_date
)
,ershou_click_agg AS (
    SELECT
        t1.active_date                         AS active_date
        ,count(DISTINCT t1.duid)               AS click_uv
        ,count(1)                              AS click_pv
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
    WHERE t1.pt = {pt}
      AND t1.site = 'beike'
      AND t1.dp = 'app'
      AND t1.city_code = {city}
      AND t1.evt_id = '93287'
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('-911', 'null')
    GROUP BY
        t1.active_date
)
,daily AS (
    SELECT
        '搜索结果页-二导新户型卡'               AS scene
        ,t1.active_date                        AS active_date
        ,t1.expo_uv                            AS expo_uv
        ,t1.expo_pv                            AS expo_pv
        ,nvl(t2.click_uv, 0)                   AS click_uv
        ,nvl(t2.click_pv, 0)                   AS click_pv
    FROM search_expo_agg t1
    LEFT JOIN search_click_agg t2
      ON t1.active_date = t2.active_date

    UNION ALL

    SELECT
        '二手首页'                             AS scene
        ,t1.active_date                        AS active_date
        ,t1.expo_uv                            AS expo_uv
        ,t1.expo_pv                            AS expo_pv
        ,nvl(t2.click_uv, 0)                   AS click_uv
        ,nvl(t2.click_pv, 0)                   AS click_pv
    FROM ershou_expo_agg t1
    LEFT JOIN ershou_click_agg t2
      ON t1.active_date = t2.active_date
)
SELECT
    t1.scene                                   AS `场景`
    ,t1.active_date                            AS `日期`
    ,t1.expo_uv                                AS `曝光UV`
    ,t1.expo_pv                                AS `曝光PV`
    ,t1.click_uv                               AS `点击UV`
    ,t1.click_pv                               AS `点击PV`
    ,CASE
         WHEN t1.expo_uv = 0 THEN 0
         ELSE t1.click_uv * 1.0 / t1.expo_uv
     END                                       AS `UCTR`
    ,CASE
         WHEN t1.expo_pv = 0 THEN 0
         ELSE t1.click_pv * 1.0 / t1.expo_pv
     END                                       AS `PCTR`
FROM daily t1
;
```

## 注意

- 与内容横卡 CTR 模板分流：横卡走中间表 + `fb_expo_id×duid`；本口径走底表 + `count(1)`
- 搜索 80326/80327 的物料 key 是 `$.item_type`，不是 `$.fb_item_type`
