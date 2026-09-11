# 商机 / 成交指标

### 内容商机（三类 · 中间表优先）

> as of 2026-09-11, source: 北京内容商机分大部

- **底表**：`rpt.rpt_content_sj_trans_detail_da`（已打标 `content_sj_type`）
- **禁止**再对 `rpt_asm_sj_trans_detail_da` 自己 UNION 展位 / 溯源 / 保护
- 表结构：[tables/content_sj_trans_detail_da.md](../tables/content_sj_trans_detail_da.md)
- 模板：[templates/content_sj_from_intermediate.md](../templates/content_sj_from_intermediate.md)
- 公共过滤：**不限** `website_name` / `client_name`（原仅贝壳 App，2026-09-11 已放开）

| 类型 | `content_sj_type` | 识别（中间表已做） |
|------|-------------------|-------------------|
| 展位 | `booth` | 内容详情页 adid 展位 |
| 溯源 | `trace` | **并集**：落地页上报 `app_id`/`ele_app_id`（`BU_PingTai_*`）**或** 详情页 `uicode`（图文/视频）；**不限 `distance`**；两口径重叠≈0，禁止互相替换 |
| 保护 | `protect` | `digv_b` 内容直播保护策略 |

**打标 ≠ 归因**（Locked）：

| 用途 | 要不要 `parent_scene_id` |
|------|--------------------------|
| 算不算内容商机（写类型） | **不要**。adid / 溯源 / 保护命中即计入 |
| 按内容 / 生产人拆 | **要**。商机 `parent_scene_id` = 详情页 `scene_id` → 解析 `content_id` |

**计数**（Locked）：

| 场景 | 写法 |
|------|------|
| 分类型 | 各自 `COUNT(DISTINCT commercial_couple_id)`，**允许重叠** |
| 总量 | 不分类型，`COUNT(DISTINCT commercial_couple_id)` 跨类型去重 |
| 禁止 | 把三类数字相加当总量（相加可以大于总量） |

打标 / JOIN 用 **`commercial_id`**；出商机量用 **`commercial_couple_id`**。

**da 快照**：`pt = '${-1d_pt}'`（最新全量）。昨天商机加 `occur_date = 昨天`；历史商机（带看/成交匹配）加 `occur_date <= 昨天`。**禁止**对 da 表写 `pt <=`。

带看 / 成交仍走下方「商机带看量 / 商机成交量」人店匹配，商机侧换成内容中间表即可。

### 页面商机（按 adid）

- 表：`rpt.rpt_asm_sj_trans_detail_da`
- **adid** = 广告位 ID（工厂）；页面商机 = 该页 adid 列表（业务上常称展位）
- 过滤：`business_name` + `is_commercial_couple = 1` + `adid IN (...)`
- UV：`COUNT(DISTINCT cust_ucid)`；PV：`COUNT(DISTINCT commercial_couple_id)`
- 模板：[templates/page_sj_by_adid.md](../templates/page_sj_by_adid.md)
- 表结构：[tables/asm_sj_trans_detail_da.md](../tables/asm_sj_trans_detail_da.md)

### 溯源商机（页面 uicode / 元素 ele_app_id）

- **含义**：访问过某页面 / 点过某按钮后，在后续路径上产生的商机（≠ 页面 adid 当场商机）
- 溯源表：`shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di`
- 归因：页面 → `uicode`；元素/按钮 → `ele_app_id`
- **`distance` = 步长**：当前页面为第 1 步，后续几个页面内（几步内）产生的商机；类型为 string，**不要 cast**
- 关联：溯源表 `commercial_id` = 商机明细 `commercial_id`，再滤 `is_commercial_couple = 1`
- UV / PV：`duid` / `commercial_couple_id`
- 模板：[templates/sj_attribution_by_scene.md](../templates/sj_attribution_by_scene.md)
- 表结构：[tables/commerce_scene_calculate_distance_di.md](../tables/commerce_scene_calculate_distance_di.md)

### 首页feed 内容点击归因商机（2026-09 confirmed）

> 项目 SQL：`首页feed指标表/homepage_feed_content_click_sj_detail_di.sql` / `*_result_di.sql`

| 项 | 口径 |
|----|------|
| 关联顺序 | 商机表 → 溯源（`BU_HomePageFeedAPI`）→ 行为点击 `40397` |
| 行为 | **全量**卡片点击（不限内容卡）；未点到的不计入 |
| 是否内容 | 按点击卡片剔除法打标 `is_content`（表末字段） |
| 溯源场景 | `app_id` 或 `ele_app_id` = `BU_HomePageFeedAPI`；`distance` 保留，明细/结果默认不限步长 |
| 关联键 | 商机↔溯源：`commercial_id`+同日；溯源↔行为：`fb_expo_id`+同日（**不挂 duid**） |
| 溯源 expo 解析 | 优先 `ele_param.$.fbexpo` / `$.fb_expo_id`；否则 map `{"r…":"r…"}` 取首个引号串且 `LIKE 'r%'` |
| 商机日 | `occur_date` = 行为日（当天） |
| 中间表明细 | 可不限 `business_name` / `is_commercial_couple` / website / client（结果表再滤） |

