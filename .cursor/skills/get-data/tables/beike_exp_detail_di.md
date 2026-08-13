# rpt.rpt_comm_log_beike_exp_detail_di

> 贝壳元素曝光。历史 SQL 引用 **124** 次。

## 用途

- 元素/模块曝光 PV、UV
- 与 behavior_flow_di UNION 构建流量 CTE
- Feed、卡片、模块曝光分析

## 必带过滤

```sql
WHERE 1 = 1
  AND t1.pt = '${-1d_pt}'
  AND t1.dp = 'app'
```

## 标准字段块

与 [behavior_flow_di.md](behavior_flow_di.md) 对齐；site 常写 `'beike' AS site`。

## 常用模式

```sql
-- 曝光 evt_id 过滤（示例：小区详情）
AND t1.evt_id IN ('82883', '54055')
AND lower(t1.uicode) = 'communitydetailv2'
```

## 与点击表配对

| 类型 | 表 | 示例 |
|------|-----|------|
| 曝光 | 本表 | evt_id 82883 |
| 点击 | behavior_flow_di | evt_id 82884 |

## 已知坑

- 曝光表无 site 字段时需 `'beike' AS site` 与点击表对齐
- uicode 大小写用 `lower()` 更稳
