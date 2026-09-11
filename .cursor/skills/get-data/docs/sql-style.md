# SQL 书写规范

> 杨富泽个人 Hive SQL 风格。写取数 / 看板 SQL 时必须遵守。

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

## 2.2 字段类型：禁止擅自 cast（硬规则，2026-09-11 confirmed）

**不要**为了「保险」改字段格式（`cast(col AS string/bigint/…)`、`string(col)` 等），**除非用户明确要求**。

| 做法 | 对 / 错 |
|------|---------|
| 按字典类型写字面量 | ✅ `city_id = '110000'`（string）；`city_code = 110000`（int/bigint） |
| 字典已是 string 再 `cast(city_id AS string)` | ❌ |
| 字典已是 bigint 再 `cast(content_id AS string)` 再和字面量比 | ❌（除非用户要求） |
| JOIN / 异常值过滤 | ✅ 用字段原生类型；`bigint` 剔 `-911`，不要先转 string 再剔 `'null'` |

跨表 JOIN 两侧类型确不一致时：优先让 **解析结果 / 字面量** 对齐表字段字典类型；确需 `cast` 时只转非表字段侧（如 `get_json_object` 结果），并加一行注释说明原因。

**例外（用户已确认）**：主理人分发等场景对供给表 `rpt.rpt_feed_content_analyze_table.city_id` 写 `cast(city_id AS string) = '110000'`；其它字段仍禁止擅自 cast。见 [curator_distribution_daily.md](../templates/curator_distribution_daily.md)。

## 2.3 注释（硬规则，2026-09-11 confirmed）

工厂 / 查询侧 **禁止** 用 `=` 或 `-` 画分隔线当注释，会报错：

```sql
-- ❌ 禁止
-- ============================================================
-- ========== 曝光 ==========
-- ------------------------------------------------------------
```

只用普通说明注释：

```sql
-- ✅
-- Project: 主理人内容 · 分发日指标
-- 内容feed · 曝光
```

## 3. 结果列名

看板底表 / 中间查询结果列用英文蛇形命名，例如：

| 业务含义 | 列名 |
|----------|------|
| 统计日期 | `active_date` |
| 场景 | `scene` |
| 卡片曝光人数 UV | `expo_uv` |
| 卡片点击人数 UV | `click_uv` |
| 卡片点击率 UCTR | `uctr` |

仅在需要中文展示时给列加中文别名；**看板模型与直接查数引号不同**。

**中文别名引号（硬规则，2026-09-03 修正）**：

| 场景 | 写法 | 说明 |
|------|------|------|
| 【看板模型】（BI/QE 挂载） | `AS "中文列名"` | QE 报错：`backquoted identifiers are not supported; use double quotes` |
| 非建表、工厂/查询侧直接 `SELECT` 查数 | `AS \`中文列名\`` | 查询侧不接受双引号别名 |
| 建表 DDL 字段定义 | `` `col` string COMMENT '...' `` | 仍用反引号包英文字段名 |

```sql
-- ✅ 看板模型
SELECT
    t1.active_date                         AS "活跃日期"
    ,t1.retain_rate                        AS "内容留存率"

-- ✅ 直接取数（非看板）
SELECT
    t1.active_date                         AS `活跃日期`
    ,t1.retain_rate                        AS `内容留存率`
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
- **PV（推荐场景硬规则）**：`COUNT(DISTINCT concat(nvl(fb_expo_id,''),'#',duid))`，**禁止** `count(1)`
- 物料维度：滑动用户集合 JOIN 后再按 `show_card_type`/`card_type` 聚合；结果按 `expo_pv DESC`；一级分类**勿用** `item_type`
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
        ,t1.show_card_type
        ,t1.card_type
        ,count(DISTINCT concat(nvl(t1.fb_expo_id, ''), '#', t1.duid)) as expo_pv
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
        ,t1.show_card_type
        ,t1.card_type
)
```

## 9. 中间表预解析字段：直接用表列（2026-08 硬规则）

内容生态流量中间表（`rpt.rpt_*_flow_di`）在 ETL 阶段已从 `action` 预解析并落表；**全量分区已回刷**。下游分析 / 周报 / 物料 CTR **只读表字段**。

```sql
-- ✅ 中间表：直接用落表列
and t1.tab_id = '推荐'
and t1.show_card_type = '内容'
and t1.card_type = '买房故事'
and t1.tab_name = '综合'
and t1.module_type = 'contentCardModule'

-- ❌ 禁止：nvl + get_json_object 兜底（历史过渡写法，已废弃）
and nvl(t1.tab_id, get_json_object(t1.action, '$.tab_id')) = '推荐'
and nvl(t1.show_card_type, get_json_object(t1.action, '$.show_card_type')) = '内容'

-- ❌ 禁止：中间表对已落表字段再 get_json_object
and get_json_object(t1.action, '$.tab_id') = '推荐'
```

| 场景 | 写法 |
|------|------|
| 扫中间表 `rpt_*_flow_di` | 用表字段（`tab_id`、`show_card_type`、`card_type`、`fb_expo_id`、`content_id`、`tab_name`、`module_type` 等，以各表字典为准） |
| 扫底表且字段未落表 | `get_json_object(action, '$.xxx')` |
| `action` 中未预解析的字段 | 按表字典；必要时仍 `get_json_object` |

参考：[templates/search_content_card_ctr.md](../templates/search_content_card_ctr.md)「中间表字段已预解析」；首页 feed 见 [tables/homepage_feed_flow_di.md](../tables/homepage_feed_flow_di.md)。