≠ 内容商机三类中间表（展位/溯源/保护打标）；本口径是 **首页 feed 点击路径归因**。

### 三次握手商机（可选子集）

- 商机全集 ⊇ 三次握手商机；**不需要质量过滤时不算**
- 线索表：`dw.dw_log_commerce_stream_clue_inf_di`，`data_lables = '["1002"]'`
- 关联：商机 `split(source_key_id,':')[0]` = 线索 `split(source_pk,':')[0]`
- 指标：握手 UV / 握手 PV；握手率 = 握手 PV ÷ 商机 PV

### 转委托 / 转带看 / 转成交

- 表同商机明细；工厂字段：
  - `is_del = 1` → **是否转委托**（不是「有效商机」）
  - `is_show = 1` → 是否转带看
  - `is_deal = 1` → 是否转成交
- 无效商机：`is_invalid`（`1`无效 / `0`非无效 / `-911`未知）
- 示例 SQL：`01 经纪业务/09 二手/20241108 房源详情页改版/转委托.sql`
- **≠ 下方「商机带看量 / 商机成交量」**：工厂 `is_show` / `is_deal` 为商机表内置转化标记；自定义指标为人店+时序 JOIN，**禁止混用**

### 商机带看量（人店匹配 · 按带看日）

- **含义**：历史商机对中，统计窗内有效带看与客户+经纪人对齐，且带看日 ≥ 商机日的商机对个数
- **计数**：`COUNT(DISTINCT commercial_couple_id)`
- **日维度**：带看发生日 `showing_date`（非商机日）
- **输出**：带看日 × 业务线（二手/新房）× 商机带看量
- **商机侧**：`rpt.rpt_asm_sj_trans_detail_da`，`is_commercial_couple = 1`；历史不限起点，`occur_date <= 带看窗末日`
- **匹配（硬）**：
  1. 商机 `cust_ucid` = 带看用户 `ucid`
  2. 商机 `agent_ucid` = 带看经纪人 ucid
  3. 带看日 **`>=`** 商机日（当天算）
  4. 一带看对多条历史商机对 → **全部挂上**
- **带看侧 · 二手** `rpt.rpt_shh_show_showing_housedel_info_da`：买卖 + `is_showing_valid = 1`；用户经客源桥；经纪人 **`showagent_ucid`**
- **带看侧 · 新房** `rpt.rpt_nh_show_house_showing_info_da`：`is_valid = 1` + 排除创建类型 4/5/8；用户经客源桥；经纪人 **`agent_ucid`**（string → bigint）
- 模板：[templates/sj_show_matched_daily.md](../templates/sj_show_matched_daily.md)
- 项目 SQL：`商机带看成交量/sj_show_daily.sql`

### 商机成交量（人店匹配 · 按成交日）

- **含义**：历史商机对中，统计窗内有效成交与客户+经纪人对齐，且成交日 ≥ 商机日的商机对个数
- **计数**：`COUNT(DISTINCT commercial_couple_id)`
- **日维度**：成交发生日（二手 `sign_time` / 新房 `order_time` 认购日）
- **输出**：成交日 × 业务线（二手/新房）× 商机成交量
- **商机侧**：同「商机带看量」
- **匹配（硬）**：同「商机带看量」（成交日 **`>=`** 商机日；一成交挂多条商机对）
- **成交侧 · 二手** `rpt.rpt_shh_rent_deal_agreement_detail_da`：Locked 新二买卖成交过滤；用户 **`cust_ucid`**；经纪人 **`sign_ucid`（签约人）**；成交日 `substr(sign_time,1,10)`；暂未滤 `is_revoke`
- **成交侧 · 新房** `rpt.rpt_nh_output_deal_info_online_custdel_da`：非外渠 + 非测试城 + `is_cancel = 0`；用户经客源桥；经纪人 **`agent_ucid`（主经纪人）**；成交日 `substr(order_time,1,10)`
- 模板：[templates/sj_deal_matched_daily.md](../templates/sj_deal_matched_daily.md)
- 项目 SQL：`商机带看成交量/sj_deal_daily.sql`

### 商机带看/成交 · 经纪人字段对照（硬）

| 侧 | 二手带看 | 新房带看 | 二手成交 | 新房成交 |
|----|----------|----------|----------|----------|
| 商机经纪人 | `agent_ucid` | `agent_ucid` | `agent_ucid` | `agent_ucid` |
| 事实经纪人 | `showagent_ucid` | `agent_ucid` | `sign_ucid` | `agent_ucid` |
| 用户键 | 客源 `customer_uid` | 客源 `customer_uid` | `cust_ucid` | 客源 `customer_uid` |

