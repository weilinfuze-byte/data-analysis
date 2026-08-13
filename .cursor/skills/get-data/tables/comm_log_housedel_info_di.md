# rpt.rpt_comm_log_housedel_info_di

> 流量房源信息表。用户浏览房源行为明细（流量域/房产相关），无聚合粒度。

## 来自内部表检索

<!-- as of 2026-07-15, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 流量房源信息表 |
| 表类型 | Hive |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 集群 | 公共集群 |
| 安全等级 | C2 |
| 存储量 | ~1.10 TB |
| 是否分区 | 是 |
| 分区字段 | `pt`（仅一层，无 site/dp/evt_type 复合分区） |
| 数据负责人 | 卓宝臻 |
| 业务负责人 | 刘欣吾 |
| 所属空间 | 数据应用开发团队 |
| 分区范围 | 20220220–至今 |
| 生命周期 | 720 天 |
| 标签 | 高价值、M公共流量、M流量专题 |

描述：浏览房源信息明细；表粒度为用户浏览房源明细。

## 用途

- 按房源 / 小区统计浏览用户数（需再 JOIN 房源维表拿小区）
- 二手 / 新房 / 租赁核访房源筛选
- 与行为明细表互补：本表已带 `c_housedel_id` / `b_housedel_id`，无需从 action 解析

## 必带过滤

```sql
WHERE pt = '${-1d_pt}'          -- 或 BETWEEN 窗口
  -- site / dp 是普通字段，不是分区，需用 WHERE 过滤
  AND site = 'beike'
  AND dp = 'app'
```

## 核心字段

| 字段 | 类型 | 含义 | 备注 |
|------|------|------|------|
| active_date | string | 活跃日期 | |
| duid | string | 数盟 id（设备） | |
| ucid | string | 用户 id | |
| business_name | string | 业务线名称 | |
| city_code | string | 城市编码 | **string**，北京=`'110000'` |
| city_name | string | 城市名称 | 埋点上报城市 |
| site | string | 网站 | beike / lianjia；非分区 |
| site_code | string | 网站编码 | |
| site_name | string | 网站名称 | |
| dp | string | 端 | app / xcx / m；非分区 |
| event | string | 事件 | |
| evt_id | string | 事件 id | 本表可写 `IN ('1','3')`；与行为表明细的 `'1,3'` 写法不同，见坑点 |
| pid | string | pid | |
| client_time | string | 客户端请求时间 | |
| client_os_type | string | 客户端操作系统类型 | |
| uicode | string | 页面标识 | 二手详情=`'ershou/detail'` |
| c_housedel_id | string | C 端房源 id | **JOIN 维表取小区用这个** |
| b_housedel_id | string | B 端房源 id | |
| is_shh_hefang | int | 是否二手核访 | `= 1`；与行为明细 `is_ershou_hefang` 对应 |
| is_nh_hefang | int | 是否新房核访 | `= 1`；与行为明细 `is_xingfang_hefang` 对应 |
| is_rent_hefang | int | 是否租赁核访 | |
| is_hefang | int | 是否核访 | |

核访完整口径见 [metrics/hefang.md](../metrics/hefang.md)。通用核访取数优先行为明细表标记字段。
| pt | string | 分区 | 必带 |

## JOIN 路径

```
本表 c_housedel_id
    ↓ CAST(housedel_id AS string)
rpt.rpt_comm_spr_hdel_housedel_info_da（房源维表，取单日快照 pt）
    ↓ resblock_id / resblock_name
小区粒度浏览用户数
```

关联小区用 **`c_housedel_id` ↔ 维表 `housedel_id`**（维表字段需 `CAST(... AS string)`）。

## 已知坑

- 分区只有 `pt`，`site`/`dp` 必须写在 WHERE，不能当分区裁剪
- `city_code` 是 **string**；维表和行为明细表的 `city_code` 是 **int**，过滤写法不同
- 本表只能统计「被浏览过」的核访房源，不是全量核访房源盘点
- 数房源时不要默认加 `ucid IS NOT NULL`（会丢掉仅未登录浏览的房源）；数用户时必须加
- 从行为明细表取详情页曝光时，`evt_id = '1,3'`（整体字符串）；本表若按事件过滤可试 `IN ('1','3')`，以实际数据为准
- 关联小区口径已确认用 `c_housedel_id`，不要改用 `b_housedel_id`

## Metrics referencing this table

- （暂无沉淀指标；内容供给热度分层属项目假设，未入库）
