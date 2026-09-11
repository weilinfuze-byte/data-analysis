# rpt.rpt_nh_show_house_showing_info_da

> 新房带看明细表。天级全量快照；标准用法：有效带看 + 排除部分创建类型，再经客源表桥到 `ucid`。

## 来自历史 SQL

<!-- as of 2026-08-14, source: http://factory.data.ke.com/detail?table_id=1043771 -->
<!-- as of 2026-07-31, source: 01 商业分析师/ 历史 SQL（with hefang as.sql / Feed细分人群） -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 新房带看明细表 |
| 表类型 | Hive |
| 数据库 | rpt |
| 是否分区 | 是 |
| 分区字段 | `pt`（天级全量快照） |

**说明**：二手带看表 `rpt.rpt_shh_show_showing_housedel_info_da` **不含**新房；新房带看用本表。工厂备注曾指向龚魏昕 / 申艳云。

## 用途

- 新房有效带看用户清单
- 新二带看 UNION（与二手表按 `custdel_id` 对齐后桥 `ucid`）
- 与商机按 **客户+经纪人** 匹配（见 [metrics/commerce.md](../metrics/commerce.md)「商机带看量」）

## 必带过滤

```sql
WHERE pt = '${-1d_pt}'
  AND is_valid = 1                              -- 有效带看
  AND old_showing_create_type NOT IN ('4','5','8')
```

日期窗口过滤 `substr(showing_start_time,1,10)`（`yyyy-MM-dd`），**不要**扫多天 `pt`。

## 核心字段

| 字段 | 类型 | 含义 | 级别 | 备注 |
|------|------|------|------|------|
| showing_id | bigint | 带看 id | **关键** | 去重带看次数 |
| custdel_id | bigint | 中台客源 id | **关键** | JOIN 客源表 |
| agent_ucid | string | 经纪人 UCID | **关键（匹配）** | 商机带看匹配键；JOIN 前 cast bigint |
| showing_start_time | string | 带看开始时间 | **关键** | 取 `substr(...,1,10)` 作带看日 |
| showing_date | string | 带看日期 | 扩展 | 工厂有；标准带看日仍优先 `showing_start_time` |
| is_valid | int | 是否有效带看 | **关键（过滤）** | 0无效/1有效；≠ 二手 `is_showing_valid` |
| old_showing_create_type | int | 源带看生成类型 | **关键（过滤）** | 排除 `4/5/8` |
| pt | string | 分区 | **关键（过滤）** | 必带 |

> 其他：`agent_name` / `channel_ucid`（渠道）/ `operator_id`（操作人）——**勿**当带看经纪人匹配键。

## JOIN 路径

```
rpt.rpt_nh_show_house_showing_info_da.custdel_id
    = dw.dw_cdel_custdel_da.custdel_id
    → customer_uid AS ucid
```

模板：
- [templates/show_ershou_xinfang.md](../templates/show_ershou_xinfang.md)
- [templates/sj_show_matched_daily.md](../templates/sj_show_matched_daily.md)

## 已知坑

- 有效字段是 **`is_valid`**，不要写成二手的 `is_showing_valid`
- 日期字段是 **`showing_start_time`**，不是 `showing_date`
- 必须排除 `old_showing_create_type IN ('4','5','8')`
- 与二手 UNION 时，两边先对齐到 `custdel_id + showing_date`，再统一 LEFT JOIN 客源

## Metrics referencing this table

- [metrics/commerce.md](../metrics/commerce.md)「新二带看」「商机带看量」
