-- ============================================================
-- Query: 北京内容商机 · 经纪人 × 内容明细
-- Project: 北京内容商机分大部
-- Created: 2026-08-14
-- Scope: 同 bj_content_sj_by_marketing.sql（昨天）
--
-- 输出粒度: 营销大区 × 经纪人 × 内容
-- 含: 生产信息、详情页流量、三类商机量（分类型 + 合计）
--
-- 商机来源: rpt.rpt_content_sj_trans_detail_da（三类已打标 content_sj_type）
-- 内容归因: parent_scene_id = 详情页 scene_id → content_id
-- 商机带看/成交: 人店匹配，历史内容商机 × 昨天带看/成交（同汇总 SQL）
-- 生产→员工: im_ucid（经纪人 ucid）= employee_ucid
-- Style: SELECT 逗号前置; 表别名 t1/t2; 中文别名反引号
-- ============================================================

-- ------------------------------------------------------------
-- Query1: 经纪人 × 内容汇总
-- ------------------------------------------------------------
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
)
,agent_org AS (
    SELECT
        cast(t1.employee_ucid AS string)       AS agent_ucid
        ,t1.employee_no                        AS employee_no
        ,t1.employee_name                      AS employee_name
        ,t1.marketing_code                     AS marketing_code
        ,t1.marketing_name                     AS marketing_name
        ,t1.region_name                        AS region_name
        ,t1.area_name                          AS area_name
        ,t1.shop_name                          AS shop_name
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
        ,t1.region_name
        ,t1.area_name
        ,t1.shop_name
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
        ,t2.region_name
        ,t2.area_name
        ,t2.shop_name
    FROM content_base t1
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
    INNER JOIN content_scene t2
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

SELECT
    '${-1d_yyyy-MM-dd}'                        AS `统计日期`
    ,t1.marketing_name                          AS `营销大区`
    ,t1.employee_no                            AS `员工工号`
    ,t1.employee_name                          AS `员工姓名`
    ,t1.agent_ucid                             AS `经纪人ucid`
    ,t1.content_id                             AS `内容id`
    ,t1.title                                  AS `内容标题`
    ,t1.resource_type                          AS `内容类型`
    ,t1.publish_date                           AS `上线日期`
    ,coalesce(t2.detail_expo_pv, 0)            AS `详情页曝光量`
    ,coalesce(t2.detail_expo_uv, 0)            AS `详情页曝光人数`
    ,count(DISTINCT CASE WHEN t3.sj_type = 'booth' THEN t3.commercial_couple_id END)
                                               AS `展位商机量`
    ,count(DISTINCT CASE WHEN t3.sj_type = 'trace' THEN t3.commercial_couple_id END)
                                               AS `溯源商机量`
    ,count(DISTINCT CASE WHEN t3.sj_type = 'protect' THEN t3.commercial_couple_id END)
                                               AS `保护商机量`
    ,count(DISTINCT t3.commercial_couple_id)   AS `内容商机量`
    ,count(DISTINCT t4.commercial_couple_id)   AS `内容商机带看量`
    ,count(DISTINCT t5.commercial_couple_id)   AS `内容商机成交量`
FROM content_enriched t1
LEFT JOIN content_traffic t2
  ON t1.content_id = t2.content_id
LEFT JOIN sj_union t3
  ON t1.content_id = t3.content_id
LEFT JOIN sj_show_matched t4
  ON t1.content_id = t4.content_id
LEFT JOIN sj_deal_matched t5
  ON t1.content_id = t5.content_id
GROUP BY
    t1.marketing_name
    ,t1.employee_no
    ,t1.employee_name
    ,t1.agent_ucid
    ,t1.content_id
    ,t1.title
    ,t1.resource_type
    ,t1.publish_date
    ,coalesce(t2.detail_expo_pv, 0)
    ,coalesce(t2.detail_expo_uv, 0)
ORDER BY
    t1.marketing_name
    ,`内容商机量` DESC
;

-- ------------------------------------------------------------
-- Query2: 商机对明细（含商机类型），基于中间表；按需取消注释运行
-- ------------------------------------------------------------
/*
WITH content_sj_daily AS (
    SELECT
        t1.commercial_couple_id
        ,t1.content_sj_type                    AS sj_type
        ,t1.cust_ucid
        ,t1.is_show
        ,t1.is_deal
        ,t1.parent_scene_id
    FROM rpt.rpt_content_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND substr(t1.occur_date, 1, 10) = '${-1d_yyyy-MM-dd}'
      AND t1.city_code = 110000
)
,sj_union AS (
    SELECT
        t2.content_id
        ,t1.commercial_couple_id
        ,t1.sj_type
        ,t1.cust_ucid
        ,t1.is_show
        ,t1.is_deal
    FROM content_sj_daily t1
    INNER JOIN content_scene t2
      ON t1.parent_scene_id = t2.scene_id
)

SELECT
    t1.marketing_name                          AS `营销大区`
    ,t1.employee_name                          AS `投稿人`
    ,t1.content_id                             AS `内容id`
    ,t1.title                                  AS `内容标题`
    ,t2.commercial_couple_id                   AS `商机对id`
    ,t2.cust_ucid                              AS `客户ucid`
    ,t2.sj_type                                AS `商机类型`
    ,t2.is_show                                AS `是否带看`
    ,t2.is_deal                                AS `是否成交`
FROM content_enriched t1
INNER JOIN sj_union t2
  ON t1.content_id = t2.content_id
ORDER BY
    t1.marketing_name
    ,t1.content_id
    ,t2.sj_type
;
*/
