# rpt.rpt_bj_content_sj_result_di

> 北京内容商机全市日汇总结果表（不分大部）。
> as of 2026-08-14, source: 北京内容商机分大部/bj_content_sj.sql

| 元信息 | 值 |
|--------|----|
| 中文名 | 北京内容商机汇总结果指标表 |
| 全名 | `rpt.rpt_bj_content_sj_result_di` |
| 粒度 | 统计日期（全市 1 行） |
| 分区 | `pt` |
| 工厂表单 | 库选 `rpt` 后只填 `bj_content_sj_result_di` |
| 依赖 | `rpt.rpt_content_sj_trans_detail_da`（需先跑中间表） |

## 字段

| 字段 | 类型 | 含义 |
|------|------|------|
| stat_date | string | 统计日期 |
| contributor_cnt | bigint | 投稿人数 |
| content_cnt | bigint | 内容生产量 |
| detail_expo_pv | bigint | 内容详情页曝光量 |
| detail_expo_uv | bigint | 内容详情页曝光人数（duid 去重，全市） |
| sj_booth_cnt | bigint | 展位商机量 |
| sj_trace_cnt | bigint | 溯源商机量 |
| sj_protect_cnt | bigint | 保护商机量 |
| sj_total_cnt | bigint | 内容商机量（跨类型去重） |
| sj_show_cnt | bigint | 内容商机带看量 |
| sj_deal_cnt | bigint | 内容商机成交量 |

## 口径

- **投稿 / 生产 / 流量**：昨天新上线北京内容（含 `im_ucid` 为空）；流量 UV 为全市 `duid` 去重，不是分内容 UV 相加
- **三类商机**：`rpt_content_sj_trans_detail_da` 北京昨天，**不要求** `parent_scene_id` 归因内容；分类型可重叠，总量跨类型去重
- **带看 / 成交**：历史内容商机 × 昨天有效带看/成交，人店匹配；≠ 工厂 `is_show` / `is_deal`
- 与按大部表 **不可直接相加核对**：大部表按内容归因后拆分，本表是全市内容商机全集

## 查数

```sql
SELECT *
FROM rpt.rpt_bj_content_sj_result_di
WHERE pt = '${-1d_pt}'
;
```

## 调度顺序

1. `content_sj_trans_detail_da.sql` → 中间表
2. `bj_content_sj.sql` → 本表
