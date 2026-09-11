# rpt.rpt_nh_output_deal_info_online_custdel_da

> 新房运管成交对外输出表（线上客源标签）。新二成交清单中的**新房**分支。
> table_id=`1161481` · 详情：`http://factory.data.ke.com/detail?table_id=1161481`

## 来自内部表检索

<!-- as of 2026-07-31, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 应用输出层-新房运管-成交表对外输出表线上客源标签 |
| 表类型 | Hive |
| 集群 | 公共集群 |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 安全等级 | C2 |
| 存储量 | 3.09 TB |
| 是否分区 | 是 |
| 分区字段 | `pt` |
| 字段数 | 99 |
| 数据负责人 | 刘少峰(26026980) |
| 业务审批人 | 刘少峰 |
| 业务负责人 | 刘燕霞 |
| 所属空间 | 数据应用开发团队 |
| 所属业务 | 第一赛道/新房 |
| 权限包 | **通用** |
| 标签 | 高价值、**行级权限**、任务/天、M非核心应用层 |
| 生命周期 | 1826 天（5 年；删除前确认 30 天） |
| 数据最后更新 | 2026-07-31 04:30:58 |

**描述**：应用输出层_新房运管_成交表对外输出表线上客源标签_日全量。

## 权限

- 权限包：通用
- 搜索卡片带**行级权限**标签；权限规则页细则以工厂「权限规则」为准
- 无客源桥时仍可能查出成交，但拿不到 C 端 `ucid`

## 用途

- 新房成交用户日清单
- 认购/网签/成销金额与时间分析
- 经客源表桥到 `ucid` 后与流量/商机/带看关联

## 必带过滤（新二成交口径）

```sql
WHERE pt = '${-1d_pt}'
  AND brand_name <> '外渠房江湖'
  AND city_name NOT LIKE '测试%'
  AND is_cancel = 0
```

## 核心字段

| 字段 | 类型 | 含义 | 备注 |
|------|------|------|------|
| custdel_id | string | 中台系统客源 id | JOIN 客源表键 |
| agent_ucid | string | 主经纪人 ucid | **商机成交匹配键**；cast bigint；另有 `agent_list` |
| agent_name | string | 主经纪人名 | |
| out_custdel_id | string | 新房客源唯一标识 | 勿与 `custdel_id` 混用 |
| order_time | string | 认购时间 | 标准成交日：`substr(...,1,10)` |
| sign_time | string | 网签时间 | 网签口径时用 |
| sold_time | string | 成销时间 | |
| is_cancel | tinyint | 是否退单 | 必滤 =0 |
| brand_name | string | 品牌名称 | 排除外渠房江湖 |
| city_name | string | 市名称 | 排除测试城 |
| showing_id / showing_date | string | 带看 id / 日期 | 本表内带看字段，非二手带看表 |
| order_amt / sign_amt / sold_amt | decimal | 认购/网签/成交金额 | |
| resblock_id / resblock_name | string | 楼盘 | |
| is_online_custdel | string | 是否线上客源 | |
| pt | string | 分区 | 必带 |

## JOIN 路径

```
rpt.rpt_nh_output_deal_info_online_custdel_da.custdel_id
    = dw.dw_cdel_custdel_da.custdel_id
    → customer_uid AS ucid
```

- 模板：
  - [templates/deal_ershou_xinfang.md](../templates/deal_ershou_xinfang.md)
  - [templates/sj_deal_matched_daily.md](../templates/sj_deal_matched_daily.md)
- 客源表：[cdel_custdel_da.md](cdel_custdel_da.md)

## 已知坑

- 用户键不在本表，必须经 `dw.dw_cdel_custdel_da` 桥 `ucid`
- `custdel_id`（中台）≠ `out_custdel_id`（新房客源唯一标识）
- 标准「签约日」用 `order_time`（认购），不是网签 `sign_time`
- 客源表 C3 + `ADHOC异地推广`，无权限会卡在 JOIN

## Metrics referencing this table

- [metrics/commerce.md](../metrics/commerce.md)「新房成交」「商机成交量」
