# P2C 入口曝光点击底表（Locked）

> 来源：`04 交易P2C/01 数据分析/【看板底表】入口曝光点击.sql`

## 曝光 evt_id

`91912`, `92395`, `91989`, `91921`

## 点击 evt_id

`91914`, `92396`, `91990`, `91922`

## 结构

```
WITH jiaoyi AS ( ... union 各入口曝光+点击 ... )
, jiaoyi_expo AS ( ... evt_id in 曝光列表, grouping sets ... )
, jiaoyi_click AS ( ... evt_id in 点击列表, grouping sets ... )
INSERT OVERWRITE TABLE rpt.rpt_p2c_rukou_rusult_di
SELECT
    t1.active_date, t1.name, t1.uicode,
    nvl(t1.pv, 0) AS expo_pv,
    nvl(t2.pv, 0) AS click_pv,
    nvl(t1.uv, 0) AS expo_uv,
    nvl(t2.uv, 0) AS click_uv,
    nvl(t2.pv, 0) / nvl(t1.pv, 0) AS pctr,
    nvl(t2.uv, 0) / nvl(t1.uv, 0) AS uctr
FROM jiaoyi_expo t1
LEFT JOIN jiaoyi_click t2
    ON t1.active_date = t2.active_date
   AND t1.uicode = t2.uicode
   AND t1.name = t2.name
```

## 入口 name 枚举

- 底部轮播
- 消息列表
- 动态主页切换

## JSON 过滤

- `get_json_object(action,'$.business_type') = '交易专家'`
- `get_json_object(action,'$.business_type') = 'osa_jiaoyizhuanjia'`
- `get_json_object(action,'$.tab_name') = '交易专家'`
