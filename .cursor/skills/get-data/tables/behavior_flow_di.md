# rpt.rpt_log_bi_user_behivor_detail_flow_di

> 点击/行为/页面浏览。历史 SQL 引用 **349** 次，最高频表。

## 来自数据工厂

<!-- as of 2026-07-07, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 应用层-流量分析—用户行为明细数据表 |
| 表类型 | Hive |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 集群 | 公共集群 |
| 安全等级 | C2 |
| 存储量 | 147.25 TB |
| 是否分区 | 是 |
| 分区字段 | `pt`, `site`, `dp`, `evt_type` |
| 数据负责人 | 卓宝臻 |
| 业务负责人 | 刘欣吾 |
| 所属空间 | 数据应用开发团队 |
| 数据最后更新时间 | 2026-07-07 03:37:34.0 |
| 标签 | 事实表、高价值、保留近365天数据、M公共流量、M流量专题、大存储、大节点、高热度 |

数据工厂描述：设备 id 是 `duid`，此表为时间戳粒度，包含 lianjia、beike 的 app、xcx、pc、m 所有流量数据，主要用于用户行为串联分析，目前只包括 p 事件（页面曝光）和 e 事件（元素点击）。

## 用途

- 页面浏览（DAU）
- 点击事件
- AB 实验分组（从 `evt_id='1,3'` 的 action JSON 取 ab_test_sign）
- 与曝光表 UNION 构建完整流量 CTE

## 必带过滤

```sql
WHERE 1 = 1
  AND t1.pt = '${-1d_pt}'
  AND t1.site = 'beike'       -- 或 lianjia
  AND t1.dp = 'app'           -- 或 xcx / m
  -- evt_type 是分区字段，明确 p/e 时建议也过滤
  -- AND t1.evt_type = 'e'
```

## 标准字段块

```sql
SELECT
    active_date, dp, site, uicode, pid, evt_id, action,
    duid, ucid, client_time, client_os_type, client_os_version,
    client_app_version, city_code, city_name, business_name
FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
```

## 常用过滤

| 场景 | 条件 |
|------|------|
| 页面浏览 / DAU | `evt_id = '1,3'`（整体字符串，不是 `IN ('1','3')`） |
| 二手详情页 App | `uicode = 'ershou/detail'` |
| 详情页解析房源 | `get_json_object(action,'$.housedel_id')`；一般是 C 端 id，用前抽样确认 |
| 大小写兼容 | `lower(uicode) = 'communitydetailv2'` |
| AB 分组 | `get_json_object(action,'$.ab_test_sign')` |
| 版本门槛 | `client_app_version >= '3.02.31'`（按实验更新） |
| 北京 | `city_code = 110000`（本表为 int） |

详情页房源浏览也可改用已带房源 id 的 [comm_log_housedel_info_di.md](comm_log_housedel_info_di.md)。

**核访（推荐直接用本表标记）**：
- 新房：`is_xingfang_hefang = 1`；楼盘 `get_json_object(action,'$.project_name')`
- 二手：`is_ershou_hefang = 1`；房源 `get_json_object(action,'$.housedel_id')`
- 完整口径：[metrics/hefang.md](../metrics/hefang.md)
- 备选房源浏览表字段名为 `is_nh_hefang` / `is_shh_hefang`，与本表字段名不同

## 核心字段（数据工厂确认）

| 字段 | 类型 | 含义 | 是否分区 |
|------|------|------|----------|
| active_date | string | 活跃日期 | 否 |
| duid | string | 设备 id | 否 |
| ucid | string | 用户 id | 否 |
| client_time | string | 客户端请求时间 | 否 |
| client_timestamp | string | 客户端请求时间戳 | 否 |
| client_os_type | string | 客户端操作系统类型 | 否 |
| client_os_version | string | 客户端操作系统版本 | 否 |
| client_app_version | string | 客户端 app 版本 | 否 |
| pid | string | 业务线标识 | 否 |
| business_name | string | 业务线名称 | 否 |
| city_code | int | 城市编码 | 否 |
| city_name | string | 城市名称 | 否 |
| dig_ssid | string | 会话 ID | 否 |
| uicode | string | 页面标识 | 否 |
| evt_id | string | 事件 ID | 否 |
| evt_name | string | 事件名称 | 否 |
| action | string | 埋点事件参数 JSON | 否 |
| is_dau | tinyint | 是否用于整站 DAU 计算：-1 不适用，0 否，1 是 | 否 |
| is_xingfang_hefang | int | 是否新房核访 | 否；`= 1`；口径见 [metrics/hefang.md](../metrics/hefang.md) |
| is_ershou_hefang | int | 是否二手核访 | 否；`= 1`；口径见 [metrics/hefang.md](../metrics/hefang.md) |
| pt | string | 分区字段 | 是 |
| site | string | 分区字段 | 是 |
| dp | string | 分区字段 | 是 |
| evt_type | string | 分区字段 | 是 |

## 与曝光表 UNION 注意

- 曝光段常写 `'beike' AS site` 固定站点
- 列顺序和类型必须与曝光表对齐

## 已知坑

- 表名拼写是 **`behivor`**（非 behavior），写错查不到
- `evt_id` 是字符串，`'1,3'` 必须带引号
- 点击与曝光是不同表，不可只用一张表算 PCTR
- 数据工厂确认该表是复合分区：`pt/site/dp/evt_type`，大查询建议尽量补齐分区过滤
- `evt_type` 中 `p` 为页面曝光，`e` 为元素点击
