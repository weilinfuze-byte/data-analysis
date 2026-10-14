# 内容生态流量中间表 ETL（Locked）

> as of 2026-09-11。底表太大，先落中间表再分析。
> 完整 SQL：`内容生态指标体系/中间表/content_detail_flow.sql`、`search_result_flow.sql`、`content_feed_flow.sql`、`homepage_feed_flow.sql`、`content_ershou_detail_flow.sql`、`content_resblock_detail_flow.sql`
> App 发版 / 新旧 uicode 并行：`docs/app-version-uicode-migration.md`（**禁止**用 `active_date` 切 uicode/evt）

## 通用壳

- 范围：WHERE 过滤 `site=beike`，`dp=app`
- 底表：行为 `rpt_log_bi_user_behivor_detail_flow_di` + 曝光 `rpt_comm_log_beike_exp_detail_di`
- 写法：先 `click_raw` / `expo_raw` 收窄 → 再 `UNION ALL`（内容详情页不限 source；其他中间表按各自模板分流，**禁止** WHERE 嵌套 OR）
- Tez：标准 5 行 set 块；**禁止** `hive.cte.materialize.threshold`
- SELECT 透传：行为表 `t1.dp`/`t1.site`；曝光表 `t1.dp` + `'beike' AS site`；**禁止** `,'app' AS dp`
- 曝光侧：`is_dau` 置 null
- 上线验数：见 [tables/content_detail_flow_di.md](../tables/content_detail_flow_di.md)「验数清单」（搜索/feed 中间表同层思路）

---

## 一、内容详情页 → `rpt.rpt_content_detail_flow_di`

### uicode 全集（raw 收窄）

```sql
lower(uicode) IN (
    'community/shipindetail'   -- 视频
    ,'new_kandian_article'     -- 图文
    ,'hangqing_content_app'     -- 行情
    ,'jiaoyi_gushi'             -- 交易故事
    ,'sunshine_content'         -- 二手日照原生
    ,'usershowing_detail'       -- 相似的人
    ,'csxx_light'               -- 新房日照
    ,'csxx_3ddetailpage'        -- 新房航拍
    ,'lightshadow'              -- 二手日照 H5
    ,'overall'                  -- 二手航拍
    ,'panorama1'                -- 小区漫游
)
```

### 加工规则

- `click_raw` / `expo_raw` 按上表 uicode 收窄后 `UNION ALL` 落表
- **中间表不限** `$.source`；分场景入口过滤见 [tables/content_detail_flow_di.md](../tables/content_detail_flow_di.md)「下游可选 source 限制」
- **不含家装**物料详情页

表说明：[tables/content_detail_flow_di.md](../tables/content_detail_flow_di.md)

---

## 二、搜索结果页 → `rpt.rpt_content_search_result_flow_di`

### raw 收窄

```sql
-- 行为表
lower(uicode) IN (
    'zonghesousuo/jieguo'   -- 首页搜索
    ,'ershousousuo/jieguo'  -- 二手搜索
)
AND evt_id IN ('80327', '93751', '1,3', '1,4')

-- 曝光表
lower(uicode) IN (
    'zonghesousuo/jieguo'
    ,'ershousousuo/jieguo'
)
AND evt_id IN ('80326', '93750')
```

埋点相同，用落表列 `uicode` 区分页面。只要首页搜索的下游加 `lower(uicode) = 'zonghesousuo/jieguo'`。

### UNION 分流规则（内容卡片 + 页览）

| 分支 | evt | tab_name | module_type |
|------|-----|----------|-------------|
| 页览 | 1,3 / 1,4 | — | — |
| 综合-底部竖卡 | 80326/80327 | 综合 | contentFeed |
| 综合-横卡（0806+） | 80326/80327 | 综合 | contentCardModule |
| 内容 tab（0709+） | 80326/80327 | 内容, 评测 | contentFeed |
| 旧横卡（0806 前） | 93750/93751 | 综合 | contentCardModule | 落表固定赋值，action 无 tab/module |

### 落表时从 action 预解析

`content_id` 按 evt_id 区分：80326/80327 用 `$.fb_item_id`，93750/93751 用 `$.content_id`。

