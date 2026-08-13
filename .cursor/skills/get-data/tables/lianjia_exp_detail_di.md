# rpt.rpt_comm_log_lianjia_exp_detail_di

> 链家元素曝光。历史 SQL 引用 **54** 次。

## 用途

- 链家 App 元素曝光
- 与贝壳曝光、点击表三表 UNION（「贝壳+链家」口径）

## 必带过滤

```sql
WHERE 1 = 1
  AND t1.pt = '${-1d_pt}'
```

## UNION 写法

```sql
SELECT ..., 'lianjia' AS site, ...
FROM rpt.rpt_comm_log_lianjia_exp_detail_di t1
WHERE lower(t1.uicode) = '{uicode}'
```

## AB 版本门槛

链家 App 版本号与贝壳不同，示例：

```sql
WHEN t1.site = 'lianjia' AND t1.client_app_version >= '9.83.01' THEN '已更新APP'
```

## 已知坑

- 小程序 uicode 可能与 App 不同（如 `house_detail` vs `ershou/detail`）
- 三表 UNION 时列数、顺序必须完全一致
