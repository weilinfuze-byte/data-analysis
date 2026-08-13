# 核访指标

> as of 2026-07-31；与用户确认口径后沉淀。
>
> **核访 ≠ 带看**。核访是线上浏览带核访标记的房源/楼盘；带看是线下看房（见 [commerce.md](commerce.md) 新二带看）。

## 总览

| 业务线 | 行为明细表字段 | 房源浏览表明细字段 | 对象标识 |
|--------|----------------|--------------------|----------|
| 新房 | `is_xingfang_hefang = 1` | `is_nh_hefang = 1` | `project_name`（楼盘） |
| 二手 | `is_ershou_hefang = 1` | `is_shh_hefang = 1` | `housedel_id`（房源） |

**主表（推荐）**：`rpt.rpt_log_bi_user_behivor_detail_flow_di`  
**备选表**：`rpt.rpt_comm_log_housedel_info_di`（已带房源 id + 核访标记；只覆盖「被浏览过」的核访房源）

默认站点/端未指定时需询问；已确认场景示例：`site = 'beike'` + `dp = 'app'`。

---

## 新房核访

- **含义**：用户浏览了带「核访」标记的新房楼盘（通常为楼盘详情相关行为）
- **主表**：`rpt.rpt_log_bi_user_behivor_detail_flow_di`
- **核心过滤**：`is_xingfang_hefang = 1`
- **楼盘标识**：`get_json_object(action, '$.project_name')`
- **备选**：`rpt.rpt_comm_log_housedel_info_di` + `is_nh_hefang = 1`

### 次数口径（需选用）

| 选项 | 定义 | 说明 |
|------|------|------|
| **A. PV 次数（默认已确认）** | `is_xingfang_hefang = 1` 的行为行数 | 字面「核访次数」 |
| B. 去重楼盘数 | `count(distinct project_name)` | 看了几个盘 |
| C. 是否核访 | 当日有无核访（0/1） | 活跃日，不是次数 |

### 不要混淆

| 易混口径 | 是什么 | 为何不是通用核访 |
|----------|--------|------------------|
| 新房有效带看 | `rpt.rpt_nh_show_house_showing_info_da` | 线下带看 |
| 首页宽口径/直接核访 | 首页后进入 `newhouse/project/detail/v4` | 首页漏斗归因，不是通用核访标记 |

---

## 二手核访

- **含义**：用户浏览了带「核访」标记的二手房源
- **主表**：`rpt.rpt_log_bi_user_behivor_detail_flow_di`
- **核心过滤**：`is_ershou_hefang = 1`
- **房源标识**：`get_json_object(action, '$.housedel_id')`（常见配合 `uicode = 'ershou/detail'`）
- **备选**：`rpt.rpt_comm_log_housedel_info_di` + `is_shh_hefang = 1`

### 次数口径（与新房对称）

| 选项 | 定义 | 说明 |
|------|------|------|
| **A. PV 次数** | `is_ershou_hefang = 1` 的行为行数 | 字面「核访次数」 |
| B. 去重房源数 | `count(distinct housedel_id)` | 看了几套房 |
| C. 是否核访 | 当日有无核访（0/1） | 活跃日，不是次数 |

### 不要混淆

| 易混口径 | 是什么 | 为何不是通用核访 |
|----------|--------|------------------|
| 二手有效带看 | `rpt.rpt_shh_show_showing_housedel_info_da` + `is_showing_valid = 1` | 线下带看 |
| Feed 局部别名 | 推荐 SQL 里用 `card_type = '房源卡片'` 自造 `is_ershou_hefang` | **不是**行为明细表上的核访标记字段 |

---

## 标准过滤块（贝壳 App）

```sql
FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
WHERE t1.pt = '${-1d_pt}'
    AND t1.site = 'beike'
    AND t1.dp = 'app'
    AND t1.is_xingfang_hefang = 1   -- 新房；二手改 is_ershou_hefang = 1
```

人数去重用 `ucid`（成交/画像场景）或 `duid`（DAU/流量场景）；去重 / 关联前剔异常值：`is not null` + `not in ('-911','null')`（禁止剔 `''` / `' '`）。

## 关联表

| 表 | 用途 | Detail |
|----|------|--------|
| `rpt.rpt_log_bi_user_behivor_detail_flow_di` | 核访主表 | [tables/behavior_flow_di.md](../tables/behavior_flow_di.md) |
| `rpt.rpt_comm_log_housedel_info_di` | 房源浏览 + 核访标记备选 | [tables/comm_log_housedel_info_di.md](../tables/comm_log_housedel_info_di.md) |
