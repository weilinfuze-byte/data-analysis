-- ============================================================
-- Project: 搜索结果页流量表
-- 中文名: 搜索结果页内容流量表
-- 英文名: rpt.rpt_content_search_result_flow_di
-- 建表页注意: 库选 rpt 后表名前缀已默认 rpt_，表单只填 content_search_result_flow_di
-- 表说明: 见同目录 rpt_content_search_result_flow_di.md
-- 【表描述 / 数据工厂描述】
-- 底层曝光/点击流量表太大，本表从中捞出「搜索结果页」所有内容卡片相关埋点明细，仅贝壳 App。
-- 页面: 首页搜索 zonghesousuo/jieguo、二手搜索 ershousousuo/jieguo（埋点相同，用 uicode 区分）
-- 覆盖：综合tab竖卡/横卡、内容tab（含历史评测）、旧横卡93750/93751、页览1,3/1,4。
-- tab_name/module_type及内容参数已预解析落表。一级分类先取 show_card_type，空则 93750/93751 用 fb_item_type、其余用 item_type。
-- Updated: 2026-10-14
-- Scope: site=beike, dp=app, 事件明细（不聚合）
-- 内容卡片口径:
--   综合tab-底部竖卡: 80326/80327 + tab_name=综合 + module_type=contentFeed
--   综合tab-横卡(0806+): 80326/80327 + tab_name=综合 + module_type=contentCardModule
--   内容tab(0709+，原评测): 80326/80327 + tab_name IN (内容,评测) + module_type=contentFeed
--   旧横卡(0806前): 93750/93751 → 落表 tab_name=综合, module_type=contentCardModule
-- 页览: 1,3 / 1,4（行为表）
-- action 参数映射（按 evt_id 区分两套 key，落表统一列名）:
--   一级分类 item_type: 先 $.show_card_type；空(NULL/''/-911/null)再按 evt 回退
--     93750/93751 → $.fb_item_type；其他 → $.item_type
--   80326/80327: content_id ← $.fb_item_id
--   93750/93751: content_id ← $.content_id
-- 解析位置: 过滤条件在 UNION 分支 WHERE；落表字段在最终 SELECT（行数已收窄，Tez 更省）
-- Style: SELECT 逗号前置; 表别名 t1; 英文列名
-- ============================================================
-- 建表语句:
-- CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_content_search_result_flow_di (
--   `active_date` string COMMENT '活跃日期'
--   ,`dp` string COMMENT '端'
--   ,`site` string COMMENT '站点'
--   ,`uicode` string COMMENT '页面标识'
--   ,`pid` string COMMENT '业务线标识'
--   ,`evt_id` string COMMENT '事件ID'
--   ,`evt_name` string COMMENT '事件名称'
--   ,`evt_type` string COMMENT '事件类型'
--   ,`action` string COMMENT '埋点事件参数Json'
--   ,`duid` string COMMENT 'duid'
--   ,`ucid` string COMMENT 'ucid'
--   ,`client_time` string COMMENT '客户端请求时间'
--   ,`client_timestamp` string COMMENT '客户端请求时间戳'
--   ,`client_os_type` string COMMENT '客户端操作系统类型'
--   ,`client_os_version` string COMMENT '客户端操作系统版本'
--   ,`client_app_version` string COMMENT '客户端app版本'
--   ,`city_code` string COMMENT '城市编码'
--   ,`city_name` string COMMENT '城市名称'
--   ,`business_name` string COMMENT '业务线名称'
--   ,`dig_ssid` string COMMENT '会话ID'
--   ,`scene_id` string COMMENT '场景id'
--   ,`parent_scene_id` string COMMENT '父场景id'
--   ,`json_data` string COMMENT '埋点事件参数Json'
--   ,`dig_url` string COMMENT '埋点上报地址'
--   ,`is_dau` tinyint COMMENT '是否用于整站dau计算（曝光侧为空）'
--   ,`tab_name` string COMMENT '一级tab'
--   ,`module_type` string COMMENT '模块类型/卡片类型'
--   ,`item_type` string COMMENT '一级分类(show_card_type空则按evt回退)'
--   ,`card_type` string COMMENT '二级分类'
--   ,`share_media` string COMMENT '内容体裁'
--   ,`action_date` string COMMENT '发布时间'
--   ,`fb_expo_id` string COMMENT '后端曝光唯一ID'
--   ,`content_id` string COMMENT '内容id'
--   ,`content_tag` string COMMENT '内容标签'
--   ,`beike_id` string COMMENT '贝壳号id'
--   ,`agent_ucid` string COMMENT '经纪人id'
-- )
-- partitioned by (pt string)
-- ROW FORMAT DELIMITED
-- FIELDS TERMINATED BY '\u0001'
-- COLLECTION ITEMS TERMINATED BY '\u0002'
-- MAP KEYS TERMINATED BY '\u0003'
-- STORED AS orc
-- LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_content_search_result_flow_di'
-- ============================================================

