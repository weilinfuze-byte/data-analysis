# SQL 书写规范

> 本仓库团队 Hive SQL 风格。写取数 / 看板 SQL 时必须遵守。

## 1. SELECT 字段：逗号前置

逗号写在下一行字段前，第一行字段不加逗号。

```sql
SELECT
    t1.active_date                         AS active_date
    ,'homepage_feed'                       AS scene
    ,t1.card_expo_uv                       AS expo_uv
    ,nvl(t2.card_click_uv, 0)              AS click_uv
    ,CASE
         WHEN t1.card_expo_uv = 0 THEN 0
         ELSE nvl(t2.card_click_uv, 0) * 1.0 / t1.card_expo_uv
     END                                   AS uctr
```

禁止：

```sql
-- ❌ 逗号写在行尾
SELECT
    t1.active_date AS active_date,
    'homepage_feed' AS scene,
```

## 2. 表别名：统一用 t1 / t2 / t3 …

主表 `t1`，后续 JOIN 按顺序 `t2`、`t3`…；CTE 内层同样遵守。

```sql
FROM expo_uv t1
LEFT JOIN click_uv t2
  ON t1.active_date = t2.active_date
```

禁止用语义化别名作为表别名（如 `e` / `c` / `expo`），语义放在 CTE / 子查询名上。

## 2.1 CTE 衔接（硬规则，禁止双逗号）

多个 CTE 之间**只保留一处逗号**，逗号写在**下一个 CTE 名前面**：

```sql
WITH a AS (
    SELECT 1 AS x
)
,b AS (
    SELECT 2 AS y
)
INSERT OVERWRITE TABLE ...
SELECT ...
```

禁止双逗号（会报 `cannot recognize input near ',' 'xxx' 'AS'`）：

```sql
-- ❌ ), 后再写前置逗号
),
,b AS (
```

改 SQL 后必须目视检查：每个衔接只能是 `)\n,name AS (`，不能出现 `),\n,`。

## 3. 结果列名

看板底表 / 中间查询结果列用英文蛇形命名，例如：

| 业务含义 | 列名 |
|----------|------|
| 统计日期 | `active_date` |
| 场景 | `scene` |
| 卡片曝光人数 UV | `expo_uv` |
| 卡片点击人数 UV | `click_uv` |
| 卡片点击率 UCTR | `uctr` |

仅在【看板模型】/ 直接取数查询需要中文展示时，用反引号：`AS \`中文列名\``。

**中文别名引号（硬规则，2026-08 confirmed）**：

| 场景 | 写法 | 说明 |
|------|------|------|
| 非建表、直接 `SELECT` 查数 / 看板模型 | `AS \`中文列名\`` | 本集群查询侧不接受双引号别名 |
| 建表 DDL 字段定义 | `` `col` string COMMENT '...' `` | 仍用反引号包英文字段名 |

```sql
-- ✅ 直接取数 / 看板模型
SELECT
    t1.active_date                         AS `活跃日期`
    ,t1.retain_rate                        AS `内容留存率`

-- ❌ 禁止（非建表查询会报错）
SELECT
    t1.active_date                         AS "活跃日期"
```

## 4. GROUP BY：写具体字段名

`GROUP BY` **禁止**写 `1,2,3`，必须写与 SELECT 对齐的具体列名（含表达式别名对应的原表达式或输出列名）。

```sql
-- ✅ 推荐
group by
    custdel_id
    ,showing_date
    ,resblock_id
    ,resblock_name

-- ❌ 不要
group by 1,2,3,4
```

## 5. JOIN

优先 `LEFT JOIN`（以曝光 / 主指标侧为左表）；不要默认用 `FULL OUTER JOIN`。

## 6. 不等于写法与异常值

不要使用不等于运算符，统一用 `NOT IN`。

关联键异常值（JOIN 前，不限字段名）：

```sql
-- ✅ 推荐
and {key} is not null
and {key} not in ('-911','null')

-- ❌ 不要剔 '' / ' '（会滤空）
and {key} not in ('-911','','null',' ')
```

## 7. INSERT 位置

有 CTE 时：`WITH ... )` → `INSERT OVERWRITE TABLE ...` → `SELECT`。  
禁止把 `INSERT` 写在 `WITH` 前面。建表 DDL 规范见 [create-hive-table](../../create-hive-table/SKILL.md)。

**Tez / 建表硬规则**：
- 底表 `INSERT ... SELECT` **禁止 `ORDER BY`**（含 `ORDER BY t1.col`）；Tez 投影后别名失效会报错，见 [create-hive-table](../../create-hive-table/SKILL.md)
- **禁止** `set hive.cte.materialize.threshold=...`（本集群不支持）

## 7.1 流量中间表：site / dp 透传（硬规则）

WHERE 里过滤 `site='beike'` / `dp='app'` 可以；SELECT **不要**把有底表字段的值写死。

| 侧 | SELECT |
|----|--------|
| 行为表 `rpt_log_bi_user_behivor_detail_flow_di` | `t1.dp`、`t1.site` |
| 曝光表 `rpt_comm_log_beike_exp_detail_di` | `t1.dp`；无 site 字段时才 `'beike' AS site` |

```sql
-- ✅
,t1.dp AS dp
,t1.site AS site          -- 行为表
,'beike' AS site          -- 仅曝光表

-- ❌ 行为表 / 曝光表都写死
,'app' AS dp
```

## 8. 首页feed曝光固定写法（2026-08 硬规则）

- **凡算首页 feed 曝光**（UV/PV/PCTR·UCTR 分母），一律 `40400 ∩ 54872`，**禁止**裸用 `40400`
- 先建滑动用户子查询，再对卡片曝光 `INNER JOIN` 取交集
- 滑动 `evt_id='54872'`：优先从中间表 `rpt.rpt_homepage_feed_flow_di`；若扫底表则**只从** `rpt.rpt_log_bi_user_behivor_detail_flow_di` 取
- 去重键：**duid**（内容生态统一）
- 物料维度：滑动用户集合 JOIN 后再按 `item_type`/`card_type` 聚合；结果按 `expo_pv DESC`
- 需要同时输出分场景与整体时，优先 `GROUP BY GROUPING SETS`，不要额外堆叠 overall 子查询

```sql
-- 示例：中间表 + duid（物料 PCTR/UCTR 同构）
with scroll_user as (
    select
        active_date
        ,duid
    from rpt.rpt_homepage_feed_flow_di t1
    where pt = '${-1d_pt}'
      and evt_id = '54872'
      and duid is not null
      and duid not in ('-911','null')
    group by
        active_date
        ,duid
)
,expo as (
    select
        t1.active_date
        ,t1.item_type
        ,t1.card_type
        ,count(1) as expo_pv
        ,count(distinct t1.duid) as expo_uv
    from rpt.rpt_homepage_feed_flow_di t1
    inner join scroll_user t2
      on t1.active_date = t2.active_date
     and t1.duid = t2.duid
    where t1.pt = '${-1d_pt}'
      and t1.evt_id = '40400'
      and t1.duid is not null
      and t1.duid not in ('-911','null')
    group by
        t1.active_date
        ,t1.item_type
        ,t1.card_type
)
```
