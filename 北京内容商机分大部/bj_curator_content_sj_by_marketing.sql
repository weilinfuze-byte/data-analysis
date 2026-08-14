-- ============================================================
-- Project: 北京主理人内容商机 · 按营销大区（大部）汇总结果表
-- 中文名: 北京主理人内容商机按营销大区汇总结果指标表
-- 英文名: rpt.rpt_bj_curator_content_sj_by_marketing_result_di
-- 建表页注意: 库选 rpt 后表名前缀已默认 rpt_，表单只填 bj_curator_content_sj_by_marketing_result_di
-- 工厂表单:
--   库/层级 = rpt
--   表名称 = bj_curator_content_sj_by_marketing_result_di
--   表中文名称 = 北京主理人内容商机按营销大区汇总结果指标表
--   描述 = 北京贝壳App主理人内容商机按营销大区日指标：投稿/生产/流量/三类商机/带看/成交（content_tag=curator_content）
--   执行前需要确认 = 是
-- 表说明: 见同目录 rpt_bj_curator_content_sj_by_marketing_result_di.md
-- Created: 2026-08-14
-- Scope: 贝壳 App，北京市，昨天；仅主理人内容；依赖 rpt_content_sj_trans_detail_da
--        pt = '${-1d_pt}'；业务日 = '${-1d_yyyy-MM-dd}'
--
-- 内容范围: 生产表 array_contains(content_tag, 'curator_content')
-- 粒度: 统计日期 × 营销大区（marketing_name）
-- 输出: 投稿人数、内容生产量、详情页流量、三类商机量、商机带看、商机成交
--
-- 商机来源: rpt.rpt_content_sj_trans_detail_da（三类已打标 content_sj_type）
-- 内容归因: parent_scene_id = 详情页 scene_id → content_id（仅主理人内容）
--
-- 商机带看量 / 商机成交量（metrics/commerce.md 人店匹配）:
--   ≠ 工厂 is_show / is_deal
--   历史主理人内容商机对 × 昨天有效带看/成交，客户+经纪人对齐，带看/成交日 >= 商机日
--
-- 生产→员工: im_ucid（经纪人 ucid）= employee_ucid
-- Style: SELECT 逗号前置; 表别名 t1/t2; 落表英文列名
-- ============================================================
-- 建表语句:
-- CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_bj_curator_content_sj_by_marketing_result_di (
--   `stat_date` string COMMENT '统计日期'
--   ,`marketing_name` string COMMENT '营销大区'
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
-- LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_bj_curator_content_sj_by_marketing_result_di'
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
        ,t1.title                              AS title
        ,t1.resource_type                      AS resource_type
        ,to_date(t1.publish_time)              AS publish_date
    FROM rpt.rpt_feed_content_analyze_table t1
    WHERE t1.pt = '${-1d_pt}'
      AND cast(t1.city_id AS string) = '110000'
      AND t1.status = 4
      AND t1.content_id IS NOT NULL
      AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
      AND t1.publish_time IS NOT NULL
      AND t1.publish_time NOT LIKE '1970%'
      AND to_date(t1.publish_time) = '${-1d_yyyy-MM-dd}'
      AND array_contains(t1.content_tag, 'curator_content')
)
,content_dim AS (
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
      AND array_contains(t1.content_tag, 'curator_content')
)
,agent_org AS (
    SELECT
        cast(t1.employee_ucid AS string)       AS agent_ucid
        ,t1.employee_no                        AS employee_no
        ,t1.employee_name                      AS employee_name
        ,t1.marketing_code                     AS marketing_code
        ,t1.marketing_name                     AS marketing_name
    FROM rpt.rpt_comm_agent_allinfo_employee_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.city_name = '北京市'
      AND t1.employee_ucid IS NOT NULL
      AND cast(t1.employee_ucid AS string) NOT IN ('-911', 'null')
    GROUP BY
        cast(t1.employee_ucid AS string)
        ,t1.employee_no
        ,t1.employee_name
        ,t1.marketing_code
        ,t1.marketing_name
)
,content_enriched AS (
    SELECT
        t1.content_id
        ,t1.agent_ucid
        ,t1.title
        ,t1.resource_type
        ,t1.publish_date
        ,coalesce(t2.marketing_name, '未匹配大部') AS marketing_name
        ,t2.employee_no
        ,t2.employee_name
    FROM content_base t1
    LEFT JOIN agent_org t2
      ON t1.agent_ucid = t2.agent_ucid
)
,content_dim_enriched AS (
    SELECT
        t1.content_id
        ,coalesce(t2.marketing_name, '未匹配大部') AS marketing_name
    FROM content_dim t1
    LEFT JOIN agent_org t2
      ON t1.agent_ucid = t2.agent_ucid
)
,content_scene AS (
    SELECT
        t1.scene_id                             AS scene_id
        ,coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
        )                                      AS content_id
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
      AND t1.scene_id IS NOT NULL
      AND t1.scene_id NOT IN ('-911', 'null')
    GROUP BY
        t1.scene_id
        ,coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
        )
)
,content_scene_all AS (
    SELECT
        t1.scene_id                             AS scene_id
        ,coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
        )                                      AS content_id
    FROM rpt.rpt_content_detail_flow_di t1
    INNER JOIN content_dim t2
      ON coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
         ) = t2.content_id
    WHERE t1.pt <= '${-1d_pt}'
      AND cast(t1.city_code AS string) = '110000'
      AND lower(t1.uicode) IN (
          'community/shipindetail'
          ,'new_kandian_article'
      )
      AND (
            (lower(t1.uicode) = 'community/shipindetail' AND t1.evt_id = '57827')
         OR (lower(t1.uicode) = 'new_kandian_article' AND t1.evt_id = '83538')
      )
      AND t1.scene_id IS NOT NULL
      AND t1.scene_id NOT IN ('-911', 'null')
      AND coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
         ) IS NOT NULL
      AND coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
         ) NOT IN ('-911', 'null')
    GROUP BY
        t1.scene_id
        ,coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
        )
)
,content_traffic AS (
    SELECT
        coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
        )                                      AS content_id
        ,count(1)                              AS detail_expo_pv
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
    GROUP BY
        coalesce(
            if(get_json_object(t1.action, '$.article_id') = '', null, get_json_object(t1.action, '$.article_id'))
            ,if(get_json_object(t1.action, '$.content_id') = '', null, get_json_object(t1.action, '$.content_id'))
        )
)
,content_sj_daily AS (
    SELECT
        t1.commercial_couple_id
        ,t1.content_sj_type                    AS sj_type
        ,t1.parent_scene_id
    FROM rpt.rpt_content_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND substr(t1.occur_date, 1, 10) = '${-1d_yyyy-MM-dd}'
      AND t1.city_code = 110000
      AND t1.commercial_couple_id IS NOT NULL
      AND t1.commercial_couple_id NOT IN ('-911', 'null')
    GROUP BY
        t1.commercial_couple_id
        ,t1.content_sj_type
        ,t1.parent_scene_id
)
,sj_union AS (
    SELECT
        t2.content_id
        ,t1.commercial_couple_id
        ,t1.sj_type
    FROM content_sj_daily t1
    INNER JOIN content_scene t2
      ON t1.parent_scene_id = t2.scene_id
    GROUP BY
        t2.content_id
        ,t1.commercial_couple_id
        ,t1.sj_type
)
,content_sj_hist AS (
    SELECT
        substr(t1.occur_date, 1, 10)           AS occur_date
        ,t1.commercial_couple_id
        ,t1.parent_scene_id
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
        ,t1.parent_scene_id
        ,t1.cust_ucid
        ,t1.agent_ucid
)
,sj_union_hist AS (
    SELECT
        t2.content_id
        ,t1.commercial_couple_id
        ,t1.cust_ucid
        ,t1.agent_ucid
        ,t1.occur_date
    FROM content_sj_hist t1
    INNER JOIN content_scene_all t2
      ON t1.parent_scene_id = t2.scene_id
    GROUP BY
        t2.content_id
        ,t1.commercial_couple_id
        ,t1.cust_ucid
        ,t1.agent_ucid
        ,t1.occur_date
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
,sj_show_matched AS (
    SELECT
        t1.content_id
        ,t1.commercial_couple_id
    FROM sj_union_hist t1
    INNER JOIN show_raw t2
      ON t1.cust_ucid = t2.ucid
     AND t1.agent_ucid = t2.agent_ucid
     AND t2.showing_date >= t1.occur_date
    GROUP BY
        t1.content_id
        ,t1.commercial_couple_id
)
,sj_deal_matched AS (
    SELECT
        t1.content_id
        ,t1.commercial_couple_id
    FROM sj_union_hist t1
    INNER JOIN deal_raw t2
      ON t1.cust_ucid = t2.ucid
     AND t1.agent_ucid = t2.agent_ucid
     AND t2.deal_date >= t1.occur_date
    GROUP BY
        t1.content_id
        ,t1.commercial_couple_id
)
,produce_metric AS (
    SELECT
        t1.marketing_name
        ,count(DISTINCT t1.agent_ucid)          AS contributor_cnt
        ,count(DISTINCT t1.content_id)          AS content_cnt
    FROM content_enriched t1
    GROUP BY
        t1.marketing_name
)
,traffic_metric AS (
    SELECT
        t1.marketing_name
        ,sum(coalesce(t2.detail_expo_pv, 0))    AS traffic_pv
        ,sum(coalesce(t2.detail_expo_uv, 0))    AS traffic_uv
    FROM content_enriched t1
    LEFT JOIN content_traffic t2
      ON t1.content_id = t2.content_id
    GROUP BY
        t1.marketing_name
)
,sj_marketing AS (
    SELECT
        t1.marketing_name
        ,count(DISTINCT CASE WHEN t2.sj_type = 'booth' THEN t2.commercial_couple_id END)
                                                AS sj_booth_cnt
        ,count(DISTINCT CASE WHEN t2.sj_type = 'trace' THEN t2.commercial_couple_id END)
                                                AS sj_trace_cnt
        ,count(DISTINCT CASE WHEN t2.sj_type = 'protect' THEN t2.commercial_couple_id END)
                                                AS sj_protect_cnt
        ,count(DISTINCT t2.commercial_couple_id) AS sj_total_cnt
    FROM content_enriched t1
    INNER JOIN sj_union t2
      ON t1.content_id = t2.content_id
    GROUP BY
        t1.marketing_name
)
,show_marketing AS (
    SELECT
        t2.marketing_name
        ,count(DISTINCT t1.commercial_couple_id) AS sj_show_cnt
    FROM sj_show_matched t1
    INNER JOIN content_dim_enriched t2
      ON t1.content_id = t2.content_id
    GROUP BY
        t2.marketing_name
)
,deal_marketing AS (
    SELECT
        t2.marketing_name
        ,count(DISTINCT t1.commercial_couple_id) AS sj_deal_cnt
    FROM sj_deal_matched t1
    INNER JOIN content_dim_enriched t2
      ON t1.content_id = t2.content_id
    GROUP BY
        t2.marketing_name
)
,marketing_base AS (
    SELECT marketing_name FROM produce_metric
    UNION
    SELECT marketing_name FROM show_marketing
    UNION
    SELECT marketing_name FROM deal_marketing
)
INSERT OVERWRITE TABLE rpt.rpt_bj_curator_content_sj_by_marketing_result_di PARTITION (pt='${-1d_pt}')
SELECT
    '${-1d_yyyy-MM-dd}'                        AS stat_date
    ,t0.marketing_name                         AS marketing_name
    ,coalesce(t1.contributor_cnt, 0)           AS contributor_cnt
    ,coalesce(t1.content_cnt, 0)               AS content_cnt
    ,coalesce(t2.traffic_pv, 0)                AS detail_expo_pv
    ,coalesce(t2.traffic_uv, 0)                AS detail_expo_uv
    ,coalesce(t3.sj_booth_cnt, 0)              AS sj_booth_cnt
    ,coalesce(t3.sj_trace_cnt, 0)              AS sj_trace_cnt
    ,coalesce(t3.sj_protect_cnt, 0)            AS sj_protect_cnt
    ,coalesce(t3.sj_total_cnt, 0)              AS sj_total_cnt
    ,coalesce(t4.sj_show_cnt, 0)               AS sj_show_cnt
    ,coalesce(t5.sj_deal_cnt, 0)               AS sj_deal_cnt
FROM marketing_base t0
LEFT JOIN produce_metric t1
  ON t0.marketing_name = t1.marketing_name
LEFT JOIN traffic_metric t2
  ON t0.marketing_name = t2.marketing_name
LEFT JOIN sj_marketing t3
  ON t0.marketing_name = t3.marketing_name
LEFT JOIN show_marketing t4
  ON t0.marketing_name = t4.marketing_name
LEFT JOIN deal_marketing t5
  ON t0.marketing_name = t5.marketing_name
;
