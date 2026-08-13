# 流量 UNION 模板（Locked）

> ⚠️ 对齐 716 份历史 SQL 最常用模式。只替换 `{name}`、`{uicode}`、`{expo_evt_ids}`、日期，不改 CTE 结构。

```sql
WITH {name} AS (
    -- 点击表
    SELECT
        active_date, dp, site, uicode, pid, evt_id, action,
        duid, ucid, client_time, client_os_type, client_os_version,
        client_app_version, city_code, city_name, business_name
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
    WHERE 1 = 1
        AND t1.pt = '${-1d_pt}'
        AND t1.site = 'beike'
        AND t1.dp = 'app'
        AND lower(t1.uicode) = '{uicode}'

    UNION ALL

    -- 贝壳曝光表
    SELECT
        active_date, dp, 'beike' AS site, uicode, pid, evt_id, action,
        duid, ucid, client_time, client_os_type, client_os_version,
        client_app_version, city_code, city_name, business_name
    FROM rpt.rpt_comm_log_beike_exp_detail_di t1
    WHERE 1 = 1
        AND t1.pt = '${-1d_pt}'
        AND lower(t1.uicode) = '{uicode}'
        AND t1.evt_id IN ({expo_evt_ids})
        AND t1.dp = 'app'

    UNION ALL

    -- 链家曝光表（可选，贝壳+链家口径时保留）
    SELECT
        active_date, dp, 'lianjia' AS site, uicode, pid, evt_id, action,
        duid, ucid, client_time, client_os_type, client_os_version,
        client_app_version, city_code, city_name, business_name
    FROM rpt.rpt_comm_log_lianjia_exp_detail_di t1
    WHERE 1 = 1
        AND t1.pt = '${-1d_pt}'
        AND lower(t1.uicode) = '{uicode}'
)
-- 后续：{name}_duid / expo / click CTE → LEFT JOIN → 聚合
```

## 后续 CTE 模式

```sql
-- DAU
,{name}_duid AS (
    SELECT active_date, COUNT(DISTINCT duid) AS dau
    FROM {name}
    WHERE evt_id = '1,3'
    GROUP BY active_date
)

-- 曝光
,{name}_expo AS (
    SELECT active_date, duid, COUNT(1) AS pv
    FROM {name}
    WHERE evt_id IN ({expo_evt_ids})
    GROUP BY active_date, duid
)

-- 点击
,{name}_click AS (
    SELECT active_date, duid, COUNT(1) AS pv
    FROM {name}
    WHERE evt_id IN ({click_evt_ids})
    GROUP BY active_date, duid
)
```

## 参考 SQL

- `01 商业分析师/01 经纪业务/09 二手/-- 流量数据.sql`
- `01 商业分析师/01 经纪业务/05 榜单/20241217 榜单看板/模板.sql`
