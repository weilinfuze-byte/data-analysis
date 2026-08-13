# AB 实验模板（duid + 版本过滤）（Locked）

> ⚠️ 只替换 `{name}`、`{traffic_cte}`、ab_test_sign 值、版本号，不改结构。

```sql
,{name}_duid AS (
    SELECT DISTINCT
        t1.active_date, t1.ab_tag, t1.duid, t1.dp, t1.site
    FROM (
        SELECT DISTINCT
            t1.active_date,
            CASE
                WHEN get_json_object(t1.action, '$.ab_test_sign') = '{control_sign}' THEN '对照组'
                WHEN get_json_object(t1.action, '$.ab_test_sign') = '{treat_sign}'   THEN '实验组'
                ELSE '其他'
            END AS ab_tag,
            t1.duid, t1.site, t1.dp,
            CASE
                WHEN t1.site = 'beike'   AND t1.client_app_version >= '{beike_min_ver}' THEN '已更新APP'
                WHEN t1.site = 'lianjia' AND t1.client_app_version >= '{lianjia_min_ver}' THEN '已更新APP'
                ELSE '未更新APP'
            END AS if_update
        FROM {traffic_cte} t1
        WHERE t1.evt_id = '1,3'
    ) t1
    WHERE t1.if_update = '已更新APP'
)
```

## 多臂实验（iOS/Android 分组后合并）

```sql
-- 输出层合并对照/实验
CASE
    WHEN ab_tag IN ('IOS_A1','IOS_A2','AN_A1','AN_A2') THEN 'A_对照组'
    WHEN ab_tag IN ('IOS_B1','IOS_B2','AN_B1','AN_B2') THEN 'B_实验组'
    ELSE '其他'
END AS ab_tag
```

## P2C / 房源详情 AB（$.ab_test）

```sql
CASE
    WHEN get_json_object(t1.action, '$.ab_test') = 'ab1292-1632-5134' THEN '对照组'
    WHEN get_json_object(t1.action, '$.ab_test') = 'ab1292-1632-5135' THEN '实验组'
    ELSE '其他'
END AS ab_tag
```

## 硬规则

- AB 分析必须过滤「已更新APP」
- 最终输出排除 `ab_tag = '其他'`
- 分析单位：**duid**

## 参考 SQL

- `01 商业分析师/01 经纪业务/09 二手/20241108 房源详情页改版/房源详情页DAU.sql`
- `04 交易P2C/01 数据分析/房源详情页.sql`
