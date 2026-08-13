# 用户关注实体清单（Locked）

> ⚠️ 只替换标记参数（站点范围、`entity_type`、时间窗口）；不改贝壳/链家双表 UNION、有效关注过滤、字段对齐。
>
> 口径要点：
> - 去重键：`ucid`（商机/画像/圈选场景）
> - 贝壳：`dw.dw_plat_user_housedel_fllow_da`（`user_ucid` + `follow_status='1'` + `follow_time`）
> - 链家：`dw.dw_plat_lianjia_user_user_favorite_da`（`user_id` + `status='1'` + `create_time`）
> - 日快照优先 `pt = '${-1d_pt}'`；再用业务时间字段卡窗口（勿只靠多分区扫）
> - 链家时间条件必须用 `>=` 近 N 天，**禁止**写成 `= date_sub(..., N)`（历史稿踩坑）
> - `entity_type` 枚举含义见下方；**未确认前不要擅自改映射注释**
>
> 表详情：[user_follow_da.md](../tables/user_follow_da.md)

## entity_type 枚举（待确认）

| 取值 | 历史 SQL 注释 / 工厂文档 | 状态 |
|------|--------------------------|------|
| `resblock` | 历史注释：小区 | **待确认** |
| `project` | 历史注释：楼盘 | **待确认** |
| `house` / `House` | 链家工厂文档列举；与 `secondhand`/`ershoufang` 关系不明 | **待确认** |
| `secondhand` | 历史 SQL：二手房关注 | **待确认** |
| `ershoufang` | 历史 SQL：与 `secondhand` 并列过滤二手房 | **待确认** |
| `search` | 链家工厂文档：搜索条件关注 | **待确认** |

写 SQL 时把实际用到的取值写进 `IN (...)`，并在注释里标明「待确认」。

## 模版 A：近 N 天有效关注实体（贝壳 + 链家）

```sql
-- 参数：{entity_types} / {n_days}
, follow AS (
    -- 贝壳
    SELECT
        DISTINCT user_ucid AS ucid
        ,entity_id
        ,entity_type
        ,'beike' AS site
    FROM dw.dw_plat_user_housedel_fllow_da
    WHERE pt = '${-1d_pt}'
        AND entity_type IN ({entity_types})   -- 例：'resblock' / 'house' / 'project'；含义待确认
        AND follow_status = '1'               -- 有效关注
        AND follow_time != '1000-01-01 00:00:00'
        AND to_date(follow_time) >= date_sub(CURRENT_DATE, {n_days})
        AND user_ucid IS NOT NULL
        AND user_ucid NOT IN ('-911','null','0')

    UNION ALL

    -- 链家
    SELECT
        DISTINCT CAST(user_id AS string) AS ucid
        ,entity_id
        ,entity_type
        ,'lianjia' AS site
    FROM dw.dw_plat_lianjia_user_user_favorite_da
    WHERE pt = '${-1d_pt}'
        AND entity_type IN ({entity_types})   -- 例：'resblock' / 'house' / 'project'；含义待确认
        AND status = '1'                      -- 有效关注
        AND to_date(create_time) >= date_sub(CURRENT_DATE, {n_days})
        AND user_id IS NOT NULL
)
```

## 模版 B：行为人群 LEFT JOIN 排除已关注

```sql
-- 行为表 a LEFT JOIN follow b
-- ON a.ucid = b.ucid AND a.entity_id = b.entity_id
-- WHERE b.ucid IS NULL
```

## 模版 C：关注归一到小区（二手房需映射）

> 仅当 `entity_type` 确认含二手房、且要把房源关注归到小区时使用。
> 映射表：`rpt.rpt_comm_hdel_housedel_info_da`（`housedel_id → resblock_id`）。

```sql
, follow_resblock AS (
    SELECT
        t1.user_ucid AS ucid
        ,CASE
            WHEN t1.entity_type IN ('secondhand','ershoufang','house','House')  -- 房源类取值待确认
                THEN t2.resblock_id
            ELSE t1.entity_id
         END AS resblock_id
    FROM dw.dw_plat_user_housedel_fllow_da t1
    LEFT JOIN rpt.rpt_comm_hdel_housedel_info_da t2
        ON t2.pt = '${-1d_pt}'
        AND t1.entity_id = t2.housedel_id
        AND t2.resblock_id IS NOT NULL
        AND t2.resblock_id NOT IN ('null','-911','0')
    WHERE t1.pt = '${-1d_pt}'
        AND t1.follow_status = '1'
        AND t1.entity_type IN ({entity_types})   -- 待确认
        AND t1.user_ucid IS NOT NULL
        AND t1.user_ucid NOT IN ('-911','null','0')
    GROUP BY
        t1.user_ucid
        ,CASE
            WHEN t1.entity_type IN ('secondhand','ershoufang','house','House')
                THEN t2.resblock_id
            ELSE t1.entity_id
         END
)
```

## 参数替换清单

| 标记 | 含义 | 示例 |
|------|------|------|
| `{entity_types}` | 关注实体类型 | `'resblock'` / `'project'` / `'house'` |
| `{n_days}` | 近 N 天窗口 | `60` / `7` / `1` |