**一级分类 `item_type`（2026-10-14）**：先 `$.show_card_type`；空（`NULL` / `''` / `-911` / `null`）时，93750/93751 用 `$.fb_item_type`，其余用 `$.item_type`。`show_card_type` 与搜索 `item_type` 不是同一套枚举。点后推仍用底表 `$.item_type`，不用本表落表列。

落表字段在最终 SELECT 解析（Tez：先 UNION 收窄，再 get_json_object）；过滤条件才在分支 WHERE 解析。

表说明：[tables/content_search_result_flow_di.md](../tables/content_search_result_flow_di.md)

下游横卡 CTR：[templates/search_content_card_ctr.md](search_content_card_ctr.md)

---

## 三、内容 feed → `rpt.rpt_content_feed_flow_di`

### raw 收窄（新旧 uicode 并行，**全部 evt**，不按 active_date 切）

```sql
-- 行为表 / 曝光表：仅 uicode，不限 evt_id
lower(uicode) IN ('new_kandian_homepage', 'content/kandian/recommend')
```

| 版本 | uicode | 常见 evt（非穷举） |
|------|--------|-------------------|
| 新版 | `new_kandian_homepage` | 94408 曝光 / 94409 点击 / 页览等 |
| 旧版 | `content/kandian/recommend` | 68193 曝光 / 68194 点击等 |

### 落表时从 action 预解析（参数表单 key，直接取，无 COALESCE）

| 表字段 | action key |
|--------|------------|
| item_type | `$.fb_item_type`（旧一级，兼容） |
| card_type | `$.card_type` |
| share_media | `$.business_type` |
| action_date | `$.action_date` |
| fb_expo_id | `$.fb_expo_id` |
| content_id | `$.article_id` |
| content_tag | `$.content_title` |
| beike_id | `$.beike_id` |
| agent_ucid | `$.agent_ucid` |
| **show_card_type** | `$.show_card_type`（**一级分类现行**；表尾追加） |

- 下游一级维优先 `show_card_type`，空则 `item_type`
- 已建表：`ALTER TABLE ... ADD COLUMNS (show_card_type ...)`，禁止删字段/改顺序

表说明：[tables/content_feed_flow_di.md](../tables/content_feed_flow_di.md)

---

## 四、首页feed → `rpt.rpt_homepage_feed_flow_di`

### raw 收窄

```sql
-- 行为表
lower(uicode) = 'homepage1'
AND evt_id IN ('40397', '54872')   -- 点击 + 滑动

-- 曝光表
lower(uicode) = 'homepage1'
AND evt_id = '40400'
```

| 事件 | evt_id | 说明 |
|------|--------|------|
| 卡片曝光 | 40400 | 曝光表 |
| 卡片点击 | 40397 | 行为表 |
| 滑动曝光 | 54872 | 行为表；**只从行为表取** |

- **全部卡片**，不限 `card_type`
- 中间表落原始事件；下游算曝光必须 `40400 ∩ 54872`（去重键 **duid**）

### 落表 action 预解析（首页 key，≠ 搜索结果页）

| 表字段 | action key | 说明 |
|--------|------------|------|
| item_type | `$.fb_item_type` | 原一级分类，兼容保留 |
| card_type | `$.card_type` | 二级分类 |
| share_media | `$.type` | |
| action_date | `$.action_date` | |
| fb_expo_id | `$.fb_expo_id` | |
| content_id | `$.content_id` | |
| content_tag | `$.content_tag` | 2026-09-11 修正；旧版误用 `$.content_title`；未重刷分区仍可能是旧语义 |
| beike_id | `$.beike_id` | |
| agent_ucid | `$.agent_ucid` | |
| **show_card_type** | `$.show_card_type` | **一级分类（现行）**；追加表尾 |
| **tab_id** | `$.tab_id` | tab名称；追加在 `show_card_type` 之后 |

