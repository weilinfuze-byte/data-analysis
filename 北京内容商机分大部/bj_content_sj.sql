-- ============================================================
-- Project: 北京内容商机 · 全市日汇总结果表（不分大部）
-- 中文名: 北京内容商机汇总结果指标表
-- 英文名: rpt.rpt_bj_content_sj_result_di
-- 建表页注意: 库选 rpt 后表名前缀已默认 rpt_，表单只填 bj_content_sj_result_di
-- 工厂表单:
--   库/层级 = rpt
--   表名称 = bj_content_sj_result_di
--   表中文名称 = 北京内容商机汇总结果指标表
--   描述 = 北京贝壳App内容日指标（全市、不分大部）：投稿/生产/流量/三类商机/带看/成交
--   执行前需要确认 = 是
-- 表说明: 见同目录 rpt_bj_content_sj_result_di.md
-- Created: 2026-08-14
-- Scope: 贝壳 App，北京市，昨天；依赖 rpt_content_sj_trans_detail_da
--        pt = '${-1d_pt}'；业务日 = '${-1d_yyyy-MM-dd}'
--
-- 粒度: 统计日期（全市 1 行）
-- 输出: 投稿人数、内容生产量、详情页流量、三类商机量、商机带看、商机成交
--
-- 投稿/生产/流量: 昨天新上线北京内容（含 im_ucid 为空）
-- 内容商机: 中间表全市计数，不要求 parent_scene_id 归因内容
-- 商机带看量 / 商机成交量（metrics/commerce.md 人店匹配）:
--   ≠ 工厂 is_show / is_deal
--   历史全部内容商机对 × 昨天有效带看/成交，客户+经纪人对齐，带看/成交日 >= 商机日
--
-- Style: SELECT 逗号前置; 表别名 t1/t2; 落表英文列名
-- ============================================================
-- 建表语句:
-- CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_bj_content_sj_result_di (
--   `stat_date` string COMMENT '统计日期'
--   ,`contributor_cnt` bigint COMMENT '投稿人数'
--   ,`content_cnt` bigint COMMENT '内容生产量'
--   ,`detail_expo_pv` bigint COMMENT '内容详情页曝光量'
--   ,`detail_expo_uv` bigint COMMENT '内容详情页曝光人数'
--   ,`sj_booth_cnt` bigint COMMENT '展位商机量'
--   ,`sj_trace_cnt` bigint COMMENT '溯源商机量'
--   ,`sj_protect_cnt` bigint COMMENT '保护商机量'
--   ,`sj_total_cnt` bigint COMMENT '内容商机量'
--   ,`sj_show_cnt` bigint COMMENT '内容商机带看量'
--   ,`sj_deal_cnt` bigint COMMENT '内容商机成交量'
-- )
-- partitioned by (pt string)
-- ROW FORMAT DELIMITED
-- FIELDS TERMINATED BY '\u0001'
-- COLLECTION ITEMS TERMINATED BY '\u0002'
-- MAP KEYS TERMINATED BY '\u0003'
-- STORED AS orc
-- LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_bj_content_sj_result_di'
-- ============================================================

set hive.exec.orc.split.strategy=BI;
set hive.auto.convert.join = true;
set hive.mapjoin.smalltable.filesize=300000000;
set hive.auto.convert.join.noconditionaltask = true;
set hive.auto.convert.join.noconditionaltask.size = 500000000;

