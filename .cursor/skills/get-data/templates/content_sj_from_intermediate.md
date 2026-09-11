# 内容商机（中间表）（Locked）

> ⚠️ 只替换城市、日期；不要再对 `rpt_asm_sj_trans_detail_da` 自己 UNION 三类。
>
> 口径要点：
> - 底表：`rpt.rpt_content_sj_trans_detail_da`
> - 打标不要求 `parent_scene_id`；按内容拆才 JOIN 详情页 `scene_id`
> - 分类型允许重叠；总量 `COUNT(DISTINCT commercial_couple_id)` 跨类型去重
> - da 快照：`pt = '${-1d_pt}'` + `occur_date` 过滤，禁止 `pt <=`
> - 指标：[metrics/commerce.md](../metrics/commerce.md)；表：[tables/content_sj_trans_detail_da.md](../tables/content_sj_trans_detail_da.md)

```sql
-- 昨天内容商机量（分类型 + 总量）

SELECT
    count(DISTINCT CASE WHEN t1.content_sj_type = 'booth'   THEN t1.commercial_couple_id END) AS sj_booth_cnt
    ,count(DISTINCT CASE WHEN t1.content_sj_type = 'trace'   THEN t1.commercial_couple_id END) AS sj_trace_cnt
    ,count(DISTINCT CASE WHEN t1.content_sj_type = 'protect' THEN t1.commercial_couple_id END) AS sj_protect_cnt
    ,count(DISTINCT t1.commercial_couple_id)                                                   AS sj_total_cnt
FROM rpt.rpt_content_sj_trans_detail_da t1
WHERE t1.pt = '${-1d_pt}'
  AND substr(t1.occur_date, 1, 10) = '${-1d_yyyy-MM-dd}'
  AND t1.city_code = {city_code}                 -- 改：北京 110000
  AND t1.commercial_couple_id IS NOT NULL
  AND t1.commercial_couple_id NOT IN ('-911', 'null')
```

历史商机（带看/成交匹配侧）：同上，把 `occur_date` 改为 `<= '${-1d_yyyy-MM-dd}'`。人店匹配仍用 [sj_show_matched_daily.md](sj_show_matched_daily.md) / [sj_deal_matched_daily.md](sj_deal_matched_daily.md)，商机侧换成本中间表。

按内容归因（可选，**不是**类型判定）：

```sql
-- 商机 parent_scene_id = 详情页 scene_id → content_id
ON t1.parent_scene_id = t2.scene_id
```

`content_id` 解析见 [tables/content_detail_flow_di.md](../tables/content_detail_flow_di.md)。
