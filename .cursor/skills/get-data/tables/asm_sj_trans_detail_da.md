# rpt.rpt_asm_sj_trans_detail_da

> 商机转化明细表。历史 SQL 引用 **73** 次。
> table_id=`125732` · 详情：`http://factory.data.ke.com/detail?table_id=125732`

## 来自内部表检索

<!-- as of 2026-07-31, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 商机转化明细表 |
| 表类型 | Hive |
| 集群 | 公共集群 |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 安全等级 | C2 |
| 存储量 | 381.23 TB |
| 是否分区 | 是 |
| 分区字段 | `pt` |
| 表粒度 | `commercial_id` |
| 分区范围 | 20200722–至今 |
| 生命周期 | 720 天（每月第一天排除） |
| 数据负责人 | 卓宝臻(26724666) |
| 业务负责人 | 马作浩 |
| 业务审批人 | 卓宝臻 |
| 所属空间 | 数据应用开发团队 |
| 所属业务 | 第一赛道/业务中台 |
| 权限包 | 通用 |
| 数据最后更新时间 | 2026-07-31 04:37:33 |
| 标签 | M大存储、M大节点、M商机专题、M高热度 |

**描述（工厂原文摘要）**：平台及城市 BI / POC / 部分业务 PM 查看商机转化明细；覆盖商机转委托、转带看、转成交。

## 用途

- 页面商机（按 `adid` 过滤展位/广告位）
- 商机对 UV / PV、转商机率分子
- 转委托 / 转带看 / 转成交链路
- 与溯源表按 `commercial_id` 关联算溯源商机
- 用户调研人群筛选
- 商机溯源分析（配合 [commerce_scene_calculate_distance_di.md](commerce_scene_calculate_distance_di.md)）

## 页面商机过滤（常用）

```sql
WHERE pt = '${-1d_pt}'
  AND occur_date = '${-1d_yyyy-MM-dd}'
  AND business_name = '二手'          -- 按业务改
  AND is_commercial_couple = 1       -- 是否商机对
  AND adid IN (...)                  -- 广告位 ID；页面商机用该页 adid 列表
```

完整模板：[templates/page_sj_by_adid.md](../templates/page_sj_by_adid.md)

## 转化标记字段（工厂口径）

| 字段 | 含义 | 用法 |
|------|------|------|
| `is_commercial_couple` | 是否商机对 | 页面/展位商机常用 `= 1` |
| `is_del` | **是否转委托** | 勿当成「有效商机」 |
| `is_show` | 是否转带看 | |
| `is_deal` | 是否转成交 | |
| `is_invalid` | 是否无效商机 | `1`无效 / `0`非无效 / `-911`未知 |

## 关键字段速查

| 字段 | 类型 | 含义 | 备注 |
|------|------|------|------|
| `pt` | string | 分区字段 | 必带；分区字段标记=是 |
| `source_key_id` | string | 源主键 id | 主键标记=是；可拆会话 ID 关联三次握手 |
| `occur_date` / `occur_time` | string | 商机发生日期/时间 | |
| `commercial_id` | string | 商机唯一主键 id | 表粒度 |
| `commercial_couple_id` | string | 商机对 id | 商机 PV |
| `cust_ucid` | bigint | 客户 ucid | 商机用户键 |
| `duid` | string | 数盟 id | 跟流量 DAU 关联 |
| `adid` | bigint | 广告位 ID | 页面商机过滤常用 |
| `port` | string | 商机展位 | 工厂字段名；与 adid 区分 |
| `business_name` | string | 业务线名称 | 见枚举 |
| `website_name` / `client_name` | string | 网站 / 访问端 | |
| `commercial_type_code` | bigint | 商机类型编码 | 见枚举 |
| `cdel_typing_time` | string | 客源录入时间 | 转委托相关 |
| `agent_ucid` | bigint | 经纪人 ucid | |

## 枚举（工厂）

**商机类型** `commercial_type_code`：

| 值 | 含义 |
|----|------|
| 900004001 | 400 |
| 900004002 | IM |
| 900004003 | 留资 |
| 900004004 | VR带看 |
| 900004005 | 语音通话 |
| -911 | 未知 |

