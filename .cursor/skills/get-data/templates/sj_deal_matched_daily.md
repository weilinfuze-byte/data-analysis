# 商机成交量（人店匹配 · 按成交日）（Locked）

> ⚠️ 只替换 `{start_date}` / `{end_date}`；不改 CTE 结构、JOIN 路径、过滤逻辑。
>
> 口径要点（完整定义见 [metrics/commerce.md](../metrics/commerce.md)「商机成交量」）：
> - **≠ 工厂 `is_deal = 1`**；本指标为人店+时序 JOIN
> - 计数：`COUNT(DISTINCT commercial_couple_id)`
> - 日维度：成交发生日；输出成交日 × 业务线(二手/新房)
> - 商机：`is_commercial_couple = 1`；历史不限起点
> - 匹配：商机 `cust_ucid` + `agent_ucid` = 成交用户 + 成交经纪人
> - 时序：成交日 **`>=`** 商机日（当天算）
> - 一对多：一成交挂多条历史商机对，全部计入
> - 二手经纪人：**`sign_ucid`（签约人）**；新房经纪人：**`agent_ucid`（主经纪人）**
> - 二手成交日：`substr(sign_time,1,10)`；新房成交日：`substr(order_time,1,10)`（认购）
> - 暂未过滤二手 `is_revoke`（与 Locked 新二成交模板一致）

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
,deal_raw AS (
    SELECT
        cust_ucid                                          AS ucid
        ,sign_ucid                                         AS agent_ucid
        ,substr(sign_time, 1, 10)                          AS deal_date
        ,'二手'                                            AS type
    FROM rpt.rpt_shh_rent_deal_agreement_detail_da
    WHERE pt = '${-1d_pt}'
        AND is_parent_agreement = 1
        AND agreement_type_code = '150001001'
        AND is_commit = 1
        AND status_code IN (
            '150005002'
            ,'150005003'
            ,'150005006'
        )
        AND del_type_name = '买卖'
        AND cust_ucid IS NOT NULL
        AND cust_ucid NOT IN ('-911', 'null')
        AND sign_ucid IS NOT NULL
        AND sign_ucid NOT IN ('-911', 'null')
        AND substr(sign_time, 1, 10) BETWEEN '{start_date}' AND '{end_date}'
    GROUP BY
        cust_ucid
        ,sign_ucid
        ,substr(sign_time, 1, 10)

    UNION ALL

    SELECT
        t2.ucid
        ,cast(t1.agent_ucid AS bigint)                     AS agent_ucid
        ,t1.deal_date
        ,'新房'                                            AS type
    FROM
    (
        SELECT
            custdel_id
            ,agent_ucid
            ,substr(order_time, 1, 10)                     AS deal_date
        FROM rpt.rpt_nh_output_deal_info_online_custdel_da
        WHERE pt = '${-1d_pt}'
            AND brand_name <> '外渠房江湖'
            AND city_name NOT LIKE '测试%'
            AND is_cancel = 0
            AND agent_ucid IS NOT NULL
            AND cast(agent_ucid AS string) NOT IN ('-911', 'null')
            AND substr(order_time, 1, 10) BETWEEN '{start_date}' AND '{end_date}'
        GROUP BY
            custdel_id
            ,agent_ucid
            ,substr(order_time, 1, 10)
    ) t1
    INNER JOIN cust t2
        ON t1.custdel_id = t2.custdel_id
)
,matched AS (
    SELECT
        t2.deal_date
        ,t2.type
        ,t1.commercial_couple_id
    FROM sj t1
    INNER JOIN deal_raw t2
        ON t1.cust_ucid = t2.ucid
       AND t1.agent_ucid = t2.agent_ucid
       AND t2.deal_date >= t1.occur_date
    GROUP BY
        t2.deal_date
        ,t2.type
        ,t1.commercial_couple_id
)

SELECT
    deal_date
    ,type
    ,count(DISTINCT commercial_couple_id)                  AS sj_deal_cnt
FROM matched
GROUP BY
    deal_date
    ,type
ORDER BY
    deal_date
    ,type
;
```

## 可替换参数

| 参数 | 含义 | 示例 |
|------|------|------|
| `{start_date}` | 成交日起 | `2026-08-10` |
| `{end_date}` | 成交日止 | `2026-08-16` |

## 关联表

| 表 | 用途 | Detail |
|----|------|--------|
| `rpt.rpt_asm_sj_trans_detail_da` | 历史商机对 | [tables/asm_sj_trans_detail_da.md](../tables/asm_sj_trans_detail_da.md) |
| `rpt.rpt_shh_rent_deal_agreement_detail_da` | 二手成交 | [tables/shh_rent_deal_agreement_detail_da.md](../tables/shh_rent_deal_agreement_detail_da.md) |
| `rpt.rpt_nh_output_deal_info_online_custdel_da` | 新房成交 | [tables/nh_output_deal_info_online_custdel_da.md](../tables/nh_output_deal_info_online_custdel_da.md) |
| `dw.dw_cdel_custdel_da` | 新房用户桥 | [tables/cdel_custdel_da.md](../tables/cdel_custdel_da.md) |

## 已知坑

- **禁止**与工厂 `is_deal=1` 混用
- 二手**无** `agent_ucid`；匹配商机经纪人用 **`sign_ucid`**，勿用 `create_ucid` / `accompany_sign_ucid`
- 新房标准成交日用 **`order_time`（认购）**，不是网签 `sign_time`
- 新房 `agent_ucid` 为 string；另有 `agent_list`，本口径只用主经纪人
- 二手 `is_revoke` 未过滤；净成交需额外确认

## 来源

- 项目：`商机带看成交量/sj_deal_daily.sql`（2026-08-14）
