# 新二有效带看用户日清单（Locked）

> ⚠️ 只替换日期窗口参数；不改 CTE 结构、JOIN 路径、过滤口径。
>
> 口径要点：
> - 输出粒度：`ucid + type + showing_date`
> - 去重键：`ucid`（商机/成交场景）
> - 二手：`rpt.rpt_shh_show_showing_housedel_info_da`（买卖 + `is_showing_valid = 1`）
> - 新房：`rpt.rpt_nh_show_house_showing_info_da`（`is_valid = 1` + 排除部分创建类型）
> - 客源桥：`dw.dw_cdel_custdel_da`（`custdel_id → customer_uid`）
> - 二手 `showing_date` 为 `yyyyMMdd`，拼成 `yyyy-MM-dd` 字符串即可，**不要**再包 `to_date()`
> - 新房带看日：`substr(showing_start_time,1,10)`
> - `GROUP BY` 必须写具体字段名，禁止 `1,2,3`

```sql
WITH show AS (
    SELECT
        t2.ucid
        ,t1.type
        ,t1.showing_date
    FROM
    (
        -- 二手有效买卖带看
        SELECT
            custdel_id
            ,'二手'                                         AS type
            ,concat(
                substr(cast(showing_date AS string),1,4),'-',
                substr(cast(showing_date AS string),5,2),'-',
                substr(cast(showing_date AS string),7,2)
            )                                              AS showing_date
        FROM rpt.rpt_shh_show_showing_housedel_info_da
        WHERE pt = '${-1d_pt}'
            AND del_type_code = '990001001'                -- 买卖；租赁=990001002
            AND is_showing_valid = 1                       -- 有效带看（勿与 is_valid 混淆）
            AND concat(
                substr(cast(showing_date AS string),1,4),'-',
                substr(cast(showing_date AS string),5,2),'-',
                substr(cast(showing_date AS string),7,2)
            ) BETWEEN '{start_date}' AND '{end_date}'      -- 改：yyyy-MM-dd
        GROUP BY
            custdel_id
            ,'二手'
            ,concat(
                substr(cast(showing_date AS string),1,4),'-',
                substr(cast(showing_date AS string),5,2),'-',
                substr(cast(showing_date AS string),7,2)
            )

        UNION ALL

        -- 新房有效带看
        SELECT
            custdel_id
            ,'新房'                                         AS type
            ,substr(showing_start_time,1,10)               AS showing_date
        FROM rpt.rpt_nh_show_house_showing_info_da
        WHERE pt = '${-1d_pt}'
            AND is_valid = 1                               -- 有效带看
            AND old_showing_create_type NOT IN ('4','5','8')
            AND substr(showing_start_time,1,10) BETWEEN '{start_date}' AND '{end_date}'
        GROUP BY
            custdel_id
            ,'新房'
            ,substr(showing_start_time,1,10)
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
        ,t1.showing_date
)

-- 示例：按日、类型统计带看人数；可改成关联画像 / 成交 / 流量
SELECT
    showing_date
    ,type
    ,count(DISTINCT ucid)                                  AS show_uv
FROM show
GROUP BY
    showing_date
    ,type
ORDER BY
    showing_date
    ,type
```

## 可替换参数

| 参数 | 含义 | 示例 |
|------|------|------|
| `{start_date}` | 带看日起 | `2026-05-02` |
| `{end_date}` | 带看日止 | `2026-07-30` |

## 关联表（权限提示）

| 表 | 用途 | 权限注意 | Detail |
|----|------|----------|--------|
| `rpt.rpt_shh_show_showing_housedel_info_da` | 二手带看 | 权限包：通用；行级城市/品牌 | [tables/shh_show_showing_housedel_info_da.md](../tables/shh_show_showing_housedel_info_da.md) |
| `rpt.rpt_nh_show_house_showing_info_da` | 新房带看 | 待确认权限包 | [tables/nh_show_house_showing_info_da.md](../tables/nh_show_house_showing_info_da.md) |
| `dw.dw_cdel_custdel_da` | 客源 → ucid | 权限包：ADHOC异地推广；C3；有行级权限 | [tables/cdel_custdel_da.md](../tables/cdel_custdel_da.md) |

## 常见变体（仍算同一模板）

| 变体 | 怎么改 |
|------|--------|
| 只要二手 / 只要新房 | 删掉对应 `UNION ALL` 分支 |
| 只要买房带看 UV（不分日） | 外层 `count(DISTINCT ucid)`，去掉 `showing_date` / `type` |
| 二手扩明细（带看次数/房源） | 二手分支加 `showing_id` / `housedel_id` / `resblock_id` / `city_code`，SELECT 与 GROUP BY 同步加；新房分支勿硬套同名字段 |
| 关联成交 | 下游 `LEFT JOIN` [deal_ershou_xinfang.md](deal_ershou_xinfang.md)，键用 `ucid`，窗用 `datediff(sign_date, showing_date)` |

## 已知坑

- 二手有效字段是 `is_showing_valid`；新房有效字段是 `is_valid`——**不要混用**
- 二手 `showing_date` 是 `bigint`（`yyyyMMdd`）；拼成 `yyyy-MM-dd` **不要**再包 `to_date()`
- 新房日期字段是 `showing_start_time`；窗口用 `substr(...,1,10)`，与二手对齐成字符串再比
- 新房必须排除 `old_showing_create_type IN ('4','5','8')`
- 窗口过滤写在带看日上，不要扫多天 `pt`
- 客源表安全等级 **C3**，权限包 `ADHOC异地推广`，无权限会卡在客源 JOIN
- 二手表有行级城市/品牌权限，跨城结果可能被裁剪

## 书写硬规则

- `GROUP BY` / `ORDER BY` 写具体字段名，禁止 `1,2,3`
- 关联键异常值：通用 `IS NOT NULL` + `NOT IN ('-911','null')`；客源 `customer_uid` 另剔 `'0'`
- 禁止剔 `''`、`' '`
- 用 `UNION ALL`（不要 `UNION`）
