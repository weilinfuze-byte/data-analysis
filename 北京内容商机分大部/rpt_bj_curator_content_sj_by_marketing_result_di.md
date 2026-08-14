# rpt.rpt_bj_curator_content_sj_by_marketing_result_di

> 北京主理人内容商机按营销大区（大部）日汇总结果表。
> as of 2026-08-14, source: 北京内容商机分大部/bj_curator_content_sj_by_marketing.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 北京主理人内容商机按营销大区汇总结果指标表 |
| 全名 | `rpt.rpt_bj_curator_content_sj_by_marketing_result_di` |
| 粒度 | 统计日期 × 营销大区 |
| 分区 | `pt` |
| 工厂表单 | 库选 `rpt` 后只填 `bj_curator_content_sj_by_marketing_result_di` |
| 依赖 | `rpt.rpt_content_sj_trans_detail_da`（需先跑中间表） |
| 内容范围 | 生产表 `array_contains(content_tag, 'curator_content')` |

## 与全量结果表差异

| | 全量 | 主理人 |
|--|------|--------|
| 表 | `rpt_bj_content_sj_by_marketing_result_di` | 本表 |
| 生产表过滤 | 无主理人限制 | **仅主理人内容** |
| 流量 / 商机 / 带看成交 | 归因到主理人内容集合 | 同左 |

## 字段

与全量表一致：`stat_date` · `marketing_name` · `contributor_cnt` · `content_cnt` · `detail_expo_pv` · `detail_expo_uv` · `sj_booth_cnt` · `sj_trace_cnt` · `sj_protect_cnt` · `sj_total_cnt` · `sj_show_cnt` · `sj_deal_cnt`

## 查数

```sql
SELECT *
FROM rpt.rpt_bj_curator_content_sj_by_marketing_result_di
WHERE pt = '${-1d_pt}'
ORDER BY sj_total_cnt DESC
;
```

## 调度顺序

1. `content_sj_trans_detail_da.sql` → 中间表
2. `bj_curator_content_sj_by_marketing.sql` → 本表
