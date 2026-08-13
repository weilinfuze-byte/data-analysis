# 商机 / 成交指标

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

- 页面商机对 = **`is_commercial_couple = 1`** + 目标页 **`adid`**
- 溯源商机 = 溯源表（`uicode` / `ele_app_id` + 步长）JOIN 商机明细
- **`is_del` = 转委托**，禁止当成有效商机过滤
- 商机用户键 = **`cust_ucid`**；商机对键 = **`commercial_couple_id`**；表粒度 = **`commercial_id`**
- 成交 / 带看用户键 = **`ucid`**；与 DAU 的 duid 关联时需桥接或明确分析单位
- 二手带看日拼成 `yyyy-MM-dd` 后不要再包 `to_date()`；新房用 `substr(showing_start_time,1,10)`
- 二手有效字段 `is_showing_valid` ≠ 新房有效字段 `is_valid`
- `GROUP BY` 写具体字段名，禁止 `1,2,3`
- 三次握手 ⊆ 商机，按需使用
