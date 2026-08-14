# 数据工厂建表信息 · 北京内容商机分大部

> 入口：http://factory.data.ke.com/create/tohive  
> 公共项（两表相同）：集群「公共集群」· 数据层级「应用分析数据」· 库/层级 **rpt** · 执行前需要确认 **是**

---

## 表 1：内容商机明细中间表（先建、先跑）

### 基本信息

| 表单项 | 填写 |
|--------|------|
| 表名称（表单后半段） | `content_sj_trans_detail_da` |
| 表中文名称 | 内容商机明细中间表 |
| 描述 | 贝壳App二手+新房内容商机明细中间表，源表全字段+content_sj_type（展位/溯源/保护），日快照da |

### 语句添加（括号内字段，点「解析」）

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_content_sj_trans_detail_da (
  `source_key_id` string COMMENT '源主键id（主键）'
  ,`occur_time` string COMMENT '商机发生时间'
  ,`occur_date` string COMMENT '商机发生日期'
  ,`commercial_type_code` bigint COMMENT '商机类型编码'
  ,`commercial_type_name` string COMMENT '商机类型名称'
  ,`website_code` bigint COMMENT '网站编码'
  ,`website_name` string COMMENT '网站名称'
  ,`client_code` bigint COMMENT '访问端编码'
  ,`client_name` string COMMENT '访问端名称'
  ,`business_code` bigint COMMENT '业务线编码'
  ,`business_name` string COMMENT '业务线名称'
  ,`cust_phone_encrypt` string COMMENT '客户手机号(非对称加密)'
  ,`cust_ucid` bigint COMMENT '客户ucid'
  ,`cust_phone` string COMMENT '客户手机号'
  ,`agent_ucid` bigint COMMENT '经纪人ucid'
  ,`agent_phone_encrypt` string COMMENT '经纪人手机号(非对称加密)'
  ,`agent_phone` string COMMENT '经纪人手机号'
  ,`housedel_id` bigint COMMENT 'B端房源id'
  ,`project_name` string COMMENT '新房C端盘源名称'
  ,`rent_unit_id` string COMMENT '租赁分散式公寓B端租赁单元id'
  ,`layout_id` string COMMENT '租赁集中式公寓B端房型id'
  ,`shh_resblock_id` bigint COMMENT '小区id'
  ,`district_id` bigint COMMENT '城区id'
  ,`bizcircle_id` bigint COMMENT '商圈id'
  ,`city_code` int COMMENT '业务城市编码'
  ,`city_name` string COMMENT '业务城市名称'
  ,`agent_no` bigint COMMENT '经纪人工号'
  ,`agent_name` string COMMENT '经纪人姓名'
  ,`brand_code` int COMMENT '品牌编码'
  ,`brand_name` string COMMENT '品牌名称'
  ,`alliance_code` string COMMENT '加盟商编码'
  ,`alliance_name` string COMMENT '加盟商名称'
  ,`corp_code` string COMMENT '分公司编码'
  ,`corp_name` string COMMENT '分公司名称'
  ,`func_code` string COMMENT '职能编码'
  ,`func_name` string COMMENT '职能名称'
  ,`region_code` string COMMENT '经纪人运营管理大区编码'
  ,`region_name` string COMMENT '经纪人运营管理大区名称'
  ,`marketing_code` string COMMENT '经纪人运营大区编码'
  ,`marketing_name` string COMMENT '经纪人运营大区名称'
  ,`area_code` string COMMENT '经纪人区域编码'
  ,`area_name` string COMMENT '经纪人区域名称'
  ,`shop_code` string COMMENT '经纪人门店编码'
  ,`shop_name` string COMMENT '经纪人门店名称'
  ,`team_code` string COMMENT '经纪人店组编码'
  ,`team_name` string COMMENT '经纪人店组名称'
  ,`uc_job_id` string COMMENT 'uc职务id'
  ,`uc_job_code` string COMMENT '职务编码'
  ,`uc_job_name` string COMMENT '职务名称'
  ,`is_cust_send` int COMMENT '是否用户主动发起'
  ,`is_today_newcust` int COMMENT '是否当日新增用户'
  ,`is_thirtydays_occur` int COMMENT '过去30天是否和该经纪人产生过商机'
  ,`is_operational` int COMMENT '是否可运营商机'
  ,`is_commercial_couple` int COMMENT '是否商机对'
  ,`is_del` int COMMENT '是否转委托'
  ,`is_show` int COMMENT '是否转带看'
  ,`is_deal` int COMMENT '是否转成交'
  ,`custdel_id` bigint COMMENT '客源id'
  ,`cdel_typing_time` string COMMENT '客源录入时间'
  ,`showing_id` bigint COMMENT '带看id'
  ,`showing_time` string COMMENT '带看时间'
  ,`recent_showing_id` bigint COMMENT '最近一次转带看id'
  ,`recent_showing_time` string COMMENT '最近一次转带看时间'
  ,`agreement_id` bigint COMMENT '成交id'
  ,`sign_time` string COMMENT '成交时间'
  ,`recent_agreement_id` bigint COMMENT '最近一次转成交id'
  ,`recent_sign_time` string COMMENT '最近一次转成交时间'
  ,`session_id` string COMMENT '网页会话id'
  ,`utm_trackid` string COMMENT 'utm_trackid'
  ,`utm_source` string COMMENT 'utm_source'
  ,`utm_medium` string COMMENT 'utm_medium'
  ,`utm_campaign` string COMMENT 'utm_campaign'
  ,`utm_content` string COMMENT 'utm_content'
  ,`utm_term` string COMMENT 'utm_term'
  ,`device_id` string COMMENT '手机设备id'
  ,`openid` string COMMENT '小程序id'
  ,`xcx_scene` string COMMENT '小程序场景'
  ,`xcx_source` string COMMENT '小程序渠道'
  ,`xcx_type` string COMMENT '小程序类型'
  ,`sub_commercial_source` string COMMENT '商机二级来源 商机中台source'
  ,`adid` bigint COMMENT '广告位ID'
  ,`app_data` string COMMENT '线索随路数据'
  ,`port` string COMMENT '商机展位'
  ,`digv_v` string COMMENT '版本号'
  ,`digv_s` string COMMENT '业务类型'
  ,`digv_flow` string COMMENT '流量版本'
  ,`digv_b` string COMMENT '出人策略'
  ,`digv_g` string COMMENT 'A/B实验标记'
  ,`digv_rid` string COMMENT '唯一追溯'
  ,`digv_sid` string COMMENT '订单号'
  ,`commercial_union_key` string COMMENT '商机信息联合键'
  ,`commercial_id` string COMMENT '商机唯一主键id'
  ,`commercial_couple_id` string COMMENT '商机对id'
  ,`commercial_user_id` string COMMENT '商机用户id'
  ,`commercial_city_code` string COMMENT '商机城市编码'
  ,`is_8_to_22` int COMMENT '是否8到22点'
  ,`is_coop_cdel_commercial` int COMMENT '是否合作客商机'
  ,`duid` string COMMENT '数盟id'
  ,`battle_region_code` string COMMENT '战区编码'
  ,`battle_region_name` string COMMENT '战区名'
  ,`province_region_code` string COMMENT '省区编码'
  ,`province_region_name` string COMMENT '省区名'
  ,`major_ucid` bigint COMMENT '总监ucid'
  ,`major_name` string COMMENT '总监'
  ,`ca_ucid` bigint COMMENT '运营人员ucid'
  ,`ca_name` string COMMENT '运营人员'
  ,`job_level_name` string COMMENT '职级名称'
  ,`battle_leader_ucid` bigint COMMENT '作战小组组长'
  ,`battle_leader_name` string COMMENT '作战小组组长姓名'
  ,`is_del_housedel` int COMMENT '商机用户是否委托房源'
  ,`del_housedel_id` bigint COMMENT '商机用户委托房源编码'
  ,`parent_scene_id` string COMMENT 'parentSceneId'
  ,`is_invalid` int COMMENT '是否无效商机'
  ,`first_deal_business_name` string COMMENT '首次成交业务名称'
  ,`commercial_channel_type_name` string COMMENT '商机渠道类型名称'
  ,`is_reserved_capital_recall` bigint COMMENT '是否留资商机回拨'
  ,`reserved_capital_recall_time` string COMMENT '留资商机回拨时间'
  ,`content_sj_type` string COMMENT '内容商机类型：booth=展位 trace=溯源 protect=保护'
)
partitioned by (pt string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\u0001'
COLLECTION ITEMS TERMINATED BY '\u0002'
MAP KEYS TERMINATED BY '\u0003'
STORED AS orc
LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_content_sj_trans_detail_da'
```

### ETL SQL 文件

`content_sj_trans_detail_da.sql`

---

## 表 2：北京内容商机按大部汇总结果表（中间表跑通后再建）

### 基本信息

| 表单项 | 填写 |
|--------|------|
| 表名称（表单后半段） | `bj_content_sj_by_marketing_result_di` |
| 表中文名称 | 北京内容商机按营销大区汇总结果指标表 |
| 描述 | 北京贝壳App内容商机按营销大区日指标：投稿/生产/流量/三类商机/带看/成交 |

### 语句添加

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_bj_content_sj_by_marketing_result_di (
  `stat_date` string COMMENT '统计日期'
  ,`marketing_name` string COMMENT '营销大区'
  ,`contributor_cnt` bigint COMMENT '投稿人数'
  ,`content_cnt` bigint COMMENT '内容生产量'
  ,`detail_expo_pv` bigint COMMENT '内容详情页曝光量'
  ,`detail_expo_uv` bigint COMMENT '内容详情页曝光人数'
  ,`sj_booth_cnt` bigint COMMENT '展位商机量'
  ,`sj_trace_cnt` bigint COMMENT '溯源商机量'
  ,`sj_protect_cnt` bigint COMMENT '保护商机量'
  ,`sj_total_cnt` bigint COMMENT '内容商机量'
  ,`sj_show_cnt` bigint COMMENT '内容商机带看量'
  ,`sj_deal_cnt` bigint COMMENT '内容商机成交量'
)
partitioned by (pt string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\u0001'
COLLECTION ITEMS TERMINATED BY '\u0002'
MAP KEYS TERMINATED BY '\u0003'
STORED AS orc
LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_bj_content_sj_by_marketing_result_di'
```

### ETL SQL 文件

`bj_content_sj_by_marketing.sql`

---

## 表 3：北京主理人内容商机按大部汇总结果表

### 基本信息

| 表单项 | 填写 |
|--------|------|
| 表名称（表单后半段） | `bj_curator_content_sj_by_marketing_result_di` |
| 表中文名称 | 北京主理人内容商机按营销大区汇总结果指标表 |
| 描述 | 北京贝壳App主理人内容商机按营销大区日指标：投稿/生产/流量/三类商机/带看/成交（content_tag=curator_content） |

### 语句添加

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_bj_curator_content_sj_by_marketing_result_di (
  `stat_date` string COMMENT '统计日期'
  ,`marketing_name` string COMMENT '营销大区'
  ,`contributor_cnt` bigint COMMENT '投稿人数'
  ,`content_cnt` bigint COMMENT '内容生产量'
  ,`detail_expo_pv` bigint COMMENT '内容详情页曝光量'
  ,`detail_expo_uv` bigint COMMENT '内容详情页曝光人数'
  ,`sj_booth_cnt` bigint COMMENT '展位商机量'
  ,`sj_trace_cnt` bigint COMMENT '溯源商机量'
  ,`sj_protect_cnt` bigint COMMENT '保护商机量'
  ,`sj_total_cnt` bigint COMMENT '内容商机量'
  ,`sj_show_cnt` bigint COMMENT '内容商机带看量'
  ,`sj_deal_cnt` bigint COMMENT '内容商机成交量'
)
partitioned by (pt string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\u0001'
COLLECTION ITEMS TERMINATED BY '\u0002'
MAP KEYS TERMINATED BY '\u0003'
STORED AS orc
LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_bj_curator_content_sj_by_marketing_result_di'
```

### ETL SQL 文件

`bj_curator_content_sj_by_marketing.sql`

---

## 调度顺序

```
1. content_sj_trans_detail_da.sql              → rpt_content_sj_trans_detail_da
2. bj_content_sj_by_marketing.sql              → rpt_bj_content_sj_by_marketing_result_di
3. bj_curator_content_sj_by_marketing.sql      → rpt_bj_curator_content_sj_by_marketing_result_di
```

## 查数验证

```sql
-- 中间表：昨天北京内容商机
SELECT content_sj_type, count(DISTINCT commercial_couple_id) AS cnt
FROM rpt.rpt_content_sj_trans_detail_da
WHERE pt = '${-1d_pt}'
  AND city_code = 110000
  AND substr(occur_date, 1, 10) = '${-1d_yyyy-MM-dd}'
GROUP BY content_sj_type
;

-- 结果表：全量内容按大部
SELECT *
FROM rpt.rpt_bj_content_sj_by_marketing_result_di
WHERE pt = '${-1d_pt}'
ORDER BY sj_total_cnt DESC
;

-- 结果表：主理人内容按大部
SELECT *
FROM rpt.rpt_bj_curator_content_sj_by_marketing_result_di
WHERE pt = '${-1d_pt}'
ORDER BY sj_total_cnt DESC
;
```
