# rpt.rpt_shh_show_showing_housedel_info_da

> 二手带看明细表。天级全量快照；标准用法：买卖 + 有效带看，再经客源表桥到 `ucid`。

## 来自内部表检索

<!-- as of 2026-07-31, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 二手带看明细表 |
| 表类型 | Hive |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 集群 | 公共集群 |
| 安全等级 | C2 |
| 存储量 | ~28 TB |
| 是否分区 | 是 |
| 分区字段 | `pt`（天级全量快照） |
| 数据负责人 | 王云娜(30995132) |
| 业务负责人 | 王紫星 |
| 所属空间 | 数据应用开发团队 |
| 权限包 | 通用 |
| 标签 | 高价值、行级权限、M带看专题、M大存储、M高热度、任务/天 |
| 数据最后更新 | 2026-07-31 05:15:00 |

**描述摘要**：人店集市输出明细；含二手与租赁带看；超过三天审核通过的带看为违规、带看状态无效；新房数据不在本表。分区范围约 2021-06-29 至今；2021-03-16 前房源信息可能不全。

## 权限

### 审批流程

数据查询 / 离线开发 / 数据交换 / 跨集群同步 → **零售通用审批流**（模板配置）。

### 行级权限（重要）

| 模板 | 系统函数 | 映射字段 |
|------|----------|----------|
| 品牌权限=全部模版 | `brand_code()` | `showagent_brand_code` |
| 通用城市模版 | `city_code()` | `city_code` |

Adhoc 会被城市/品牌裁剪；跨城分析前先确认权限包。

## 用途

- 二手有效带看用户 / 小区清单（新二模板中的**二手**分支）
- 与商机、成交按 `ucid` 关联（需客源桥）
- 带看次数、带看房源数等转化分析

## 必带过滤

```sql
WHERE pt = '${-1d_pt}'              -- 全量快照：取窗口末日一天即可
  AND del_type_code = '990001001'   -- 买卖；租赁=990001002；商业=990001007
  AND is_showing_valid = 1          -- 有效带看
```

日期窗口过滤 `showing_date`（拼成 `yyyy-MM-dd` 字符串后），**不要**扫多天 `pt`。**不要**再包 `to_date()`。

## 核心字段

| 字段 | 类型 | 含义 | 级别 | 备注 |
|------|------|------|------|------|
| custdel_id | bigint | 客源编码 | **关键** | JOIN 客源表 |
| showing_date | bigint | 统计日期 | **关键** | `yyyyMMdd`；拼 `yyyy-MM-dd`，勿 `to_date()` |
| showing_id | bigint | 带看 id | **关键** | 带看明细主键 |
| housedel_id | bigint | 房源编码 | **关键** | 房源粒度 |
| resblock_id / resblock_name | bigint / string | 楼盘 | **关键** | 本表已带小区名 |
| city_code / city_name | bigint / string | 城市 | 常用扩展 | 行级权限字段 |
| del_type_code | bigint | 带看委托类型 | **关键（过滤）** | 990001001 买卖 / 990001002 租赁 / 990001007 商业 |
| is_showing_valid | bigint | 是否带看有效 | **关键（过滤）** | **标准有效过滤** |
| is_valid | string | 带看状态 | 勿当有效过滤 | 字符「是/否」；≠ `is_showing_valid` |
| showagent_brand_code | — | 带看人品牌编码 | 权限相关 | 行级权限字段 |
| showagent_ucid / showagent_no | bigint | 带看人 | 扩展 | |
| pt | string | 分区 | **关键（过滤）** | 必带 |

## JOIN 路径

```
rpt.rpt_shh_show_showing_housedel_info_da.custdel_id
    = dw.dw_cdel_custdel_da.custdel_id
    → customer_uid AS ucid
```

模板：[templates/show_ershou_xinfang.md](../templates/show_ershou_xinfang.md)

## 已知坑

- `is_showing_valid` ≠ `is_valid`（本表）≠ 新房表的 `is_valid`
- `showing_date` 是 bigint；`concat(substr(...))` 拼日期即可，**禁止**再包 `to_date()`
- 本表已有 `resblock_name`，不必仅为小区名再 JOIN spr
- 行级城市/品牌权限会导致无权限城市结果为空
- **新房带看不在本表** → 用 `rpt.rpt_nh_show_house_showing_info_da`（见 [nh_show_house_showing_info_da.md](nh_show_house_showing_info_da.md)）

## Metrics referencing this table

- [metrics/commerce.md](../metrics/commerce.md)「新二带看」「商机带看量」
