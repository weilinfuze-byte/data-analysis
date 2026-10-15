-- ============================================================
-- 行情内容商机溯源（按物料）
-- 直接查数，不落表
--
-- 口径:
--   溯源范围: 与中间表 content_sj_type=trace 同一套内容溯源
--     app_id / ele_app_id ∈ 图文落地页、视频落地页
--     或 uicode ∈ 视频/图文/行情/楼盘轻量/楼盘3D/光影/全景/全景新
--     交易故事、日照、相似的人不进内容溯源
--   步长: distance 1–7（string，不 cast）
--   同日: 溯源分区日 = 商机 occur_date
--   商机: 内容商机中间表 content_sj_type = trace，且 is_commercial_couple = 1
--   物料: 溯源 param.content_id，空则 ele_param.content_id
--         再挂 rpt.rpt_feed_content_analyze_table.resource_type
--         只留行情数据 6 类，其余物料不进结果：
--           resblock_deal_trend / bizcircle_deal_trend
--           resblock_deal_detail / bizcircle_deal_detail
--           resblock_rent_income_content / resblock_chain_case
--   范围: 昨天；二手+新房；不限城市、不限站点、不限端
--
-- 计数: 商机量 = commercial_couple_id 去重；商机用户 = cust_ucid 去重
-- 一条商机可挂多个 content_id，分物料相加可以大于总量
-- ============================================================

WITH sy AS (
    SELECT
        concat_ws('-', substr(t1.pt, 1, 4), substr(t1.pt, 5, 2), substr(t1.pt, 7, 2)) AS stat_date
        ,t1.commercial_id                        AS commercial_id
        ,CASE
            WHEN get_json_object(t1.param, '$.content_id') IS NOT NULL
             AND get_json_object(t1.param, '$.content_id') NOT IN ('-911', 'null')
            THEN get_json_object(t1.param, '$.content_id')
            WHEN get_json_object(t1.ele_param, '$.content_id') IS NOT NULL
             AND get_json_object(t1.ele_param, '$.content_id') NOT IN ('-911', 'null')
            THEN get_json_object(t1.ele_param, '$.content_id')
        END                                      AS content_id
    FROM shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.business_name IN ('二手', '新房')
      AND t1.distance BETWEEN 1 AND 7
      AND (
          t1.app_id IN (
              'BU_PingTai_new_kandian_article_zixun'
              ,'BU_PingTai_community_shipindetail_zixun'
          )
          OR t1.ele_app_id IN (
              'BU_PingTai_new_kandian_article_zixun'
              ,'BU_PingTai_community_shipindetail_zixun'
          )
          OR lower(t1.uicode) IN (
              'community/shipindetail'
              ,'new_kandian_article'
              ,'hangqing_content_app'
              ,'csxx_light'
              ,'csxx_3ddetailpage'
              ,'lightshadow'
              ,'overall'
              ,'panorama1'
          )
      )
      AND t1.commercial_id IS NOT NULL
      AND t1.commercial_id NOT IN ('-911', 'null')
)
,sj AS (
    SELECT
        substr(t1.occur_date, 1, 10)            AS occur_date
        ,t1.commercial_id                        AS commercial_id
        ,t1.commercial_couple_id                 AS commercial_couple_id
        ,t1.cust_ucid                            AS cust_ucid
        ,t1.business_name                        AS business_name
    FROM rpt.rpt_content_sj_trans_detail_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND substr(t1.occur_date, 1, 10) = '${-1d_yyyy-MM-dd}'
      AND t1.content_sj_type = 'trace'
      AND t1.is_commercial_couple = 1
      AND t1.business_name IN ('二手', '新房')
      AND t1.commercial_id IS NOT NULL
      AND t1.commercial_id NOT IN ('-911', 'null')
      AND t1.commercial_couple_id IS NOT NULL
      AND t1.commercial_couple_id NOT IN ('-911', 'null')
)
,content AS (
    SELECT
        cast(t1.content_id AS string)           AS content_id
        ,max(t1.resource_type)                   AS resource_type
    FROM rpt.rpt_feed_content_analyze_table t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.content_id IS NOT NULL
      AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
      AND t1.resource_type IN (
          'resblock_deal_trend'
          ,'bizcircle_deal_trend'
          ,'resblock_deal_detail'
          ,'bizcircle_deal_detail'
          ,'resblock_rent_income_content'
          ,'resblock_chain_case'
      )
    GROUP BY
        cast(t1.content_id AS string)
)
,hit AS (
    SELECT
        t2.business_name                         AS business_name
        ,t2.commercial_couple_id                 AS commercial_couple_id
        ,t2.cust_ucid                            AS cust_ucid
        ,t1.content_id                           AS content_id
        ,t3.resource_type                        AS resource_type
    FROM sy t1
    INNER JOIN sj t2
      ON t1.commercial_id = t2.commercial_id
     AND t1.stat_date = t2.occur_date
    INNER JOIN content t3
      ON t1.content_id = t3.content_id
)

SELECT
    t1.business_name                             AS `业务线`
    ,t1.resource_type                            AS `物料`
    ,count(DISTINCT t1.commercial_couple_id)     AS `商机量`
    ,count(DISTINCT CASE
        WHEN t1.cust_ucid IS NOT NULL
         AND cast(t1.cust_ucid AS string) NOT IN ('-911', 'null')
        THEN t1.cust_ucid
    END)                                         AS `商机用户数`
    ,count(DISTINCT t1.content_id)               AS `内容数`
FROM hit t1
GROUP BY
    t1.business_name
    ,t1.resource_type
;
