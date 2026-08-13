# 新二成交用户日清单（Locked）

> ⚠️ 只替换日期窗口参数；不改 CTE 结构、JOIN 路径、过滤口径。
>
> 口径要点：
> - 输出粒度：`ucid + type + sign_date`
> - 去重键：`ucid`（商机/成交场景）
> - 二手：主协议 + 合同 + 已提交 + 签约/过户/完结 + 买卖
> - 新房：非外渠 + 非测试城 + 未退单；`custdel_id` → 客源表取 `customer_uid`
> - 二手表名含 `rent`，靠 `del_type_name = '买卖'` 筛买卖成交

```sql
WITH deal AS (
    -- 二手成交
    SELECT
        cust_ucid                                          AS ucid
        ,'二手'                                            AS type
        ,substr(sign_time,1,10)                            AS sign_date
    FROM rpt.rpt_shh_rent_deal_agreement_detail_da
    WHERE pt = '${-1d_pt}'
        AND is_parent_agreement = 1                        -- 主协议
        AND agreement_type_code = '150001001'              -- 合同
        AND is_commit = 1                                  -- 合同提交
        AND status_code IN (
            '150005002'                                    -- 签约
            ,'150005003'                                   -- 过户
            ,'150005006'                                   -- 完结
        )
        AND del_type_name = '买卖'
        AND cust_ucid IS NOT NULL
        AND cust_ucid NOT IN ('-911','null')
    GROUP BY
        cust_ucid
        ,'二手'
        ,substr(sign_time,1,10)

    UNION ALL

    -- 新房成交
    SELECT
        t2.ucid
        ,t1.type
        ,t1.sign_date
    FROM
    (
        SELECT
            '新房'                                         AS type
            ,custdel_id
            ,substr(order_time,1,10)                       AS sign_date
        FROM rpt.rpt_nh_output_deal_info_online_custdel_da
        WHERE pt = '${-1d_pt}'
            AND brand_name <> '外渠房江湖'
            AND city_name NOT LIKE '测试%'
            AND is_cancel = 0
        GROUP BY
            '新房'
            ,custdel_id
            ,substr(order_time,1,10)
    ) t1
    LEFT JOIN
    (
        SELECT
            custdel_id
            ,customer_uid                                  AS ucid
        FROM dw.dw_cdel_custdel_da
        WHERE pt = '${-1d_pt}'
            AND customer_uid NOT IN ('-911','0')
            AND customer_uid IS NOT NULL
        GROUP BY
            custdel_id
            ,customer_uid
    ) t2
        ON t1.custdel_id = t2.custdel_id
    WHERE t2.ucid IS NOT NULL
    GROUP BY
        t2.ucid
        ,t1.type
        ,t1.sign_date
)

-- 示例：按日、类型统计成交人数；可改成关联画像 / 带看 / 流量
SELECT
    sign_date
    ,type
    ,count(DISTINCT ucid)                                  AS deal_uv
FROM deal
WHERE sign_date BETWEEN '{start_date}' AND '{end_date}'    -- 改：yyyy-MM-dd
GROUP BY
    sign_date
    ,type
ORDER BY
    sign_date
    ,type
```

## 可替换参数

| 参数 | 含义 | 示例 |
|------|------|------|
| `{start_date}` | 签约日起 | `2025-01-01` |
| `{end_date}` | 签约日止 | `2025-01-31` |

## 关联表（权限提示）

| 表 | 用途 | 权限注意 | Detail |
|----|------|----------|--------|
| `rpt.rpt_shh_rent_deal_agreement_detail_da` | 二手成交 | 权限包：通用；C2 | [tables/shh_rent_deal_agreement_detail_da.md](../tables/shh_rent_deal_agreement_detail_da.md) |
| `rpt.rpt_nh_output_deal_info_online_custdel_da` | 新房成交 | 权限包：通用；有行级权限标签 | [tables/nh_output_deal_info_online_custdel_da.md](../tables/nh_output_deal_info_online_custdel_da.md) |
| `dw.dw_cdel_custdel_da` | 客源 → ucid | 权限包：ADHOC异地推广；C3；有行级权限 | [tables/cdel_custdel_da.md](../tables/cdel_custdel_da.md) |

## 常见变体（仍算同一模板）

| 变体 | 怎么改 |
|------|--------|
| 只要二手 / 只要新房 | 删掉对应 `UNION ALL` 分支 |
| 限制签约日窗口下沉到源表 | 二手加 `substr(sign_time,1,10) BETWEEN ...`；新房加 `substr(order_time,1,10) BETWEEN ...` |
| 关联带看 | 下游 `LEFT JOIN` [show_ershou_xinfang.md](show_ershou_xinfang.md)，键用 `ucid`，窗用 `datediff(sign_date, showing_date)` |

## 书写硬规则

- `GROUP BY` / `ORDER BY` 写具体字段名，禁止 `1,2,3`
- 二手 `cust_ucid`：通用关联键口径 `IS NOT NULL` + `NOT IN ('-911','null')`
- 客源桥 `customer_uid`：`NOT IN ('-911','0')` + `IS NOT NULL`（专用口径）
- 禁止剔 `''`、`' '`
