# rpt.rpt_comm_spr_hdel_housedel_info_da

> 房源明细扩展表。天级全量快照，主键 `housedel_id`（B 端房源编码）。

## 来自内部表检索

<!-- as of 2026-07-15, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 房源明细扩展表 |
| 表类型 | Hive |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 是否分区 | 是 |
| 分区字段 | `pt`（天级全量快照） |
| 标签 | 高价值 |

## 用途

- 房源 → 小区 / 商圈 / 城区映射
- 挂牌、户型、状态、贝壳呈现等房源属性
- 与流量房源表 JOIN，做小区级浏览用户分析

## 必带过滤

```sql
WHERE pt = '${-1d_pt}'          -- 全量快照：取窗口末日一天即可，勿扫多天
  AND city_code = 110000        -- int，北京
```

## 核心字段（流量分析常用）

| 字段 | 类型 | 含义 | 备注 |
|------|------|------|------|
| housedel_id | bigint | 房源编码（主键） | JOIN 前 `CAST(... AS string)`；与流量表 **`c_housedel_id`** 关联 |
| house_id | bigint | 房屋编码 | |
| ke_housedel_id | string | 贝壳网房源编码 | 注释：不适用 C→B 转换；一般不用作小区 JOIN 主路径 |
| city_code | int | 城市编码（房源所在城市） | **int**，北京=`110000` |
| city_name | string | 城市名称 | |
| resblock_id | bigint | 楼盘/小区 ID | |
| resblock_name | string | 楼盘/小区名称 | |
| bizcircle_id | bigint | 商圈编码 | |
| bizcircle_name | string | 商圈名称 | |
| district_code | bigint | 城区编码 | |
| district_name | string | 城区名称 | |
| del_type_code | int | 委托类型 | 990001001 买卖 / 990001002 租赁 / 990001007 商业 |
| status_code | int | 房源状态 | |
| listing_price | decimal | 挂牌价格 | |
| floor_area | double | 建筑面积 | |
| room_cnt / parlor_cnt / ... | int | 户型格局 | |
| ke_show_status_code | int | 贝壳呈现状态 | 在售/成交/不呈现 |
| pt | string | 分区 | 必带 |

> 表字段很多（170+），完整字段以数据工厂为准；上表只沉淀流量/小区分析高频字段。

## 与索引里其他房源表的区别

| 表 | 用途 |
|----|------|
| `rpt.rpt_comm_spr_hdel_housedel_info_da`（本表） | 房源明细扩展，含小区/商圈，适合 JOIN 流量 |
| `rpt.rpt_comm_hdel_housedel_info_da` | 索引里的「房源信息」，字段未在本会话核实 |
| `rpt.rpt_comm_log_housedel_info_di` | 流量浏览明细，带核访标记，不是维表 |

## JOIN 路径

```
rpt.rpt_comm_log_housedel_info_di.c_housedel_id
    = CAST(housedel_id AS string)
本表（pt = 窗口末日）
    → resblock_id / resblock_name
```

关联小区用 **`c_housedel_id` ↔ 维表 `housedel_id`**。

## 已知坑

- 全量快照：月窗口只取月末一天 `pt`，扫多天会翻倍
- `housedel_id` 是 bigint，流量表 id 是 string，必须 CAST 对齐
- 同名小区可能有多个 `resblock_id`（不同城区），按名过滤后要用 id 区分
- 本表**没有**核访标记；核访筛选放在流量表 `is_shh_hefang = 1`
- 不要用流量表 `b_housedel_id` 关联本表主键（已确认口径是 `c_housedel_id`）

## Metrics referencing this table

- （暂无沉淀指标）
