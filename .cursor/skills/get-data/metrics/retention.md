# 留存 / 复访指标

> 硬规则：以下定义 verbatim 使用。页面活跃与内容生态留存均用 **duid**（见 [content-ecology.md](content-ecology.md)）。
> 参考：`01 商业分析师/01 经纪业务/留存复访.sql`、`…/房源详情页改版/留存.sql`

### 结构（固定）

- 表：`rpt.rpt_log_bi_user_behivor_detail_flow_di`
- 写法：dau CTE 自 LEFT JOIN（`a`=基准日，`b`=回访日）
- JOIN：`a.用户键 = b.用户键`（可加 site/dp/uicode/ab_tag）

### 7 日留存用户数 / 留存率

```sql
COUNT(DISTINCT CASE
    WHEN DATEDIFF(b.active_date, a.active_date) BETWEEN 1 AND 7
    THEN a.duid
END) AS retain_uv_7d
-- 留存率 = retain_uv_7d / COUNT(DISTINCT a.duid)
```

### 1–7 日复访天数

```sql
COUNT(DISTINCT CASE
    WHEN DATEDIFF(b.active_date, a.active_date) BETWEEN 1 AND 7
    THEN concat(a.duid, b.active_date)
END) AS revisit_days_1_7
```
- 不含当日；不要用旧口径 `0 AND 6`

---

### 普通查询写法（Adhoc）

- 用途：临时分析、一次拉多日对比
- 做法：`pt` 覆盖整段窗口，`a` 不限制单日，按 `active_date` group 出多日结果
- 特点：近几日的长窗口留存未算满（半成品会混在结果里），适合人眼看趋势，不适合直接当日更底表

### 建表写法（成熟日，推荐日更 ETL）

- 用途：落底表，后续按 `active_date` 与分发/消费表关联
- 参考：`01 经纪业务/09 二手/20241108 房源详情页改版/留存.sql`
- 做法：
  1. `pt` 取 `${-Nd_pt}` ~ `${-1d_pt}`（N=最长窗口）
  2. **基准日 a 固定为已成熟日**：N 日留存用 `active_date = '${-Nd_yyyy-MM-dd}'`
  3. 每天 `insert overwrite ... partition(pt='${-1d_pt}')`，只写入当天算满的那几个 cohort
  4. 多窗口（次日/7/14/30）用 `UNION ALL`，每段一个 `retain_window` + 对应 `-Nd` 基准日
- 关联：`LEFT JOIN ... ON active_date AND retain_window = '7d'`（或 pivot）
- 特点：表内都是算满值；近 N 日在对应长窗口上暂时没行，不会出现半成品
