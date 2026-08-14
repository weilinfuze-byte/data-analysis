# rpt.rpt_bj_content_sj_by_marketing_result_di

> 北京内容商机按营销大区（大部）日汇总结果表。
> as of 2026-08-14, source: 北京内容商机分大部/bj_content_sj_by_marketing.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 北京内容商机按营销大区汇总结果指标表 |
| 全名 | `rpt.rpt_bj_content_sj_by_marketing_result_di` |
| 粒度 | 统计日期 × 营销大区 |
| 分区 | `pt` |
| 工厂表单 | 库选 `rpt` 后只填 `bj_content_sj_by_marketing_result_di` |
| 依赖 | `rpt.rpt_content_sj_trans_detail_da`（需先跑中间表） |

## 字段

| 字段 | 类型 | 含义 |
|------|------|------|
| stat_date | string | 统计日期 |
| marketing_name | string | 营销大区 |
| contributor_cnt | bigint | 投稿人数 |
| content_cnt | bigint | 内容生产量 |
| detail_expo_pv | bigint | 内容详情页曝光量 |
| detail_expo_uv | bigint | 内容详情页曝光人数 |
| sj_booth_cnt | bigint | 展位商机量 |
| sj_trace_cnt | bigint | 溯源商机量 |
| sj_protect_cnt | bigint | 保护商机量 |
| sj_total_cnt | bigint | 内容商机量（跨类型去重） |
| sj_show_cnt | bigint | 内容商机带看量 |
| sj_deal_cnt | bigint | 内容商机成交量 |

## 查数

```sql
SELECT *
FROM rpt.rpt_bj_content_sj_by_marketing_result_di
WHERE pt = '${-1d_pt}'
ORDER BY sj_total_cnt DESC
;
```

## 调度顺序

1. `content_sj_trans_detail_da.sql` → 中间表
2. `bj_content_sj_by_marketing.sql` → 本表