- 二手成交**无** `agent_ucid` 字段；勿用 `create_ucid` / `accompany_sign_ucid`
- 新房带看/成交 `agent_ucid` 为 string，JOIN 前 cast

### 新二带看（有效带看用户日清单）

- 输出粒度：`ucid + type(二手/新房) + showing_date`
- 去重键：`ucid`
- 客源：`dw.dw_cdel_custdel_da`（`custdel_id → customer_uid`）
- 二手：`rpt.rpt_shh_show_showing_housedel_info_da`
  - 过滤：`del_type_code = '990001001'` + `is_showing_valid = 1` + `pt = '${-1d_pt}'`
  - 带看日：`showing_date`（`yyyyMMdd`）→ 拼成 `yyyy-MM-dd` 字符串，**不要** `to_date()`
  - 明细扩展（可选）：`showing_id` / `housedel_id` / `resblock_id` / `city_code`
- 新房：`rpt.rpt_nh_show_house_showing_info_da`
  - 过滤：`is_valid = 1` + `old_showing_create_type NOT IN ('4','5','8')` + `pt = '${-1d_pt}'`
  - 带看日：`substr(showing_start_time,1,10)`
- 模板：[templates/show_ershou_xinfang.md](../templates/show_ershou_xinfang.md)
- 表结构：
  - [tables/shh_show_showing_housedel_info_da.md](../tables/shh_show_showing_housedel_info_da.md)
  - [tables/nh_show_house_showing_info_da.md](../tables/nh_show_house_showing_info_da.md)
  - [tables/cdel_custdel_da.md](../tables/cdel_custdel_da.md)

### 新二成交用户日清单

- 输出粒度：`ucid + type(二手/新房) + sign_date`
- 去重键：`ucid`
- 二手：`rpt.rpt_shh_rent_deal_agreement_detail_da`
  - 过滤：主协议 + 合同 + 已提交 + 签约/过户/完结 + `del_type_name = '买卖'`
  - 用户键：直接 `cust_ucid`；签约日：`substr(sign_time,1,10)`
- 新房：`rpt.rpt_nh_output_deal_info_online_custdel_da`
  - 过滤：`brand_name <> '外渠房江湖'` + 非测试城 + `is_cancel = 0`
  - 用户键：`custdel_id` → `dw.dw_cdel_custdel_da.customer_uid`
  - 签约日：`substr(order_time,1,10)`（认购时间）
- 模板：[templates/deal_ershou_xinfang.md](../templates/deal_ershou_xinfang.md)
- 表结构：
  - [tables/shh_rent_deal_agreement_detail_da.md](../tables/shh_rent_deal_agreement_detail_da.md)
  - [tables/nh_output_deal_info_online_custdel_da.md](../tables/nh_output_deal_info_online_custdel_da.md)
  - [tables/cdel_custdel_da.md](../tables/cdel_custdel_da.md)

### 二手成交（房源侧）

- 表：`rpt.rpt_shh_deal_agreement_da`
- 常见于成交房源 / 带看储备分析（键多用 `housedel_id`）
- 状态过滤与主协议口径同新二清单二手分支

### 租赁成交

- 表：`rpt.rpt_shh_rent_deal_agreement_detail_da`（同表，换租赁 `del_type`）

## 硬规则

- 内容商机优先扫 **`rpt_content_sj_trans_detail_da`**；打标不要求 `parent_scene_id`；分类型可重叠、总量跨类型去重
- 首页feed **内容点击归因商机** ≠ 内容商机三类打标；关联键用 `fb_expo_id`（不挂 duid），行为侧全量 40397
- 页面商机对 = **`is_commercial_couple = 1`** + 目标页 **`adid`**
- 溯源商机 = 溯源表（`uicode` / `ele_app_id` + 步长）JOIN 商机明细
- **`is_del` = 转委托**，禁止当成有效商机过滤
- **商机带看量 / 商机成交量**（人店匹配）≠ 工厂 **`is_show` / `is_deal`**；写 SQL 前先确认用哪套
- 商机带看/成交匹配：客户+经纪人+时序 `>=`；计数 `commercial_couple_id`；一带看/成交可挂多条商机对
- 商机用户键 = **`cust_ucid`**；商机对键 = **`commercial_couple_id`**；表粒度 = **`commercial_id`**
- 成交 / 带看用户键 = **`ucid`**；与 DAU 的 duid 关联时需桥接或明确分析单位
- 二手带看日拼成 `yyyy-MM-dd` 后不要再包 `to_date()`；新房用 `substr(showing_start_time,1,10)`
- 二手有效字段 `is_showing_valid` ≠ 新房有效字段 `is_valid`
- `GROUP BY` 写具体字段名，禁止 `1,2,3`
- 三次握手 ⊆ 商机，按需使用