set hive.exec.orc.split.strategy=BI;
set hive.auto.convert.join = true;
set hive.mapjoin.smalltable.filesize=300000000;
set hive.auto.convert.join.noconditionaltask = true;
set hive.auto.convert.join.noconditionaltask.size = 500000000;

WITH click_raw AS (
    SELECT
        t1.active_date                         AS active_date
        ,t1.dp                                 AS dp
        ,t1.site                               AS site
        ,t1.uicode                             AS uicode
        ,t1.pid                                AS pid
        ,t1.evt_id                             AS evt_id
        ,t1.evt_name                           AS evt_name
        ,t1.evt_type                           AS evt_type
        ,t1.action                             AS action
        ,t1.duid                               AS duid
        ,t1.ucid                               AS ucid
        ,t1.client_time                        AS client_time
        ,t1.client_timestamp                   AS client_timestamp
        ,t1.client_os_type                     AS client_os_type
        ,t1.client_os_version                  AS client_os_version
        ,t1.client_app_version                 AS client_app_version
        ,t1.city_code                          AS city_code
        ,t1.city_name                          AS city_name
        ,t1.business_name                      AS business_name
        ,t1.dig_ssid                           AS dig_ssid
        ,t1.scene_id                           AS scene_id
        ,t1.parent_scene_id                    AS parent_scene_id
        ,t1.json_data                          AS json_data
        ,t1.dig_url                            AS dig_url
        ,t1.is_dau                             AS is_dau
    FROM rpt.rpt_log_bi_user_behivor_detail_flow_di t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.site = 'beike'
      AND t1.dp = 'app'
      AND lower(t1.uicode) IN (
            'zonghesousuo/jieguo'   -- 首页搜索
            ,'ershousousuo/jieguo'  -- 二手搜索
      )
      AND t1.evt_id IN (
            '80327'
            ,'93751'
            ,'1,3'
            ,'1,4'
      )
)
,expo_raw AS (
    SELECT
        t1.active_date                         AS active_date
        ,t1.dp                                 AS dp
        ,'beike'                               AS site
        ,t1.uicode                             AS uicode
        ,t1.pid                                AS pid
        ,t1.evt_id                             AS evt_id
        ,t1.evt_name                           AS evt_name
        ,t1.evt_type                           AS evt_type
        ,t1.action                             AS action
        ,t1.duid                               AS duid
        ,t1.ucid                               AS ucid
        ,t1.client_time                        AS client_time
        ,t1.client_timestamp                   AS client_timestamp
        ,t1.client_os_type                     AS client_os_type
        ,t1.client_os_version                  AS client_os_version
        ,t1.client_app_version                 AS client_app_version
        ,t1.city_code                          AS city_code
        ,t1.city_name                          AS city_name
        ,t1.business_name                      AS business_name
        ,t1.dig_ssid                           AS dig_ssid
        ,t1.scene_id                           AS scene_id
        ,t1.parent_scene_id                    AS parent_scene_id
        ,t1.json_data                          AS json_data
        ,t1.dig_url                            AS dig_url
        ,null                                  AS is_dau
    FROM rpt.rpt_comm_log_beike_exp_detail_di t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.dp = 'app'
      AND lower(t1.uicode) IN (
            'zonghesousuo/jieguo'   -- 首页搜索
            ,'ershousousuo/jieguo'  -- 二手搜索
      )
      AND t1.evt_id IN (
            '80326'
            ,'93750'
      )
)
,search_result_flow AS (
    -- 页览 1,3 / 1,4
    SELECT
        t1.*
    FROM click_raw t1
    WHERE t1.evt_id IN ('1,3', '1,4')

    UNION ALL

    -- 综合tab-底部竖卡 contentFeed 点击
    SELECT
        t1.*
    FROM click_raw t1
    WHERE t1.evt_id = '80327'
      AND get_json_object(t1.action, '$.tab_name') = '综合'
      AND get_json_object(t1.action, '$.module_type') = 'contentFeed'

    UNION ALL

    -- 综合tab-底部竖卡 contentFeed 曝光
    SELECT
        t1.*
    FROM expo_raw t1
    WHERE t1.evt_id = '80326'
      AND get_json_object(t1.action, '$.tab_name') = '综合'
      AND get_json_object(t1.action, '$.module_type') = 'contentFeed'

    UNION ALL

    -- 综合tab-横卡 contentCardModule 点击（0806+）
    SELECT
        t1.*
    FROM click_raw t1
    WHERE t1.evt_id = '80327'
      AND get_json_object(t1.action, '$.tab_name') = '综合'
      AND get_json_object(t1.action, '$.module_type') = 'contentCardModule'

    UNION ALL

    -- 综合tab-横卡 contentCardModule 曝光（0806+）
    SELECT
        t1.*
    FROM expo_raw t1
    WHERE t1.evt_id = '80326'
      AND get_json_object(t1.action, '$.tab_name') = '综合'
      AND get_json_object(t1.action, '$.module_type') = 'contentCardModule'

    UNION ALL

    -- 内容tab contentFeed 点击（0709+；历史含评测tab）
    SELECT
        t1.*
    FROM click_raw t1
    WHERE t1.evt_id = '80327'
      AND get_json_object(t1.action, '$.tab_name') IN ('内容', '评测')
      AND get_json_object(t1.action, '$.module_type') = 'contentFeed'

    UNION ALL

    -- 内容tab contentFeed 曝光（0709+；历史含评测tab）
    SELECT
        t1.*
    FROM expo_raw t1
    WHERE t1.evt_id = '80326'
      AND get_json_object(t1.action, '$.tab_name') IN ('内容', '评测')
      AND get_json_object(t1.action, '$.module_type') = 'contentFeed'

    UNION ALL

    -- 旧横卡点击（0806前）
    SELECT
        t1.*
    FROM click_raw t1
    WHERE t1.evt_id = '93751'

    UNION ALL

    -- 旧横卡曝光（0806前）
    SELECT
        t1.*
    FROM expo_raw t1
    WHERE t1.evt_id = '93750'
)
INSERT OVERWRITE TABLE rpt.rpt_content_search_result_flow_di PARTITION (pt='${-1d_pt}')
SELECT
    t1.active_date
    ,t1.dp
    ,t1.site
    ,t1.uicode
    ,t1.pid
    ,t1.evt_id
    ,t1.evt_name
    ,t1.evt_type
    ,t1.action
    ,t1.duid
    ,t1.ucid
    ,t1.client_time
    ,t1.client_timestamp
    ,t1.client_os_type
    ,t1.client_os_version
    ,t1.client_app_version
    ,t1.city_code
    ,t1.city_name
    ,t1.business_name
    ,t1.dig_ssid
    ,t1.scene_id
    ,t1.parent_scene_id
    ,t1.json_data
    ,t1.dig_url
    ,t1.is_dau
    ,CASE
         WHEN t1.evt_id IN ('93750', '93751') THEN '综合'
         ELSE get_json_object(t1.action, '$.tab_name')
     END                                          AS tab_name
    ,CASE
         WHEN t1.evt_id IN ('93750', '93751') THEN 'contentCardModule'
         ELSE get_json_object(t1.action, '$.module_type')
     END                                          AS module_type
    ,CASE
         WHEN get_json_object(t1.action, '$.show_card_type') IS NOT NULL
          AND get_json_object(t1.action, '$.show_card_type') NOT IN ('', '-911', 'null')
         THEN get_json_object(t1.action, '$.show_card_type')
         WHEN t1.evt_id IN ('93750', '93751')
         THEN get_json_object(t1.action, '$.fb_item_type')
         ELSE get_json_object(t1.action, '$.item_type')
     END                                          AS item_type
    ,get_json_object(t1.action, '$.card_type')      AS card_type
    ,get_json_object(t1.action, '$.share_media')    AS share_media
    ,get_json_object(t1.action, '$.action_date')    AS action_date
    ,get_json_object(t1.action, '$.fb_expo_id')     AS fb_expo_id
    ,CASE
         WHEN t1.evt_id IN ('93750', '93751')
         THEN get_json_object(t1.action, '$.content_id')
         ELSE get_json_object(t1.action, '$.fb_item_id')
     END                                          AS content_id
    ,get_json_object(t1.action, '$.content_title')  AS content_tag
    ,get_json_object(t1.action, '$.beike_id')       AS beike_id
    ,get_json_object(t1.action, '$.agent_ucid')     AS agent_ucid
FROM search_result_flow t1
;
