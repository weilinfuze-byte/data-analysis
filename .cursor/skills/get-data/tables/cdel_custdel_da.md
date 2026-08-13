# dw.dw_cdel_custdel_da

> 客源表。客户委托经纪人买二手/新房或租房后形成客源；带看、新房成交等场景用 `custdel_id → customer_uid(ucid)` 桥接。

## 来自内部表检索

<!-- as of 2026-07-31, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 客源 |
| 表类型 | Hive |
| 数据层级 | 基础细节数据 |
| 数据库 | dw |
| 集群 | 公共集群 |
| 安全等级 | **C3** |
| 存储量 | ~129 TB |
| 是否分区 | 是 |
| 分区字段 | `pt` |
| 数据负责人 | 苏万磊 |
| 业务审批人 | 苏万磊 |
| 所属空间 | 数据资产开发团队 |
| 权限包 | **ADHOC异地推广** |
| 标签 | 核心表、行级权限、高价值、DW2.0、M大存储、任务/天 |
| 字段数 | 61 |
| 数据最后更新 | 2026-07-31 01:30:11 |

**描述摘要**：客源实体含委托信息，主要有联系电话、委托来源、维护人信息等。

## 权限

### 审批流程

数据查询 / 离线开发 → **表业务审批人通用模板**（业务审批人：苏万磊）。

### 行级权限

标签含**行级权限**；申请查询/开发前在数据工厂「权限规则」页确认当前账号可见范围。

## 用途

- 带看事实 `custdel_id` → C 端用户 `ucid`
- 新房成交 `custdel_id` → `customer_uid`
- 客源属性（委托类型、状态、维护人等）

## 必带过滤（客源桥 `customer_uid`）

新房成交 / 带看桥 `ucid` 时，异常值按此口径（Locked）：

```sql
WHERE pt = '${-1d_pt}'
  AND customer_uid NOT IN ('-911','0')
  AND customer_uid IS NOT NULL
```

## 核心字段

| 字段 | 类型 | 含义 | 备注 |
|------|------|------|------|
| custdel_id | bigint | 客源编码 | 主键 |
| customer_uid | bigint | 客源 UID | 分析侧作 `ucid` |
| del_type_code | — | 委托类型 | |
| status_code | — | 状态编码 | |
| hold_ucid / create_ucid | — | 维护人 / 创建人 | 勿与 `customer_uid` 混淆 |
| telephone1/2/3 | — | 联系电话 | 加密，C2 |
| pt | string | 分区 | 必带 |

## JOIN 路径

```
带看 / 新房成交.custdel_id
    = dw.dw_cdel_custdel_da.custdel_id
    → customer_uid AS ucid
```

- 带看模板：[templates/show_ershou_xinfang.md](../templates/show_ershou_xinfang.md)
- 成交模板：[templates/deal_ershou_xinfang.md](../templates/deal_ershou_xinfang.md)

## 已知坑

- 安全等级 **C3** + 独立权限包，无权限会先卡查询
- `customer_uid` 才是 C 端用户；`hold_ucid` / `ucid`（维护人）不是客户
- `customer_uid` 异常值：`NOT IN ('-911','0')` + `IS NOT NULL`（相对通用关联键多剔 `'0'`；禁止剔 `''` / `' '`）

## Metrics referencing this table

- [metrics/commerce.md](../metrics/commerce.md)「新二带看」「新房成交」
