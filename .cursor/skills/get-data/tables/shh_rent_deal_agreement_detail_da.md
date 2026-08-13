# rpt.rpt_shh_rent_deal_agreement_detail_da

> 二手成交基础信息表。表名含 `rent`，实际覆盖买卖与租赁；筛买卖用 `del_type_name = '买卖'`。
> table_id=`1174088` · 详情：`http://factory.data.ke.com/detail?table_id=1174088`

## 来自内部表检索

<!-- as of 2026-07-31, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 二手成交基础信息表 |
| 表类型 | Hive |
| 集群 | 公共集群 |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 安全等级 | C2 |
| 存储量 | 4.29 TB |
| 是否分区 | 是 |
| 分区字段 | `pt` |
| 字段数 | 167 |
| 数据负责人 | 张显锋(26670241) |
| 业务审批人 | 张显锋 |
| 业务负责人 | 李新星 |
| 所属空间 | 数据应用开发团队 |
| 权限包 | **通用** |
| 标签 | 高价值、M二手成交专题、任务/天 |
| 生命周期 | 365 天（删除前确认 7 天） |
| 数据最后更新 | 2026-07-31 03:31:07 |

**描述**：二手成交基础信息表。

## 权限

- 权限包：通用；审批/行级规则页未见额外规则
- 相对客源表、新房成交表更好申请

## 用途

- 新二成交用户日清单中的**二手**分支
- 买卖成交人数 / 签约日分布
- 同表可做租赁成交（换 `del_type`）

## 必带过滤（买卖成交）

```sql
WHERE pt = '${-1d_pt}'
  AND is_parent_agreement = 1          -- 主协议
  AND agreement_type_code = '150001001' -- 合同
  AND is_commit = 1                    -- 合同提交
  AND status_code IN (
      '150005002'                      -- 签约
      ,'150005003'                     -- 过户
      ,'150005006'                     -- 完结
  )
  AND del_type_name = '买卖'
  AND cust_ucid IS NOT NULL
  AND cust_ucid NOT IN ('-911','null')
```

## 核心字段

| 字段 | 类型 | 含义 | 备注 |
|------|------|------|------|
| cust_ucid | bigint | 客户 id | 二手侧直接作 `ucid` |
| sign_time | string | 签约时间 | `substr(...,1,10)` → `sign_date` |
| is_parent_agreement | tinyint | 是否主协议 | 必滤 =1 |
| agreement_type_code | int | 协议类型 | `150001001` 合同 |
| is_commit | tinyint | 是否提交 | 必滤 =1 |
| status_code / status_name | int / string | 协议状态 | 签约/过户/完结 |
| del_type_code / del_type_name | int / string | 委托类型 | 买卖 / 租赁 |
| housedel_id | bigint | 房源编码 | |
| custdel_id | bigint | 客源编码 | |
| city_code / city_name | int / string | 城市 | |
| agreement_amt | decimal | 协议金额 | |
| is_revoke | bigint | 是否解约 | |
| pt | string | 分区 | 必带 |

## 与 `rpt_shh_deal_agreement_da` 的关系

| 表 | 常见用途 |
|----|----------|
| `rpt.rpt_shh_rent_deal_agreement_detail_da` | 新二成交用户清单（直接有 `cust_ucid`） |
| `rpt.rpt_shh_deal_agreement_da` | 成交房源分析（常用 `housedel_id` + 同类状态过滤） |

## JOIN / 模板

- 模板：[templates/deal_ershou_xinfang.md](../templates/deal_ershou_xinfang.md)
- 指标：[metrics/commerce.md](../metrics/commerce.md)「二手成交」「租赁成交」

## 已知坑

- 表名 `rent` ≠ 只含租赁；买卖必须加 `del_type_name = '买卖'`
- `GROUP BY` 写具体字段/表达式，禁止 `1,2,3`
