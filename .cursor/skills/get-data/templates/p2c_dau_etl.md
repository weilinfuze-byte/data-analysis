# P2C DAU 底表 ETL（Locked）

> 来源：`04 交易P2C/01 数据分析/【看板底表】DAU.sql`
> 只替换 pt / 日期，不改 union 段结构与 grouping sets。

```sql
-- Tez 加速（5 行 set 块，略）

WITH jiaoyi AS (
    -- 核心四页面
    SELECT active_date, dp, site, uicode, pid, evt_id, action,
           duid, ucid, client_time, client_os_type, client_os_version,
           client_app_version, city_code, city_name, business_name
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
    WHERE 1 = 1
        AND t1.pt = '${-1d_pt}'
        AND t1.uicode IN (
            'osa_jiaoyizhuanjia', 'transaction_expert_person',
            'transaction_expert_articlelist', 'transaction_expert_articledetail'
        )
        AND t1.evt_id = '1,3'

    UNION ALL

    -- 动态主页 Tab 点击
    SELECT active_date, dp, 'beike' AS site, uicode, pid, evt_id, action,
           duid, ucid, client_time, client_os_type, client_os_version,
           client_app_version, city_code, city_name, business_name
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
    WHERE t1.pt = '${-1d_pt}'
        AND t1.uicode = 'osa_homepage'
        AND t1.evt_id = '91922'
        AND get_json_object(t1.action, '$.tab_name') = '交易专家'

    UNION ALL

    -- 动态主页 moments（版本门槛）
    SELECT ...
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
    WHERE t1.pt = '${-1d_pt}'
        AND t1.uicode = 'transactionexpert_moments'
        AND t1.evt_id = '1,3'
        AND t1.client_app_version >= '3.05.30'

    UNION ALL

    -- 专属管家入口点击
    SELECT ...
    WHERE t1.evt_id = '91914'
        AND get_json_object(t1.action, '$.business_type') = '交易专家'
        AND get_json_object(t1.action, '$.strategy_info') = 'policy_issuance'
)
INSERT OVERWRITE TABLE rpt.rpt_p2c_dau_result_di PARTITION (pt = '${-1d_pt}')
SELECT
    t1.active_date,
    nvl(t1.uicode, 'all') AS uicode,
    COUNT(DISTINCT t1.ucid) AS uv
FROM jiaoyi t1
GROUP BY active_date, uicode
GROUPING SETS (
    (active_date),
    (active_date, uicode)
)
```

## 看板模型

```sql
SELECT active_date AS "活跃日期", uv AS "DAU"
FROM rpt.rpt_p2c_dau_result_di
WHERE pt BETWEEN '20260305000000' AND '${-1d_pt}'
```
