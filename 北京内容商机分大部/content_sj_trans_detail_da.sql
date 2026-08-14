-- ============================================================
-- Project: 内容商机明细中间表
-- 中文名: 内容商机明细中间表
-- 英文名: rpt.rpt_content_sj_trans_detail_da
-- 建表页注意: 库选 rpt 后表名前缀已默认 rpt_，表单只填 content_sj_trans_detail_da
-- 表说明: 见同目录 rpt_content_sj_trans_detail_da.md
-- Created: 2026-08-14
-- Scope: 贝壳 App，二手+新房，全国；业务日 = '${-1d_yyyy-MM-dd}'
--
-- 粒度: 日快照 da 表；每 pt 分区含源表快照中全部内容商机（不限 occur_date）
-- ETL: 读 rpt_asm_sj_trans_detail_da pt=当天快照，三类打标后全量写入
-- 计数口径（Locked）:
--   分类型: 按 content_sj_type 各自 count(DISTINCT commercial_couple_id)，三类可加总大于总量
--   总量:   count(DISTINCT commercial_couple_id)，跨类型去重
--
-- 三类口径（不要求 parent_scene_id 归因内容页）:
--   booth   展位: adid 内容详情页展位列表
--   trace   溯源: 溯源表 uicode 视频/图文详情 + distance 1-7 + JOIN 商机
--   protect 保护: rpt_asm_sj_detail_di digv_b 内容直播保护 → JOIN 商机明细取全字段
--
-- Style: SELECT 逗号前置; 表别名 t1/t2; 禁止 ORDER BY
-- ============================================================
-- 建表语句:
-- CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_content_sj_trans_detail_da (
--   `source_key_id` string COMMENT '源主键id（主键）'
--   ,`occur_time` string COMMENT '商机发生时间'
--   ,`occur_date` string COMMENT '商机发生日期'
--   ,`commercial_type_code` bigint COMMENT '商机类型编码'
--   ,`commercial_type_name` string COMMENT '商机类型名称'
--   ,`website_code` bigint COMMENT '网站编码'
--   ,`website_name` string COMMENT '网站名称'
--   ,`client_code` bigint COMMENT '访问端编码'
--   ,`client_name` string COMMENT '访问端名称'
--   ,`business_code` bigint COMMENT '业务线编码'
--   ,`business_name` string COMMENT '业务线名称'
--   ,`cust_phone_encrypt` string COMMENT '客户手机号(非对称加密)'
--   ,`cust_ucid` bigint COMMENT '客户ucid'
--   ,`cust_phone` string COMMENT '客户手机号'
--   ,`agent_ucid` bigint COMMENT '经纪人ucid'
--   ,`agent_phone_encrypt` string COMMENT '经纪人手机号(非对称加密)'
--   ,`agent_phone` string COMMENT '经纪人手机号'
--   ,`housedel_id` bigint COMMENT 'B端房源id'
--   ,`project_name` string COMMENT '新房C端盘源名称'
--   ,`rent_unit_id` string COMMENT '租赁分散式公寓B端租赁单元id'
--   ,`layout_id` string COMMENT '租赁集中式公寓B端房型id'
--   ,`shh_resblock_id` bigint COMMENT '小区id'
--   ,`district_id` bigint COMMENT '城区id'
--   ,`bizcircle_id` bigint COMMENT '商圈id'
--   ,`city_code` int COMMENT '业务城市编码'
--   ,`city_name` string COMMENT '业务城市名称'
--   ,`agent_no` bigint COMMENT '经纪人工号'
--   ,`agent_name` string COMMENT '经纪人姓名'
--   ,`brand_code` int COMMENT '品牌编码'
--   ,`brand_name` string COMMENT '品牌名称'
--   ,`alliance_code` string COMMENT '加盟商编码'
--   ,`alliance_name` string COMMENT '加盟商名称'
--   ,`corp_code` string COMMENT '分公司编码'
--   ,`corp_name` string COMMENT '分公司名称'
--   ,`func_code` string COMMENT '职能编码'
--   ,`func_name` string COMMENT '职能名称'
--   ,`region_code` string COMMENT '经纪人运营管理大区编码'
--   ,`region_name` string COMMENT '经纪人运营管理大区名称'
--   ,`marketing_code` string COMMENT '经纪人运营大区编码'
--   ,`marketing_name` string COMMENT '经纪人运营大区名称'
--   ,`area_code` string COMMENT '经纪人区域编码'
--   ,`area_name` string COMMENT '经纪人区域名称'
--   ,`shop_code` string COMMENT '经纪人门店编码'
--   ,`shop_name` string COMMENT '经纪人门店名称'
--   ,`team_code` string COMMENT '经纪人店组编码'
--   ,`team_name` string COMMENT '经纪人店组名称'
--   ,`uc_job_id` string COMMENT 'uc职务id'
--   ,`uc_job_code` string COMMENT '职务编码'
--   ,`uc_job_name` string COMMENT '职务名称'
--   ,`is_cust_send` int COMMENT '是否用户主动发起'
--   ,`is_today_newcust` int COMMENT '是否当日新增用户'
--   ,`is_thirtydays_occur` int COMMENT '过去30天是否和该经纪人产生过商机'
--   ,`is_operational` int COMMENT '是否可运营商机'
--   ,`is_commercial_couple` int COMMENT '是否商机对'
--   ,`is_del` int COMMENT '是否转委托'
--   ,`is_show` int COMMENT '是否转带看'
--   ,`is_deal` int COMMENT '是否转成交'
--   ,`custdel_id` bigint COMMENT '客源id'
--   ,`cdel_typing_time` string COMMENT '客源录入时间'
--   ,`showing_id` bigint COMMENT '带看id'
--   ,`showing_time` string COMMENT '带看时间'
--   ,`recent_showing_id` bigint COMMENT '最近一次转带看id'
--   ,`recent_showing_time` string COMMENT '最近一次转带看时间'
--   ,`agreement_id` bigint COMMENT '成交id'
--   ,`sign_time` string COMMENT '成交时间'
--   ,`recent_agreement_id` bigint COMMENT '最近一次转成交id'
--   ,`recent_sign_time` string COMMENT '最近一次转成交时间'
--   ,`session_id` string COMMENT '网页会话id'
--   ,`utm_trackid` string COMMENT 'utm_trackid'
--   ,`utm_source` string COMMENT 'utm_source'
--   ,`utm_medium` string COMMENT 'utm_medium'
--   ,`utm_campaign` string COMMENT 'utm_campaign'
--   ,`utm_content` string COMMENT 'utm_content'
--   ,`utm_term` string COMMENT 'utm_term'
--   ,`device_id` string COMMENT '手机设备id'
--   ,`openid` string COMMENT '小程序id'
--   ,`xcx_scene` string COMMENT '小程序场景'
--   ,`xcx_source` string COMMENT '小程序渠道'
--   ,`xcx_type` string COMMENT '小程序类型'
--   ,`sub_commercial_source` string COMMENT '商机二级来源 商机中台source'
--   ,`adid` bigint COMMENT '广告位ID'
--   ,`app_data` string COMMENT '线索随路数据'
--   ,`port` string COMMENT '商机展位'
--   ,`digv_v` string COMMENT '版本号'
--   ,`digv_s` string COMMENT '业务类型'
--   ,`digv_flow` string COMMENT '流量版本'
--   ,`digv_b` string COMMENT '出人策略'
--   ,`digv_g` string COMMENT 'A/B实验标记'
--   ,`digv_rid` string COMMENT '唯一追溯'
--   ,`digv_sid` string COMMENT '订单号'
--   ,`commercial_union_key` string COMMENT '商机信息联合键'
--   ,`commercial_id` string COMMENT '商机唯一主键id'
--   ,`commercial_couple_id` string COMMENT '商机对id'
--   ,`commercial_user_id` string COMMENT '商机用户id'
--   ,`commercial_city_code` string COMMENT '商机城市编码'
--   ,`is_8_to_22` int COMMENT '是否8到22点'
--   ,`is_coop_cdel_commercial` int COMMENT '是否合作客商机'
--   ,`duid` string COMMENT '数盟id'
--   ,`battle_region_code` string COMMENT '战区编码'
--   ,`battle_region_name` string COMMENT '战区名'
--   ,`province_region_code` string COMMENT '省区编码'
--   ,`province_region_name` string COMMENT '省区名'
--   ,`major_ucid` bigint COMMENT '总监ucid'
--   ,`major_name` string COMMENT '总监'
--   ,`ca_ucid` bigint COMMENT '运营人员ucid'
--   ,`ca_name` string COMMENT '运营人员'
--   ,`job_level_name` string COMMENT '职级名称'
--   ,`battle_leader_ucid` bigint COMMENT '作战小组组长'
--   ,`battle_leader_name` string COMMENT '作战小组组长姓名'
--   ,`is_del_housedel` int COMMENT '商机用户是否委托房源'
--   ,`del_housedel_id` bigint COMMENT '商机用户委托房源编码'
--   ,`parent_scene_id` string COMMENT 'parentSceneId'
--   ,`is_invalid` int COMMENT '是否无效商机'
--   ,`first_deal_business_name` string COMMENT '首次成交业务名称'
--   ,`commercial_channel_type_name` string COMMENT '商机渠道类型名称'
--   ,`is_reserved_capital_recall` bigint COMMENT '是否留资商机回拨'
--   ,`reserved_capital_recall_time` string COMMENT '留资商机回拨时间'
--   ,`content_sj_type` string COMMENT '内容商机类型：booth=展位 trace=溯源 protect=保护'
-- )
-- partitioned by (pt string)
-- ROW FORMAT DELIMITED
-- FIELDS TERMINATED BY '\u0001'
-- COLLECTION ITEMS TERMINATED BY '\u0002'
-- MAP KEYS TERMINATED BY '\u0003'
-- STORED AS orc
-- LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_content_sj_trans_detail_da'
-- ============================================================

