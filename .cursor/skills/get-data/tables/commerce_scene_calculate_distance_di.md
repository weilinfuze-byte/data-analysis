# shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di

> 计算溯源路径长度-关联元素。商机溯源主表。
> table_id=`1223528` · 详情：`http://factory.data.ke.com/detail?table_id=1223528`

## 来自内部表检索

<!-- as of 2026-07-31, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 计算溯源路径长度-关联元素 |
| 表类型 | Hive |
| 集群 | 公共集群 |
| 数据层级 | 基础细节数据 |
| 数据库 | shangyehua |
| 安全等级 | C2 |
| 存储量 | 634.33 GB |
| 是否分区 | 是 |
| 分区字段 | `pt` |
| 生命周期 | 365 天 |
| 数据负责人 | 刘妍(26020419) |
| 业务负责人 | 曹远鹏 |
| 所属空间 | 基础业务平台 |
| 数据最后更新时间 | 2026-07-31 05:43:38 |
| 标签 | M高耗时 |
| 描述 | 计算溯源路径长度 - 页面溯源与元素溯源拓展 |

## 用途

- **溯源商机**：访问过某页面 / 点过某元素后，在后续路径上产生的商机
- 页面溯源：滤 `uicode`
- 元素溯源：滤 `ele_app_id`（按钮/模块）
- 与商机明细按 `commercial_id` 关联

模板：[templates/sj_attribution_by_scene.md](../templates/sj_attribution_by_scene.md)

## 常用过滤

```sql
WHERE pt BETWEEN '{start_pt}' AND '${-1d_pt}'
  AND business_name = '二手'
  AND lower(uicode) IN ('ershou/bangdan')   -- 或 ele_app_id IN (...)
  AND distance BETWEEN 1 AND 3             -- 步长：当前页=第1步
```

## 关键字段

| 字段 | 类型 | 含义 | 用法 |
|------|------|------|------|
| `pt` | string | 分区字段 | 必带 |
| `commercial_id` | string | 商机 ID | 关联 `rpt_asm_sj_trans_detail_da` |
| `distance` | string | 步长 | 当前页面为第1步；几步内产生的商机；**不要强转类型** |
| `uicode` | string | 页面 | 页面溯源 |
| `ele_app_id` | string | 父页面元素应用 id | 元素/按钮溯源 |
| `app_id` | string | 溯源上报场景 | 场景级归因 |
| `ele_uicode` | string | 父页面元素端 uicode | 细拆 |
| `ele_param` | string | 父页面元素随路参数 | 细拆 |
| `ele_parent_scene_id` | string | 父页面元素 id | |
| `duid` | string | 设备 | |
| `business_name` | string | 业务线 | |
| `client_name` | string | 端 | |
| `adid` | string | adid | 表内有；溯源主口径一般用 uicode/ele_app_id |
| `is_del` / `is_show` / `is_deal` | int | 转委托/带看/成交 | 可选 |
| `commercial_scene_id` | string | 商机关联场景 ID | |
| `scene_id` / `parent_scene_id` | string | 场景链路 | |

## 全字段清单（26）

| # | 字段 | 类型 | 含义 |
|---|------|------|------|
| 1 | commercial_scene_id | string | 商机关联场景ID |
| 2 | distance | string | 步长 |
| 3 | scene_id | string | scene_id |
| 4 | parent_scene_id | string | parent_scene_id |
| 5 | app_id | string | 溯源上报场景 |
| 6 | customer | string | customer |
| 7 | param | string | param |
| 8 | revice_time | string | revice_time |
| 9 | seo | string | seo |
| 10 | referer | string | referer |
| 11 | uicode | string | uicode |
| 12 | commercial_id | string | commercial_id |
| 13 | adid | string | adid |
| 14 | duid | string | duid |
| 15 | business_name | string | business_name |
| 16 | client_name | string | client_name |
| 17 | ele_parent_scene_id | string | 父页面元素id |
| 18 | ele_app_id | string | 父页面元素应用id |
| 19 | ele_uicode | string | 父页面元素端uicode |
| 20 | ele_param | string | 父页面元素随路参数 |
| 21 | pt | string | 分区字段 |
| 22 | client_source | string | client_source |
| 23 | client_version | string | client_version |
| 24 | is_del | int | 是否转委托 |
| 25 | is_show | int | 是否转带看 |
| 26 | is_deal | int | 是否转成交 |

## 同系列表（勿混用）

| 表 | 中文名 | 说明 |
|----|--------|------|
| `shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di` | 计算溯源路径长度-关联元素 | **常用**，含 ele_* |
| `shangyehua.shangyehua_commerce_scene_calculate_distance_di` | 计算溯源路径长度 | 无「关联元素」扩展 |
| `reco_data_center.reco_data_center_commerce_scene_calculate_distance_di` | 商机溯源 | 另一套，历史少用 |

## 已知坑

- `distance` 工厂类型为 **string**，过滤写 `distance BETWEEN 1 AND 3` 即可，**不要** `cast(... AS int)`
- 溯源商机必须再 JOIN 商机明细并带 `is_commercial_couple = 1`，不能只在溯源表上 count
- 与「页面 adid 商机」是两套口径，勿混称