**网站** `website_code`：`909999003` 链家 · `909999005` 贝壳 · `-911` 未知

**访问端** `client_code`：`130008001` pc · `130008002` app · `130008004` m · `130008005` 小程序 · `-911` 未知

**业务线** `business_code`：`909100001` 租赁 · `909100002` 二手 · `909100003` 新房 · `909100005` 海外 · `909100011` 商业地产 · `-911` 未知

## 全字段清单（118）

| # | 字段 | 类型 | 含义 |
|---|------|------|------|
| 1 | source_key_id | string | 源主键id（主键） |
| 2 | occur_time | string | 商机发生时间 |
| 3 | occur_date | string | 商机发生日期 |
| 4 | commercial_type_code | bigint | 商机类型编码 |
| 5 | commercial_type_name | string | 商机类型名称 |
| 6 | website_code | bigint | 网站编码 |
| 7 | website_name | string | 网站名称 |
| 8 | client_code | bigint | 访问端编码 |
| 9 | client_name | string | 访问端名称 |
| 10 | business_code | bigint | 业务线编码 |
| 11 | business_name | string | 业务线名称 |
| 12 | cust_phone_encrypt | string | 客户手机号(非对称加密) |
| 13 | cust_ucid | bigint | 客户ucid |
| 14 | cust_phone | string | 客户手机号 |
| 15 | agent_ucid | bigint | 经纪人ucid |
| 16 | agent_phone_encrypt | string | 经纪人手机号(非对称加密) |
| 17 | agent_phone | string | 经纪人手机号 |
| 18 | housedel_id | bigint | B端房源id |
| 19 | project_name | string | 新房C端盘源名称 |
| 20 | rent_unit_id | string | 租赁分散式公寓B端租赁单元id |
| 21 | layout_id | string | 租赁集中式公寓B端房型id |
| 22 | shh_resblock_id | bigint | 小区id |
| 23 | district_id | bigint | 城区id |
| 24 | bizcircle_id | bigint | 商圈id |
| 25 | city_code | int | 业务城市编码 |
| 26 | city_name | string | 业务城市名称 |
| 27 | agent_no | bigint | 经纪人工号 |
| 28 | agent_name | string | 经纪人姓名 |
| 29 | brand_code | int | 品牌编码 |
| 30 | brand_name | string | 品牌名称 |
| 31 | alliance_code | string | 加盟商编码 |
| 32 | alliance_name | string | 加盟商名称 |
| 33 | corp_code | string | 分公司编码 |
| 34 | corp_name | string | 分公司名称 |
| 35 | func_code | string | 职能编码 |
| 36 | func_name | string | 职能名称 |
| 37 | region_code | string | 经纪人运营管理大区编码 |
| 38 | region_name | string | 经纪人运营管理大区名称 |
| 39 | marketing_code | string | 经纪人运营大区编码 |
| 40 | marketing_name | string | 经纪人运营大区名称 |
| 41 | area_code | string | 经纪人区域编码 |
| 42 | area_name | string | 经纪人区域名称 |
| 43 | shop_code | string | 经纪人门店编码 |
| 44 | shop_name | string | 经纪人门店名称 |
| 45 | team_code | string | 经纪人店组编码 |
| 46 | team_name | string | 经纪人店组名称 |
| 47 | uc_job_id | string | uc职务id |
| 48 | uc_job_code | string | 职务编码 |
| 49 | uc_job_name | string | 职务名称 |
| 50 | is_cust_send | int | 是否用户主动发起 |
| 51 | is_today_newcust | int | 是否当日新增用户 |
| 52 | is_thirtydays_occur | int | 过去30天是否和该经纪人产生过商机 |
| 53 | is_operational | int | 是否可运营商机 |
| 54 | is_commercial_couple | int | 是否商机对 |
| 55 | is_del | int | 是否转委托 |
| 56 | is_show | int | 是否转带看 |
| 57 | is_deal | int | 是否转成交 |
| 58 | custdel_id | bigint | 客源id |
| 59 | cdel_typing_time | string | 客源录入时间 |
| 60 | showing_id | bigint | 带看id |
| 61 | showing_time | string | 带看时间 |
| 62 | recent_showing_id | bigint | 最近一次转带看id |
| 63 | recent_showing_time | string | 最近一次转带看时间 |
| 64 | agreement_id | bigint | 成交id |
| 65 | sign_time | string | 成交时间 |
| 66 | recent_agreement_id | bigint | 最近一次转成交id |
| 67 | recent_sign_time | string | 最近一次转成交时间 |
| 68 | session_id | string | 网页会话id |
| 69 | utm_trackid | string | utm_trackid |
| 70 | utm_source | string | utm_source |
| 71 | utm_medium | string | utm_medium |
| 72 | utm_campaign | string | utm_campaign |
| 73 | utm_content | string | utm_content |
| 74 | utm_term | string | utm_term |
| 75 | device_id | string | 手机设备id |
| 76 | openid | string | 小程序id |
| 77 | xcx_scene | string | 小程序场景 |
| 78 | xcx_source | string | 小程序渠道 |
| 79 | xcx_type | string | 小程序类型 |
| 80 | sub_commercial_source | string | 商机二级来源 商机中台source |
| 81 | adid | bigint | 广告位ID |
| 82 | app_data | string | 线索随路数据 |
| 83 | port | string | 商机展位 |
| 84 | digv_v | string | 版本号 |
| 85 | digv_s | string | 业务类型 |
| 86 | digv_flow | string | 流量版本 |
| 87 | digv_b | string | 出人策略 |
| 88 | digv_g | string | A/B实验标记 |
| 89 | digv_rid | string | 唯一追溯 |
| 90 | digv_sid | string | 订单号 |
| 91 | commercial_union_key | string | 商机信息联合键 |
| 92 | commercial_id | string | 商机唯一主键id |
| 93 | commercial_couple_id | string | 商机对id |
| 94 | commercial_user_id | string | 商机用户id |
| 95 | pt | string | 分区字段 |
| 96 | commercial_city_code | string | 商机城市编码 |
| 97 | is_8_to_22 | int | 是否8到22点 |
| 98 | is_coop_cdel_commercial | int | 是否合作客商机 |
| 99 | duid | string | 数盟id |
| 100 | battle_region_code | string | 战区编码 |
| 101 | battle_region_name | string | 战区名 |
| 102 | province_region_code | string | 省区编码 |
| 103 | province_region_name | string | 省区名 |
| 104 | major_ucid | bigint | 总监ucid |
| 105 | major_name | string | 总监 |
| 106 | ca_ucid | bigint | 运营人员ucid |
| 107 | ca_name | string | 运营人员 |
| 108 | job_level_name | string | 职级名称 |
| 109 | battle_leader_ucid | bigint | 作战小组组长 |
| 110 | battle_leader_name | string | 作战小组组长姓名 |
| 111 | is_del_housedel | int | 商机用户是否委托房源 |
| 112 | del_housedel_id | bigint | 商机用户委托房源编码 |
| 113 | parent_scene_id | string | parentSceneId |
| 114 | is_invalid | int | 是否无效商机 |
| 115 | first_deal_business_name | string | 首次成交业务名称 |
| 116 | commercial_channel_type_name | string | 商机渠道类型名称 |
| 117 | is_reserved_capital_recall | bigint | 是否留资商机回拨 |
| 118 | reserved_capital_recall_time | string | 留资商机回拨时间 |

## 与流量表 JOIN

```sql
INNER JOIN (
    SELECT cust_ucid
    FROM rpt.rpt_asm_sj_trans_detail_da
    WHERE pt = '${-1d_pt}'
      AND is_commercial_couple = 1
    GROUP BY cust_ucid
) sj ON dau.ucid = sj.cust_ucid
```

## 已知坑

- **`is_del` = 是否转委托**，不是「有效商机」；无效商机看 `is_invalid`
- 页面商机：`is_commercial_couple = 1` + `adid IN (...)`
- 工厂字段：`adid`=广告位ID，`port`=商机展位；写 SQL 过滤页面时沿用历史 `adid`
- 商机用户键 `cust_ucid`，页面 DAU 常用 `duid`——JOIN 前确认分析单位
- 三次握手来自 `dw.dw_log_commerce_stream_clue_inf_di`（`data_lables = '["1002"]'`），是商机子集、按需使用
