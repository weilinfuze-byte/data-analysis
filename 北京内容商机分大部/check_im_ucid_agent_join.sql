-- ============================================================
-- Query: 校验内容生产表经纪人 id ↔ 员工表能否关联
-- Project: 北京内容商机分大部
-- Created: 2026-08-14
--
-- 生产表: rpt.rpt_feed_content_analyze_table
-- 员工表: rpt.rpt_comm_agent_allinfo_employee_da
-- 关联键（Locked）: im_ucid = employee_ucid
--
-- Scope: 北京，已上线内容；pt = '${-1d_pt}'
-- Style: SELECT 逗号前置; 表别名 t1/t2
-- ============================================================

-- ------------------------------------------------------------
-- Query1: 整体覆盖率（im_ucid vs employee_ucid）
-- ------------------------------------------------------------
WITH content_agent AS (
    SELECT
        cast(t1.content_id AS string)                      AS content_id
        ,if(trim(t1.im_ucid) = '', null, trim(t1.im_ucid)) AS im_ucid
        ,if(trim(t1.admin_ucid) = '', null, trim(t1.admin_ucid))
                                                           AS admin_ucid
        ,array_contains(t1.content_tag, 'curator_content') AS is_curator
    FROM rpt.rpt_feed_content_analyze_table t1
    WHERE t1.pt = '${-1d_pt}'
      AND cast(t1.city_id AS string) = '110000'
      AND t1.status = 4
      AND t1.content_id IS NOT NULL
      AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
)
,agent_org AS (
    SELECT
        cast(t1.employee_ucid AS string)                   AS employee_ucid
        ,t1.employee_no                                    AS employee_no
        ,t1.employee_name                                  AS employee_name
        ,t1.marketing_name                                 AS marketing_name
    FROM rpt.rpt_comm_agent_allinfo_employee_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.city_name = '北京市'
      AND t1.employee_ucid IS NOT NULL
      AND cast(t1.employee_ucid AS string) NOT IN ('-911', 'null')
    GROUP BY
        cast(t1.employee_ucid AS string)
        ,t1.employee_no
        ,t1.employee_name
        ,t1.marketing_name
)

SELECT
    'all'                                                  AS `内容范围`
    ,count(DISTINCT t1.content_id)                         AS `内容量`
    ,count(DISTINCT t1.im_ucid)                            AS `有im_ucid内容对应经纪人数`
    ,sum(CASE WHEN t1.im_ucid IS NULL THEN 1 ELSE 0 END)   AS `im_ucid为空内容量`
    ,sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
                                                           AS `im关联成功内容量`
    ,sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NULL THEN 1 ELSE 0 END)
                                                           AS `im有值未关联内容量`
    ,round(
        100.0 * sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
        / nullif(sum(CASE WHEN t1.im_ucid IS NOT NULL THEN 1 ELSE 0 END), 0)
        ,2
     )                                                     AS `im有值关联成功率%`
    ,count(DISTINCT CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN t1.im_ucid END)
                                                           AS `im关联成功经纪人数`
    ,count(DISTINCT CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NULL THEN t1.im_ucid END)
                                                           AS `im有值未关联经纪人数`
FROM content_agent t1
LEFT JOIN agent_org t2
  ON t1.im_ucid = t2.employee_ucid

UNION ALL

SELECT
    'curator'                                              AS `内容范围`
    ,count(DISTINCT t1.content_id)                         AS `内容量`
    ,count(DISTINCT t1.im_ucid)                            AS `有im_ucid内容对应经纪人数`
    ,sum(CASE WHEN t1.im_ucid IS NULL THEN 1 ELSE 0 END)   AS `im_ucid为空内容量`
    ,sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
                                                           AS `im关联成功内容量`
    ,sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NULL THEN 1 ELSE 0 END)
                                                           AS `im有值未关联内容量`
    ,round(
        100.0 * sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
        / nullif(sum(CASE WHEN t1.im_ucid IS NOT NULL THEN 1 ELSE 0 END), 0)
        ,2
     )                                                     AS `im有值关联成功率%`
    ,count(DISTINCT CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN t1.im_ucid END)
                                                           AS `im关联成功经纪人数`
    ,count(DISTINCT CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NULL THEN t1.im_ucid END)
                                                           AS `im有值未关联经纪人数`
FROM content_agent t1
LEFT JOIN agent_org t2
  ON t1.im_ucid = t2.employee_ucid
WHERE t1.is_curator = true
;


-- ------------------------------------------------------------
-- Query2: 对比 im_ucid / admin_ucid 各自关联成功率
-- ------------------------------------------------------------
WITH content_agent AS (
    SELECT
        cast(t1.content_id AS string)                      AS content_id
        ,if(trim(t1.im_ucid) = '', null, trim(t1.im_ucid)) AS im_ucid
        ,if(trim(t1.admin_ucid) = '', null, trim(t1.admin_ucid))
                                                           AS admin_ucid
    FROM rpt.rpt_feed_content_analyze_table t1
    WHERE t1.pt = '${-1d_pt}'
      AND cast(t1.city_id AS string) = '110000'
      AND t1.status = 4
      AND t1.content_id IS NOT NULL
      AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
)
,agent_org AS (
    SELECT
        cast(t1.employee_ucid AS string)                   AS employee_ucid
    FROM rpt.rpt_comm_agent_allinfo_employee_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.city_name = '北京市'
      AND t1.employee_ucid IS NOT NULL
      AND cast(t1.employee_ucid AS string) NOT IN ('-911', 'null')
    GROUP BY
        cast(t1.employee_ucid AS string)
)

