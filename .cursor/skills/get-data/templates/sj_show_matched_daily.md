# 商机带看量（人店匹配 · 按带看日）（Locked）

> ⚠️ 只替换 `{start_date}` / `{end_date}`；不改 CTE 结构、JOIN 路径、过滤逻辑。
>
> 口径要点（完整定义见 [metrics/commerce.md](../metrics/commerce.md)「商机带看量」）：
> - **≠ 工厂 `is_show = 1`**；本指标为人店+时序 JOIN
> - 计数：`COUNT(DISTINCT commercial_couple_id)`
> - 日维度：带看发生日；输出带看日 × 业务线(二手/新房)
> - 商机：`is_commercial_couple = 1`；历史不限起点
> - 匹配：商机 `cust_ucid` + `agent_ucid` = 带看用户 + 带看经纪人
> - 时序：带看日 **`>=`** 商机日（当天算）
> - 一对多：一带看挂多条历史商机对，全部计入
> - 二手经纪人：`showagent_ucid`；新房经纪人：`agent_ucid`（cast bigint）
> - 带看有效：二手买卖 + `is_showing_valid=1`；新房 `is_valid=1` + 排除 create_type 4/5/8

```sql
WITH sj AS (
    SELECT
        t1.commercial_couple_id
        ,t1.cust_ucid
        ,t1.agent_ucid
        ,substr(t1.occur_date, 1, 10)                      AS occur_date
    FROM rpt.rpt_asm_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
        AND t1.is_commercial_couple = 1
        AND t1.cust_ucid IS NOT NULL
        AND t1.cust_ucid NOT IN ('-911', 'null')
        AND t1.agent_ucid IS NOT NULL
        AND t1.agent_ucid NOT IN ('-911', 'null')
        AND t1.commercial_couple_id IS NOT NULL
        AND t1.commercial_couple_id NOT IN ('-911', 'null')
        AND substr(t1.occur_date, 1, 10) <= '{end_date}'
    GROUP BY
        t1.commercial_couple_id
        ,t1.cust_ucid
        ,t1.agent_ucid
        ,substr(t1.occur_date, 1, 10)
)
,cust AS (
    SELECT
        t1.custdel_id
        ,t1.customer_uid                                   AS ucid
    FROM dw.dw_cdel_custdel_da t1
    WHERE t1.pt = '${-1d_pt}'
        AND t1.customer_uid IS NOT NULL
        AND t1.customer_uid NOT IN ('-911', '0')
    GROUP BY
        t1.custdel_id
        ,t1.customer_uid
)
,show_raw AS (
    SELECT
        t2.ucid
        ,t1.showagent_ucid                                 AS agent_ucid
        ,t1.showing_date
        ,'二手'                                            AS type
    FROM
    (
        SELECT
            custdel_id
            ,showagent_ucid
            ,concat(
                substr(cast(showing_date AS string), 1, 4), '-',
                substr(cast(showing_date AS string), 5, 2), '-',
                substr(cast(showing_date AS string), 7, 2)
            )                                              AS showing_date
        FROM rpt.rpt_shh_show_showing_housedel_info_da
        WHERE pt = '${-1d_pt}'
            AND del_type_code = '990001001'
            AND is_showing_valid = 1
            AND showagent_ucid IS NOT NULL
            AND showagent_ucid NOT IN ('-911', 'null')
            AND concat(
                substr(cast(showing_date AS string), 1, 4), '-',
                substr(cast(showing_date AS string), 5, 2), '-',
                substr(cast(showing_date AS string), 7, 2)
            ) BETWEEN '{start_date}' AND '{end_date}'
        GROUP BY
            custdel_id
            ,showagent_ucid
            ,concat(
                substr(cast(showing_date AS string), 1, 4), '-',
                substr(cast(showing_date AS string), 5, 2), '-',
                substr(cast(showing_date AS string), 7, 2)
            )
    ) t1
    INNER JOIN cust t2
        ON t1.custdel_id = t2.custdel_id

    UNION ALL

    SELECT
        t2.ucid
        ,cast(t1.agent_ucid AS bigint)                     AS agent_ucid
        ,t1.showing_date
        ,'新房'                                            AS type
    FROM
    (
        SELECT
            custdel_id
            ,agent_ucid
            ,substr(showing_start_time, 1, 10)             AS showing_date
        FROM rpt.rpt_nh_show_house_showing_info_da
        WHERE pt = '${-1d_pt}'
            AND is_valid = 1
            AND old_showing_create_type NOT IN ('4', '5', '8')
            AND agent_ucid IS NOT NULL
            AND cast(agent_ucid AS string) NOT IN ('-911', 'null')
            AND substr(showing_start_time, 1, 10) BETWEEN '{start_date}' AND '{end_date}'
        GROUP BY
            custdel_id
            ,agent_ucid
            ,substr(showing_start_time, 1, 10)
    ) t1
    INNER JOIN cust t2
        ON t1.custdel_id = t2.custdel_id
)
,matched AS (
    SELECT
        t2.showing_date
        ,t2.type
        ,t1.commercial_couple_id
    FROM sj t1
    INNER JOIN show_raw t2
        ON t1.cust_ucid = t2.ucid
       AND t1.agent_ucid = t2.agent_ucid
       AND t2.showing_date >= t1.occur_date
    GROUP BY
        t2.showing_date
        ,t2.type
        ,t1.commercial_couple_id
)

SELECT
    showing_date
    ,type
    ,count(DISTINCT commercial_couple_id)                  AS sj_show_cnt
FROM matched
GROUP BY
    showing_date
    ,type
ORDER BY
    showing_date
    ,type
;
```

## 可替换参数

| 参数 | 含义 | 示例 |
|------|------|------|
| `{start_date}` | 带看日起 | `2026-08-10` |
| `{end_date}` | 带看日止 | `2026-08-16` |

## 关联表

| 表 | 用途 | Detail |
|----|------|--------|
| `rpt.rpt_asm_sj_trans_detail_da` | 历史商机对 | [tables/asm_sj_trans_detail_da.md](../tables/asm_sj_trans_detail_da.md) |
| `rpt.rpt_shh_show_showing_housedel_info_da` | 二手带看 | [tables/shh_show_showing_housedel_info_da.md](../tables/shh_show_showing_housedel_info_da.md) |
| `rpt.rpt_nh_show_house_showing_info_da` | 新房带看 | [tables/nh_show_house_showing_info_da.md](../tables/nh_show_house_showing_info_da.md) |
| `dw.dw_cdel_custdel_da` | 带看用户桥 | [tables/cdel_custdel_da.md](../tables/cdel_custdel_da.md) |

## 已知坑

- **禁止**与工厂 `is_show=1` 混用
- 二手 `showing_date` 拼 `yyyy-MM-dd` 后**不要**再包 `to_date()`
- 新房 `agent_ucid` 为 string，JOIN 前 cast
- 客源表 C3；无权限卡在 `cust` CTE

## 来源

- 项目：`商机带看成交量/sj_show_daily.sql`（2026-08-14）
