# 商机溯源（页面 uicode / 元素 ele_app_id）（Locked）

> ⚠️ 只替换业务线、归因键（uicode 或 ele_app_id）、步长、日期、站点端；不改 JOIN 路径。
>
> 口径要点：
> - **溯源商机** ≠ 页面 adid 当场商机；= 访问过某页 / 点过某按钮后，在后续路径上产生的商机
> - 页面溯源：`uicode`；元素溯源：`ele_app_id`
> - **`distance` = 步长**：当前页面为第 1 步，后续几个页面内（几步内）产生的商机
> - 关联键：`commercial_id`；商机对：`is_commercial_couple = 1`
> - CTE 衔接用 `,sj AS (`（逗号写在下一 CTE 名前）

```sql
-- 商机溯源模版（页面 uicode / 元素 ele_app_id）

WITH sy AS (
    SELECT
        concat_ws('-', substr(t1.pt, 1, 4), substr(t1.pt, 5, 2), substr(t1.pt, 7, 2)) AS stat_date
        ,t1.commercial_id
        ,t1.duid
        ,t1.uicode
        ,t1.ele_app_id
        ,t1.app_id
        ,t1.distance
    FROM shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di t1
    WHERE t1.pt BETWEEN '{start_pt}' AND '${-1d_pt}'
      AND t1.business_name = '{business_name}'
      -- 归因二选一（或按需组合）：
      AND lower(t1.uicode) IN ('{uicode}')              -- 页面溯源
      -- AND t1.ele_app_id IN ('{ele_app_id_1}', '{ele_app_id_2}')  -- 元素溯源
      -- 限制步长：当前页面为第1步，后续几个页面内（几步内）产生的商机
      AND t1.distance BETWEEN 1 AND 3
    GROUP BY
        concat_ws('-', substr(t1.pt, 1, 4), substr(t1.pt, 5, 2), substr(t1.pt, 7, 2))
        ,t1.commercial_id
        ,t1.duid
        ,t1.uicode
        ,t1.ele_app_id
        ,t1.app_id
        ,t1.distance
)
,sj AS (
    SELECT
        substr(t1.occur_date, 1, 10) AS occur_date
        ,t1.commercial_id
        ,t1.commercial_couple_id
        ,t1.duid
        ,t1.cust_ucid
    FROM rpt.rpt_asm_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.business_name = '{business_name}'
      AND t1.is_commercial_couple = 1
      AND substr(t1.occur_date, 1, 10) BETWEEN '{start_date}' AND '{end_date}'
      -- AND t1.website_name = '贝壳'
      -- AND t1.client_name = 'app'
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('null','-911')
    GROUP BY
        substr(t1.occur_date, 1, 10)
        ,t1.commercial_id
        ,t1.commercial_couple_id
        ,t1.duid
        ,t1.cust_ucid
)

SELECT
    t2.occur_date
    -- ,t1.uicode
    -- ,t1.ele_app_id
    ,count(DISTINCT t2.commercial_couple_id) AS sy_sj_pv
    ,count(DISTINCT t2.duid)                 AS sy_sj_uv
FROM sy t1
INNER JOIN sj t2
  ON t1.commercial_id = t2.commercial_id
 -- AND t1.stat_date = t2.occur_date            -- 需要同日对齐时打开
GROUP BY
    t2.occur_date
    -- ,t1.uicode
    -- ,t1.ele_app_id
;
```

## 参数

| 参数 | 说明 |
|------|------|
| `{business_name}` | 业务线，如 `二手`、`新房` |
| `{uicode}` | 页面溯源时填写 |
| `{ele_app_id_*}` | 元素/按钮溯源时填写 |
| `distance BETWEEN 1 AND 3` | 步长；当前页=第1步，改区间即改「几步内」 |
| `{start_pt}` / `{start_date}` / `{end_date}` | 溯源表分区窗、商机发生日窗 |
| 同日对齐 | 需要时打开 `stat_date = occur_date` |

## 与「页面 adid 商机」区别

| | 页面商机 | 溯源商机 |
|--|----------|----------|
| 表 | 仅商机明细 | 溯源路径表 + 商机明细 |
| 归因 | `adid` | `uicode` / `ele_app_id` |
| 含义 | 该展位当场商机 | 源场景后路径上产生的商机 |

页面 adid 模版见 [page_sj_by_adid.md](page_sj_by_adid.md)。

## 来源

- 语料：榜单窄口径 uicode + `distance 1–3`；新房首页 `ele_app_id` 元素溯源
- 表：`shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di`（table_id=1223528）
- 确认：2026-07-31
