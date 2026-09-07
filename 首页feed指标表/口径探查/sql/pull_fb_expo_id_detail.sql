-- ============================================================
-- 按 fb_expo_id 捞贝壳曝光底表明细（全部字段）
-- 表: rpt.rpt_comm_log_beike_exp_detail_di
-- 说明: fb_expo_id 在 action 内，用 get_json_object 过滤；只查昨天
-- ============================================================

SELECT
    t1.*
FROM rpt.rpt_comm_log_beike_exp_detail_di t1
WHERE t1.pt = '${-1d_pt}'
  AND get_json_object(t1.action, '$.fb_expo_id') IN (
      'r1788741261704307417183839796311'
      ,'r178874109446223238515080105617'
      ,'r17887404852914602186217624205'
  )
;