- 已建表：`ALTER TABLE ... ADD COLUMNS (...)`，禁止删字段/改顺序；若已有 `show_card_type` 则只 ADD `tab_id`
- 下游一级维度用 `show_card_type`，勿再用 `item_type`；按 tab 用 `tab_id`（主分析默认 **`tab_id = '推荐'`**）
- **下游分析**（周报 / 物料 CTR 等）：直接用表列，禁止 `nvl(表字段, get_json_object(action,'$.xxx'))`；`show_card_type`/`tab_id` 等字段以已回刷分区为准，见 [sql-style.md](../docs/sql-style.md) §9。**`content_tag` key 变更（2026-09-11）**：仅已重刷分区为 `$.content_tag`；未重刷分区（如 7/8 月）可能仍是旧 `content_title` 语义
- AB / 内容占比实验：`$.fb_combine_ab_test_id` 完整值 `IN (...)`，禁止 LIKE；**桶列表每次向用户确认**，见 [dimensions.md](../dimensions.md)

表说明：[tables/homepage_feed_flow_di.md](../tables/homepage_feed_flow_di.md)  
物料 CTR：[templates/homepage_feed_material_ctr.md](homepage_feed_material_ctr.md)

---

## 五、二手房源详情页内容 → `rpt.rpt_content_ershou_detail_flow_di`

### raw 收窄

```sql
-- 行为表
lower(uicode) = 'ershou/detail'
AND evt_id IN ('80580', '87222')   -- 头部点击 / 底部点击

-- 曝光表
lower(uicode) = 'ershou/detail'
AND evt_id IN ('80579', '87223')   -- 头部曝光 / 底部曝光
```

### UNION 分流规则

| 模块 | 曝光 | 点击 | action 过滤 |
|------|------|------|-------------|
| 头部推荐 | `80579` | `80580` | `$.source_type` ∈ 探房 / 业主vlog / 房源视频 / 业主讲房 / 视频 |
| 底部推荐 | `87223` | `87222` | **剔除** `from×card_type`：二手×房源卡片、新房×新房楼盘、新房×土拍 |

底部**禁止**再用 `card_type` 白名单（会漏小区点评、行情卡等）。`from` 取值：`内容` / `二手` / `新房`。

### 落表 action 预解析

| 表字段 | action key |
|--------|------------|
| source_type | `$.source_type` |
| from_val | `$.from` |
| card_type | `$.card_type` |
| housedel_id | `$.housedel_id` |

表说明：[tables/content_ershou_detail_flow_di.md](../tables/content_ershou_detail_flow_di.md)

---

## 六、小区详情页 → `rpt.rpt_content_resblock_detail_flow_di`

### raw 收窄

```sql
-- 行为表
lower(uicode) = 'communitydetailv2'
AND evt_id IN ('28738', '82884')

-- 曝光表
lower(uicode) = 'communitydetailv2'
AND evt_id IN ('28737', '82883')
```

### UNION 分流规则

| 模块 | 曝光 | 点击 | action 过滤 |
|------|------|------|-------------|
| 头部推荐 | `28737` | `28738` | `$.source_type` ∈ 视频 / 街访 / 解读 / 探房 |
| 底部推荐 | `82883` | `82884` | **剔除** `$.card_type` ∈ `xinfang_project_name` / `ershou_house` / `resblock` / `resblock_rankinglist` |

落表预解析：`source_type`←`$.source_type`，`card_type`←`$.card_type`。

表说明：[tables/content_resblock_detail_flow_di.md](../tables/content_resblock_detail_flow_di.md)

---

## 七、分发场景（其它仍从底表取）

| 场景 | uicode | 曝光 evt | 点击 evt | action 限制 |
|------|--------|----------|----------|-------------|
| 首页feed | homepage1 | **40400 ∩ 54872** | 40397 | 见第四节中间表；内容卡用 `card_type` **剔除法**（见 [homepage_feed_content_card_filter.md](../docs/homepage_feed_content_card_filter.md)） |
| 二手详情推荐 | ershou/detail | 80579, 87223 | 80580, 87222 | 见第五节中间表 |
| 小区详情推荐 | communitydetailv2 | 28737, 82883 | 28738, 82884 | 见第六节中间表 |

已建中间表：内容详情页 / 搜索结果页 / 内容 feed / 首页 feed / **二手详情内容** / 小区详情页。

首页 feed（硬规则）：凡算曝光必须 `40400 ∩ 54872`；去重键 **duid**；禁止裸用 40400。

详见 [events/beike_evt_id.md](../events/beike_evt_id.md)、[docs/sql-style.md](../docs/sql-style.md) §8。
