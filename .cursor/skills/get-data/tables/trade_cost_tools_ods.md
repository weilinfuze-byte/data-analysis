# 四工具 ODS 表

> 购房能力评估、房贷方案、税费计算、成本规划。UNION ALL 合并分析。

## 表清单

| 工具 | 表 | 用户 ID 字段 | 时间字段 | 结果字段 |
|------|-----|-------------|----------|----------|
| 购房能力评估 | `ods.ods_plat_trade_cost_assess_calc_record_da` | calc_user_id | ctime | calc_result |
| 房贷方案 | `ods.ods_plat_trade_cost_home_loan_da` | user_id | ctime | plan_str |
| 税费计算 | `ods.ods_plat_trade_cost_tax_calc_record_da` | cal_user_id | create_time | tax_data |
| 成本规划 | `ods.ods_plat_trade_cost_home_cost_da` | user_id | ctime | tax_data |

## UNION 模板

```sql
WITH card_info AS (
    SELECT substr(ctime, 1, 10) AS active_date,
           calc_user_id AS ucid,
           calc_result AS result_info,
           '购房能力评估' AS name
    FROM ods.ods_plat_trade_cost_assess_calc_record_da
    WHERE pt = '${-1d_pt}'
      AND substr(ctime, 1, 10) BETWEEN '${-7d_yyyy-MM-dd}' AND '${-1d_yyyy-MM-dd}'
    UNION ALL
    -- 房贷、税费、成本规划 ...
)
```

## 信息卡 vs 结果卡

```sql
CASE
    WHEN result_info IS NULL OR result_info IN ('', ' ') THEN '信息卡'
    ELSE '结果卡'
END AS type
```

## 工具完整使用

`result_info IS NOT NULL` 的去重 ucid，或结果卡曝光 evt_id IN (92247, 92259, 92272, 92290)。