SELECT
    'im_ucid'                                              AS `关联键`
    ,count(1)                                              AS `内容量`
    ,sum(CASE WHEN t1.im_ucid IS NULL THEN 1 ELSE 0 END)   AS `键为空内容量`
    ,sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
                                                           AS `关联成功内容量`
    ,sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NULL THEN 1 ELSE 0 END)
                                                           AS `有值未关联内容量`
    ,round(
        100.0 * sum(CASE WHEN t1.im_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
        / nullif(sum(CASE WHEN t1.im_ucid IS NOT NULL THEN 1 ELSE 0 END), 0)
        ,2
     )                                                     AS `有值关联成功率%`
FROM content_agent t1
LEFT JOIN agent_org t2
  ON t1.im_ucid = t2.employee_ucid

UNION ALL

SELECT
    'admin_ucid'                                           AS `关联键`
    ,count(1)                                              AS `内容量`
    ,sum(CASE WHEN t1.admin_ucid IS NULL THEN 1 ELSE 0 END) AS `键为空内容量`
    ,sum(CASE WHEN t1.admin_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
                                                           AS `关联成功内容量`
    ,sum(CASE WHEN t1.admin_ucid IS NOT NULL AND t2.employee_ucid IS NULL THEN 1 ELSE 0 END)
                                                           AS `有值未关联内容量`
    ,round(
        100.0 * sum(CASE WHEN t1.admin_ucid IS NOT NULL AND t2.employee_ucid IS NOT NULL THEN 1 ELSE 0 END)
        / nullif(sum(CASE WHEN t1.admin_ucid IS NOT NULL THEN 1 ELSE 0 END), 0)
        ,2
     )                                                     AS `有值关联成功率%`
FROM content_agent t1
LEFT JOIN agent_org t2
  ON t1.admin_ucid = t2.employee_ucid
;


-- ------------------------------------------------------------
-- Query3: im_ucid 有值但未关联到员工表的样例（Top 50）
-- ------------------------------------------------------------
WITH content_agent AS (
    SELECT
        cast(t1.content_id AS string)                      AS content_id
        ,if(trim(t1.im_ucid) = '', null, trim(t1.im_ucid)) AS im_ucid
        ,t1.title                                          AS title
        ,t1.resource_type                                  AS resource_type
        ,array_contains(t1.content_tag, 'curator_content') AS is_curator
    FROM rpt.rpt_feed_content_analyze_table t1
    WHERE t1.pt = '${-1d_pt}'
      AND cast(t1.city_id AS string) = '110000'
      AND t1.status = 4
      AND t1.content_id IS NOT NULL
      AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
      AND if(trim(t1.im_ucid) = '', null, trim(t1.im_ucid)) IS NOT NULL
)
,agent_org AS (
    SELECT
        cast(t1.employee_ucid AS string)                   AS employee_ucid
    FROM rpt.rpt_comm_agent_allinfo_employee_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.city_name = '北京市'
      AND t1.employee_ucid IS NOT NULL
      AND cast(t1.employee_ucid AS string) NOT IN ('-911', 'null')
    GROUP BY
        cast(t1.employee_ucid AS string)
)

SELECT
    t1.im_ucid                                             AS `im_ucid`
    ,count(DISTINCT t1.content_id)                         AS `内容量`
    ,max(t1.title)                                         AS `样例标题`
    ,max(t1.resource_type)                                 AS `样例类型`
    ,max(CASE WHEN t1.is_curator THEN 1 ELSE 0 END)        AS `是否含主理人内容`
FROM content_agent t1
LEFT JOIN agent_org t2
  ON t1.im_ucid = t2.employee_ucid
WHERE t2.employee_ucid IS NULL
GROUP BY
    t1.im_ucid
ORDER BY
    `内容量` DESC
LIMIT 50
;


-- ------------------------------------------------------------
-- Query4: 关联成功样例（确认能带出大部/姓名）
-- ------------------------------------------------------------
WITH content_agent AS (
    SELECT
        cast(t1.content_id AS string)                      AS content_id
        ,if(trim(t1.im_ucid) = '', null, trim(t1.im_ucid)) AS im_ucid
        ,t1.title                                          AS title
    FROM rpt.rpt_feed_content_analyze_table t1
    WHERE t1.pt = '${-1d_pt}'
      AND cast(t1.city_id AS string) = '110000'
      AND t1.status = 4
      AND t1.content_id IS NOT NULL
      AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
      AND if(trim(t1.im_ucid) = '', null, trim(t1.im_ucid)) IS NOT NULL
)
,agent_org AS (
    SELECT
        cast(t1.employee_ucid AS string)                   AS employee_ucid
        ,t1.employee_no                                    AS employee_no
        ,t1.employee_name                                  AS employee_name
        ,t1.marketing_name                                 AS marketing_name
    FROM rpt.rpt_comm_agent_allinfo_employee_da t1
    WHERE t1.pt = '${-1d_pt}'
      AND t1.city_name = '北京市'
      AND t1.employee_ucid IS NOT NULL
      AND cast(t1.employee_ucid AS string) NOT IN ('-911', 'null')
    GROUP BY
        cast(t1.employee_ucid AS string)
        ,t1.employee_no
        ,t1.employee_name
        ,t1.marketing_name
)

SELECT
    t1.im_ucid                                             AS `im_ucid`
    ,t2.employee_no                                        AS `工号`
    ,t2.employee_name                                      AS `姓名`
    ,t2.marketing_name                                     AS `营销大区`
    ,count(DISTINCT t1.content_id)                         AS `内容量`
    ,max(t1.title)                                         AS `样例标题`
FROM content_agent t1
INNER JOIN agent_org t2
  ON t1.im_ucid = t2.employee_ucid
GROUP BY
    t1.im_ucid
    ,t2.employee_no
    ,t2.employee_name
    ,t2.marketing_name
ORDER BY
    `内容量` DESC
LIMIT 50
;
