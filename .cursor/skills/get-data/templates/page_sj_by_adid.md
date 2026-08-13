# 页面商机（按 adid 展位）（Locked）

> ⚠️ 只替换 `business_name`、`adid` 列表、日期参数；三次握手整段可删，不改商机底座结构。
>
> 口径要点：
> - `adid` = 广告位 ID（工厂）；业务上按页面 adid 列表圈商机（常称展位）
> - 商机对：`is_commercial_couple = 1`
> - `is_del` = 是否转委托（不是有效商机）
> - 三次握手是商机子集，**按需**使用，不是必算

```sql
-- 通用：某页面商机（按 adid 展位）

WITH sj AS (
    SELECT
        t1.occur_date
        ,CASE
             WHEN t1.website_name = '贝壳' THEN 'beike'
             WHEN t1.website_name = '链家' THEN 'lianjia'
             ELSE t1.website_name
         END                                               AS site
        ,CASE
             WHEN t1.client_name = '小程序' THEN 'xcx'
             ELSE t1.client_name
         END                                               AS dp
        ,t1.cust_ucid                                      AS ucid
        ,t1.duid
        ,t1.commercial_couple_id
        ,t1.adid
        ,split(t1.source_key_id, ':')[0]                   AS convid
    FROM rpt.rpt_asm_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.occur_date = '${-1d_yyyy-MM-dd}'
      AND t1.business_name = '{business_name}'             -- 改：二手 / 新房 …
      AND t1.is_commercial_couple = 1
      AND t1.adid IN (                                     -- 改：目标页面展位 adid
          '{adid_1}'
          ,'{adid_2}'
      )
)
-- 可选：三次握手会话（商机子集；不需要时整段注释掉，并去掉下方 LEFT JOIN 与握手指标）
,woshou AS (
    SELECT
        split(t1.source_pk, ':')[0]                        AS convid
    FROM dw.dw_log_commerce_stream_clue_inf_di t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.data_lables = '["1002"]'
    GROUP BY split(t1.source_pk, ':')[0]
)

SELECT
    t1.occur_date
    ,t1.site
    ,t1.dp
    ,count(DISTINCT t1.ucid)                               AS sj_uv
    ,count(DISTINCT t1.commercial_couple_id)               AS sj_pv
    ,count(DISTINCT CASE WHEN t2.convid IS NOT NULL THEN t1.ucid END)
                                                           AS woshou_sj_uv
    ,count(DISTINCT CASE WHEN t2.convid IS NOT NULL THEN t1.commercial_couple_id END)
                                                           AS woshou_sj_pv
FROM sj t1
LEFT JOIN woshou t2
  ON t1.convid = t2.convid
GROUP BY
    t1.occur_date
    ,t1.site
    ,t1.dp
;
```

## 参数

| 参数 | 说明 |
|------|------|
| `{business_name}` | 业务线，如 `二手`、`新房` |
| `{adid_1}` … | 目标页面商机展位 ID；多展位全部列入 `IN` |
| 三次握手 | 不需要时删除 `woshou` CTE、`LEFT JOIN` 及 `woshou_*` 指标 |

## 去重键

| 指标 | 键 |
|------|-----|
| 商机 UV | `cust_ucid`（输出别名 `ucid`） |
| 商机 PV | `commercial_couple_id` |
| 跟页面 DAU 算转化 | 流量侧用 `duid`；需先对齐分析单位，勿与 ucid 混用 |

## 来源

- 语料：`01 经纪业务/09 二手/20241108 房源详情页改版/整体商机.sql`
- 确认：adid = 展位；页面商机 = 该页 adid；三次握手 ⊆ 商机、按需使用（2026-07-31）