WITH content_base AS (
    SELECT
        cast(t1.content_id AS string)          AS content_id
        ,if(trim(t1.im_ucid) = '', null, trim(t1.im_ucid))
                                               AS agent_ucid
    FROM rpt.rpt_feed_content_analyze_table t1
    WHERE t1.pt = '${-1d_pt}'
      AND cast(t1.city_id AS string) = '110000'
      AND t1.status = 4
      AND t1.content_id IS NOT NULL
      AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
      AND t1.publish_time IS NOT NULL
      AND t1.publish_time NOT LIKE '1970%'
      AND to_date(t1.publish_time) = '${-1d_yyyy-MM-dd}'
)
,produce_metric AS (
    SELECT
        count(DISTINCT t1.agent_ucid)          AS contributor_cnt
        ,count(DISTINCT t1.content_id)          AS content_cnt
    FROM content_base t1
)
,content_traffic AS (
    SELECT
        count(1)                               AS detail_expo_pv
        ,count(DISTINCT t1.duid)               AS detail_expo_uv
    FROM rpt.rpt_content_detail_flow_di t1
    INNER JOIN content_base t2
      ON coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
         ) = t2.content_id
    WHERE t1.pt = '${-1d_pt}'
      AND cast(t1.city_code AS string) = '110000'
      AND lower(t1.uicode) IN (
          'community/shipindetail'
          ,'new_kandian_article'
      )
      AND (
            (lower(t1.uicode) = 'community/shipindetail' AND t1.evt_id = '57827')
         OR (lower(t1.uicode) = 'new_kandian_article' AND t1.evt_id = '83538')
      )
      AND t1.duid IS NOT NULL
      AND t1.duid NOT IN ('-911', 'null')
)
,sj_metric AS (
    SELECT
        count(DISTINCT CASE WHEN t1.content_sj_type = 'booth' THEN t1.commercial_couple_id END)
                                               AS sj_booth_cnt
        ,count(DISTINCT CASE WHEN t1.content_sj_type = 'trace' THEN t1.commercial_couple_id END)
                                               AS sj_trace_cnt
        ,count(DISTINCT CASE WHEN t1.content_sj_type = 'protect' THEN t1.commercial_couple_id END)
                                               AS sj_protect_cnt
        ,count(DISTINCT t1.commercial_couple_id) AS sj_total_cnt
    FROM rpt.rpt_content_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND substr(t1.occur_date, 1, 10) = '${-1d_yyyy-MM-dd}'
      AND t1.city_code = 110000
      AND t1.commercial_couple_id IS NOT NULL
      AND t1.commercial_couple_id NOT IN ('-911', 'null')
)
,content_sj_hist AS (
    SELECT
        substr(t1.occur_date, 1, 10)           AS occur_date
        ,t1.commercial_couple_id
        ,t1.cust_ucid
        ,t1.agent_ucid
    FROM rpt.rpt_content_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND substr(t1.occur_date, 1, 10) <= '${-1d_yyyy-MM-dd}'
      AND t1.city_code = 110000
      AND t1.commercial_couple_id IS NOT NULL
      AND t1.commercial_couple_id NOT IN ('-911', 'null')
      AND t1.cust_ucid IS NOT NULL
      AND cast(t1.cust_ucid AS string) NOT IN ('-911', 'null')
      AND t1.agent_ucid IS NOT NULL
      AND cast(t1.agent_ucid AS string) NOT IN ('-911', 'null')
    GROUP BY
        substr(t1.occur_date, 1, 10)
        ,t1.commercial_couple_id
        ,t1.cust_ucid
        ,t1.agent_ucid
)
,cust AS (
    SELECT
        t1.custdel_id
        ,t1.customer_uid                                   AS ucid
    FROM dw.dw_cdel_custdel_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.customer_uid IS NOT NULL
      AND t1.customer_uid NOT IN ('-911', '0')
    GROUP BY
        t1.custdel_id
        ,t1.customer_uid
)
,show_raw AS (
    SELECT
        t2.ucid
        ,t1.showagent_ucid                                 AS agent_ucid
        ,t1.showing_date
    FROM (
        SELECT
            custdel_id
            ,showagent_ucid
            ,concat(
                substr(cast(showing_date AS string), 1, 4), '-'
                ,substr(cast(showing_date AS string), 5, 2), '-'
                ,substr(cast(showing_date AS string), 7, 2)
            )                                              AS showing_date
        FROM rpt.rpt_shh_show_showing_housedel_info_da
        WHERE pt = '${-1d_pt}'
          AND del_type_code = '990001001'
          AND is_showing_valid = 1
          AND showagent_ucid IS NOT NULL
          AND showagent_ucid NOT IN ('-911', 'null')
          AND concat(
                substr(cast(showing_date AS string), 1, 4), '-'
                ,substr(cast(showing_date AS string), 5, 2), '-'
                ,substr(cast(showing_date AS string), 7, 2)
            ) = '${-1d_yyyy-MM-dd}'
        GROUP BY
            custdel_id
            ,showagent_ucid
            ,concat(
                substr(cast(showing_date AS string), 1, 4), '-'
                ,substr(cast(showing_date AS string), 5, 2), '-'
                ,substr(cast(showing_date AS string), 7, 2)
            )
    ) t1
    INNER JOIN cust t2
      ON t1.custdel_id = t2.custdel_id

    UNION ALL

    SELECT
        t2.ucid
        ,cast(t1.agent_ucid AS bigint)                     AS agent_ucid
        ,t1.showing_date
    FROM (
        SELECT
            custdel_id
            ,agent_ucid
            ,substr(showing_start_time, 1, 10)             AS showing_date
        FROM rpt.rpt_nh_show_house_showing_info_da
        WHERE pt = '${-1d_pt}'
          AND is_valid = 1
          AND old_showing_create_type NOT IN ('4', '5', '8')
          AND agent_ucid IS NOT NULL
          AND cast(agent_ucid AS string) NOT IN ('-911', 'null')
          AND substr(showing_start_time, 1, 10) = '${-1d_yyyy-MM-dd}'
        GROUP BY
            custdel_id
            ,agent_ucid
            ,substr(showing_start_time, 1, 10)
    ) t1
    INNER JOIN cust t2
      ON t1.custdel_id = t2.custdel_id
)
,deal_raw AS (
    SELECT
        cust_ucid                                          AS ucid
        ,sign_ucid                                         AS agent_ucid
        ,substr(sign_time, 1, 10)                          AS deal_date
    FROM rpt.rpt_shh_rent_deal_agreement_detail_da
    WHERE pt = '${-1d_pt}'
      AND is_parent_agreement = 1
      AND agreement_type_code = '150001001'
      AND is_commit = 1
      AND status_code IN (
          '150005002'
          ,'150005003'
          ,'150005006'
      )
      AND del_type_name = '买卖'
      AND cust_ucid IS NOT NULL
      AND cust_ucid NOT IN ('-911', 'null')
      AND sign_ucid IS NOT NULL
      AND sign_ucid NOT IN ('-911', 'null')
      AND substr(sign_time, 1, 10) = '${-1d_yyyy-MM-dd}'
    GROUP BY
        cust_ucid
        ,sign_ucid
        ,substr(sign_time, 1, 10)

    UNION ALL

    SELECT
        t2.ucid
        ,cast(t1.agent_ucid AS bigint)                     AS agent_ucid
        ,t1.deal_date
    FROM (
        SELECT
            custdel_id
            ,agent_ucid
            ,substr(order_time, 1, 10)                     AS deal_date
        FROM rpt.rpt_nh_output_deal_info_online_custdel_da
        WHERE pt = '${-1d_pt}'
          AND brand_name <> '外渠房江湖'
          AND city_name NOT LIKE '测试%'
          AND is_cancel = 0
          AND agent_ucid IS NOT NULL
          AND cast(agent_ucid AS string) NOT IN ('-911', 'null')
          AND substr(order_time, 1, 10) = '${-1d_yyyy-MM-dd}'
        GROUP BY
            custdel_id
            ,agent_ucid
            ,substr(order_time, 1, 10)
    ) t1
    INNER JOIN cust t2
      ON t1.custdel_id = t2.custdel_id
)
,show_metric AS (
    SELECT
        count(DISTINCT t1.commercial_couple_id) AS sj_show_cnt
    FROM content_sj_hist t1
    INNER JOIN show_raw t2
      ON t1.cust_ucid = t2.ucid
     AND t1.agent_ucid = t2.agent_ucid
     AND t2.showing_date >= t1.occur_date
)
,deal_metric AS (
    SELECT
        count(DISTINCT t1.commercial_couple_id) AS sj_deal_cnt
    FROM content_sj_hist t1
    INNER JOIN deal_raw t2
      ON t1.cust_ucid = t2.ucid
     AND t1.agent_ucid = t2.agent_ucid
     AND t2.deal_date >= t1.occur_date
)
INSERT OVERWRITE TABLE rpt.rpt_bj_content_sj_result_di PARTITION (pt='${-1d_pt}')
SELECT
    '${-1d_yyyy-MM-dd}'                        AS stat_date
    ,coalesce(t1.contributor_cnt, 0)           AS contributor_cnt
    ,coalesce(t1.content_cnt, 0)               AS content_cnt
    ,coalesce(t2.detail_expo_pv, 0)            AS detail_expo_pv
    ,coalesce(t2.detail_expo_uv, 0)            AS detail_expo_uv
    ,coalesce(t3.sj_booth_cnt, 0)              AS sj_booth_cnt
    ,coalesce(t3.sj_trace_cnt, 0)              AS sj_trace_cnt
    ,coalesce(t3.sj_protect_cnt, 0)            AS sj_protect_cnt
    ,coalesce(t3.sj_total_cnt, 0)              AS sj_total_cnt
    ,coalesce(t4.sj_show_cnt, 0)               AS sj_show_cnt
    ,coalesce(t5.sj_deal_cnt, 0)               AS sj_deal_cnt
FROM produce_metric t1
CROSS JOIN content_traffic t2
CROSS JOIN sj_metric t3
CROSS JOIN show_metric t4
CROSS JOIN deal_metric t5
;
