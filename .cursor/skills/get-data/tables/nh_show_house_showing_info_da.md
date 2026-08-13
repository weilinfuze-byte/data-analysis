# rpt.rpt_nh_show_house_showing_info_da

> 新房带看明细表。天级全量快照；标准用法：有效带看 + 排除部分创建类型，再经客源表桥到 `ucid`。

## 来自历史 SQL

<!-- as of 2026-07-31, source: 01 商业分析师/ 历史 SQL（with hefang as.sql / Feed细分人群）；待 factory.data.ke.com 复核字段类型与权限包 -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 新房带看（待工厂确认正式中文名） |
| 表类型 | Hive |
| 数据库 | rpt |
| 是否分区 | 是 |
| 分区字段 | `pt`（天级全量快照） |

**说明**：二手带看表 `rpt.rpt_shh_show_showing_housedel_info_da` **不含**新房；新房带看用本表。工厂备注曾指向龚魏昕 / 申艳云。

## 用途

- 新房有效带看用户清单
- 新二带看 UNION（与二手表按 `custdel_id` 对齐后桥 `ucid`）
- 与商机、成交按 `ucid` 关联

## 必带过滤

```sql
WHERE pt = '${-1d_pt}'
  AND is_valid = 1                              -- 有效带看
  AND old_showing_create_type NOT IN ('4','5','8')
```

日期窗口过滤 `substr(showing_start_time,1,10)`（`yyyy-MM-dd`），**不要**扫多天 `pt`。

## 核心字段

| 字段 | 类型（待复核） | 含义 | 级别 | 备注 |
|------|----------------|------|------|------|
| custdel_id | — | 客源编码 | **关键** | JOIN 客源表 |
| showing_start_time | — | 带看开始时间 | **关键** | 取 `substr(...,1,10)` 作带看日 |
| is_valid | — | 是否有效带看 | **关键（过滤）** | 新房侧标准有效过滤；≠ 二手的 `is_showing_valid` |
| old_showing_create_type | — | 带看创建类型 | **关键（过滤）** | 排除 `'4','5','8'` |
| pt | string | 分区 | **关键（过滤）** | 必带 |

> 明细扩展字段（`showing_id` / 楼盘等）以工厂字段页为准，未在本字典沉淀前勿凭记忆写入 Locked 模板。

## JOIN 路径

```
rpt.rpt_nh_show_house_showing_info_da.custdel_id
    = dw.dw_cdel_custdel_da.custdel_id
    → customer_uid AS ucid
```

模板：[templates/show_ershou_xinfang.md](../templates/show_ershou_xinfang.md)

## 已知坑

- 有效字段是 **`is_valid`**，不要写成二手的 `is_showing_valid`
- 日期字段是 **`showing_start_time`**，不是 `showing_date`
- 必须排除 `old_showing_create_type IN ('4','5','8')`
- 与二手 UNION 时，两边先对齐到 `custdel_id + showing_date`，再统一 LEFT JOIN 客源

## Metrics referencing this table

- [metrics/commerce.md](../metrics/commerce.md)「新二带看」