set hive.exec.orc.split.strategy=BI;
set hive.auto.convert.join = true;
set hive.mapjoin.smalltable.filesize=300000000;
set hive.auto.convert.join.noconditionaltask = true;
set hive.auto.convert.join.noconditionaltask.size = 500000000;

WITH sj_base AS (
    SELECT
        t1.source_key_id
                ,t1.occur_time
                ,t1.occur_date
                ,t1.commercial_type_code
                ,t1.commercial_type_name
                ,t1.website_code
                ,t1.website_name
                ,t1.client_code
                ,t1.client_name
                ,t1.business_code
                ,t1.business_name
                ,t1.cust_phone_encrypt
                ,t1.cust_ucid
                ,t1.cust_phone
                ,t1.agent_ucid
                ,t1.agent_phone_encrypt
                ,t1.agent_phone
                ,t1.housedel_id
                ,t1.project_name
                ,t1.rent_unit_id
                ,t1.layout_id
                ,t1.shh_resblock_id
                ,t1.district_id
                ,t1.bizcircle_id
                ,t1.city_code
                ,t1.city_name
                ,t1.agent_no
                ,t1.agent_name
                ,t1.brand_code
                ,t1.brand_name
                ,t1.alliance_code
                ,t1.alliance_name
                ,t1.corp_code
                ,t1.corp_name
                ,t1.func_code
                ,t1.func_name
                ,t1.region_code
                ,t1.region_name
                ,t1.marketing_code
                ,t1.marketing_name
                ,t1.area_code
                ,t1.area_name
                ,t1.shop_code
                ,t1.shop_name
                ,t1.team_code
                ,t1.team_name
                ,t1.uc_job_id
                ,t1.uc_job_code
                ,t1.uc_job_name
                ,t1.is_cust_send
                ,t1.is_today_newcust
                ,t1.is_thirtydays_occur
                ,t1.is_operational
                ,t1.is_commercial_couple
                ,t1.is_del
                ,t1.is_show
                ,t1.is_deal
                ,t1.custdel_id
                ,t1.cdel_typing_time
                ,t1.showing_id
                ,t1.showing_time
                ,t1.recent_showing_id
                ,t1.recent_showing_time
                ,t1.agreement_id
                ,t1.sign_time
                ,t1.recent_agreement_id
                ,t1.recent_sign_time
                ,t1.session_id
                ,t1.utm_trackid
                ,t1.utm_source
                ,t1.utm_medium
                ,t1.utm_campaign
                ,t1.utm_content
                ,t1.utm_term
                ,t1.device_id
                ,t1.openid
                ,t1.xcx_scene
                ,t1.xcx_source
                ,t1.xcx_type
                ,t1.sub_commercial_source
                ,t1.adid
                ,t1.app_data
                ,t1.port
                ,t1.digv_v
                ,t1.digv_s
                ,t1.digv_flow
                ,t1.digv_b
                ,t1.digv_g
                ,t1.digv_rid
                ,t1.digv_sid
                ,t1.commercial_union_key
                ,t1.commercial_id
                ,t1.commercial_couple_id
                ,t1.commercial_user_id
                ,t1.commercial_city_code
                ,t1.is_8_to_22
                ,t1.is_coop_cdel_commercial
                ,t1.duid
                ,t1.battle_region_code
                ,t1.battle_region_name
                ,t1.province_region_code
                ,t1.province_region_name
                ,t1.major_ucid
                ,t1.major_name
                ,t1.ca_ucid
                ,t1.ca_name
                ,t1.job_level_name
                ,t1.battle_leader_ucid
                ,t1.battle_leader_name
                ,t1.is_del_housedel
                ,t1.del_housedel_id
                ,t1.parent_scene_id
                ,t1.is_invalid
                ,t1.first_deal_business_name
                ,t1.commercial_channel_type_name
                ,t1.is_reserved_capital_recall
                ,t1.reserved_capital_recall_time
    FROM rpt.rpt_asm_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.business_name IN ('二手', '新房')
      AND t1.is_commercial_couple = 1
      AND t1.website_name = '贝壳'
      AND t1.client_name = 'app'
      AND t1.commercial_id IS NOT NULL
      AND t1.commercial_id NOT IN ('-911', 'null')
      AND t1.commercial_couple_id IS NOT NULL
      AND t1.commercial_couple_id NOT IN ('-911', 'null')
)
,booth_id AS (
    SELECT
        t1.commercial_id                        AS commercial_id
    FROM sj_base t1
    WHERE t1.adid IN (
          100014625, 100014626, 100014627, 100014471, 100014469
          ,100014470, 100014886, 100012754, 100012753, 100017529
          ,100017615, 100017738, 100017736, 100017739
          ,100012284, 100012285, 100014885, 100012752, 100012751
          ,100012750, 100017528, 100017614, 100017737, 100017740
          ,100017741
      )
    GROUP BY
        t1.commercial_id
)
,sy AS (
    SELECT
        concat_ws('-', substr(t1.pt, 1, 4), substr(t1.pt, 5, 2), substr(t1.pt, 7, 2)) AS stat_date
        ,t1.commercial_id                        AS commercial_id
    FROM shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di t1
    WHERE t1.pt <= '${-1d_pt}'
      AND t1.business_name IN ('二手', '新房')
      AND lower(t1.uicode) IN (
          'community/shipindetail'
          ,'new_kandian_article'
      )
      AND t1.distance BETWEEN 1 AND 7
      AND t1.commercial_id IS NOT NULL
      AND t1.commercial_id NOT IN ('-911', 'null')
    GROUP BY
        concat_ws('-', substr(t1.pt, 1, 4), substr(t1.pt, 5, 2), substr(t1.pt, 7, 2))
        ,t1.commercial_id
)
,trace_id AS (
    SELECT
        t2.commercial_id                        AS commercial_id
    FROM sy t1
    INNER JOIN sj_base t2
      ON t1.commercial_id = t2.commercial_id
     AND t1.stat_date = substr(t2.occur_date, 1, 10)
    GROUP BY
        t2.commercial_id
)
,protect_id AS (
    SELECT
        t2.commercial_id                        AS commercial_id
    FROM rpt.rpt_asm_sj_detail_di t1
    INNER JOIN sj_base t2
      ON t1.commercial_id = t2.commercial_id
    WHERE t1.pt = '${-1d_pt}'
      AND t1.is_commercial_couple = 1
      AND t1.digv_b IN (
          'AdProtectBuilder_content_live_protect_sell_house'
          ,'AdProtectBuilder_content_live_protect_nh_project'
          ,'AdProtectBuilder_content_live_protect_sell_resblock'
      )
      AND t1.commercial_id IS NOT NULL
      AND t1.commercial_id NOT IN ('-911', 'null')
    GROUP BY
        t2.commercial_id
)
,content_sj_type_map AS (
    SELECT commercial_id, 'booth' AS content_sj_type FROM booth_id
    UNION ALL
    SELECT commercial_id, 'trace' AS content_sj_type FROM trace_id
    UNION ALL
    SELECT commercial_id, 'protect' AS content_sj_type FROM protect_id
)
INSERT OVERWRITE TABLE rpt.rpt_content_sj_trans_detail_da PARTITION (pt='${-1d_pt}')
SELECT
    t1.source_key_id
        ,t1.occur_time
        ,t1.occur_date
        ,t1.commercial_type_code
        ,t1.commercial_type_name
        ,t1.website_code
        ,t1.website_name
        ,t1.client_code
        ,t1.client_name
        ,t1.business_code
        ,t1.business_name
        ,t1.cust_phone_encrypt
        ,t1.cust_ucid
        ,t1.cust_phone
        ,t1.agent_ucid
        ,t1.agent_phone_encrypt
        ,t1.agent_phone
        ,t1.housedel_id
        ,t1.project_name
        ,t1.rent_unit_id
        ,t1.layout_id
        ,t1.shh_resblock_id
        ,t1.district_id
        ,t1.bizcircle_id
        ,t1.city_code
        ,t1.city_name
        ,t1.agent_no
        ,t1.agent_name
        ,t1.brand_code
        ,t1.brand_name
        ,t1.alliance_code
        ,t1.alliance_name
        ,t1.corp_code
        ,t1.corp_name
        ,t1.func_code
        ,t1.func_name
        ,t1.region_code
        ,t1.region_name
        ,t1.marketing_code
        ,t1.marketing_name
        ,t1.area_code
        ,t1.area_name
        ,t1.shop_code
        ,t1.shop_name
        ,t1.team_code
        ,t1.team_name
        ,t1.uc_job_id
        ,t1.uc_job_code
        ,t1.uc_job_name
        ,t1.is_cust_send
        ,t1.is_today_newcust
        ,t1.is_thirtydays_occur
        ,t1.is_operational
        ,t1.is_commercial_couple
        ,t1.is_del
        ,t1.is_show
        ,t1.is_deal
        ,t1.custdel_id
        ,t1.cdel_typing_time
        ,t1.showing_id
        ,t1.showing_time
        ,t1.recent_showing_id
        ,t1.recent_showing_time
        ,t1.agreement_id
        ,t1.sign_time
        ,t1.recent_agreement_id
        ,t1.recent_sign_time
        ,t1.session_id
        ,t1.utm_trackid
        ,t1.utm_source
        ,t1.utm_medium
        ,t1.utm_campaign
        ,t1.utm_content
        ,t1.utm_term
        ,t1.device_id
        ,t1.openid
        ,t1.xcx_scene
        ,t1.xcx_source
        ,t1.xcx_type
        ,t1.sub_commercial_source
        ,t1.adid
        ,t1.app_data
        ,t1.port
        ,t1.digv_v
        ,t1.digv_s
        ,t1.digv_flow
        ,t1.digv_b
        ,t1.digv_g
        ,t1.digv_rid
        ,t1.digv_sid
        ,t1.commercial_union_key
        ,t1.commercial_id
        ,t1.commercial_couple_id
        ,t1.commercial_user_id
        ,t1.commercial_city_code
        ,t1.is_8_to_22
        ,t1.is_coop_cdel_commercial
        ,t1.duid
        ,t1.battle_region_code
        ,t1.battle_region_name
        ,t1.province_region_code
        ,t1.province_region_name
        ,t1.major_ucid
        ,t1.major_name
        ,t1.ca_ucid
        ,t1.ca_name
        ,t1.job_level_name
        ,t1.battle_leader_ucid
        ,t1.battle_leader_name
        ,t1.is_del_housedel
        ,t1.del_housedel_id
        ,t1.parent_scene_id
        ,t1.is_invalid
        ,t1.first_deal_business_name
        ,t1.commercial_channel_type_name
        ,t1.is_reserved_capital_recall
        ,t1.reserved_capital_recall_time
    ,t2.content_sj_type
FROM sj_base t1
INNER JOIN content_sj_type_map t2
  ON t1.commercial_id = t2.commercial_id
;
