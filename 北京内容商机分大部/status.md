# 北京内容商机分大部

## Project info
- **Date**: 2026-08-14
- **Requester**: 杨富泽
- **Problem statement**: 北京市按营销大区（大部）看内容投稿人、生产内容、流量及三类内容商机（展位 / 溯源 / 保护）。

## Scope（待确认）
| 维度 | 当前默认 |
|------|----------|
| 城市 | 北京市（city_id=110000 / city_name=北京市） |
| 站点端 | 贝壳 App |
| 业务线 | 二手 + 新房 |
| 日期 | 昨天：`pt = '${-1d_pt}'`；业务日 `${-1d_yyyy-MM-dd}` |
| 大部 | 员工表 `marketing_name`（营销大区/部门） |
| 生产→员工 | 生产表 **`im_ucid`**（经纪人 ucid）= 员工表 `employee_ucid` |

## 三类商机口径

| 类型 | 定义 | 来源 |
|------|------|------|
| 展位/溯源/保护 | `content_sj_type` 已打标 | `rpt.rpt_content_sj_trans_detail_da` |

**内容归因**：商机 `parent_scene_id` = 内容详情页曝光 `scene_id` → 解析 `content_id`

**商机带看量 / 商机成交量**（人店匹配，≠ 工厂 `is_show`/`is_deal`）：
- 商机侧：历史全部内容商机对（`occur_date <= 昨天`）
- 带看/成交侧：仅昨天有效带看/成交
- 匹配：客户 + 经纪人 + 带看/成交日 >= 商机日
- 模板：`sj_show_matched_daily` / `sj_deal_matched_daily`

## Deliverables
| 文件 | 用途 |
|------|------|
| `content_sj_trans_detail_da.sql` | **中间表 ETL**：`rpt_content_sj_trans_detail_da` |
| `bj_content_sj.sql` | **结果表 ETL + 建表 DDL**：全市不分大部 `rpt_bj_content_sj_result_di` |
| `rpt_bj_content_sj_result_di.md` | 全市结果表说明 |
| `bj_content_sj_by_marketing.sql` | **结果表 ETL + 建表 DDL**：全量内容 `rpt_bj_content_sj_by_marketing_result_di` |
| `bj_curator_content_sj_by_marketing.sql` | **结果表 ETL + 建表 DDL**：主理人内容 `rpt_bj_curator_content_sj_by_marketing_result_di` |
| `rpt_bj_content_sj_by_marketing_result_di.md` | 全量结果表说明 |
| `rpt_bj_curator_content_sj_by_marketing_result_di.md` | 主理人结果表说明 |
| `bj_content_sj_agent_detail.sql` | 经纪人 × 内容明细 + 三类商机 |

## Progress
- **Status**: 汇总 SQL + 中间表 ETL 已写，待工厂建表跑数
- **待确认**:
  1. 大部是否用 `marketing_name`（而非 `region_name`）
  2. ~~生产经纪人键~~ → **已校验**：`im_ucid` 有值关联成功率 99.23%；`admin_ucid` 0%（见 skill + `check_im_ucid_agent_join.sql`）
  3. ~~带看/成交口径~~ → 已改为人店匹配（历史内容商机 × 昨天带看/成交）
  4. 流量是否仅详情页曝光，或需叠加五场景卡片曝光

## Closure log (2026-08-14)

### Sunk
- 内容商机三类（中间表优先、打标≠归因、重叠计数、da 快照）→ `metrics/commerce.md` + `tables/content_sj_trans_detail_da.md` + `templates/content_sj_from_intermediate.md`
- `commercial_id` 打标 / `commercial_couple_id` 计数 → `tables/asm_sj_trans_detail_da.md` + `dimensions.md`
- 生产人只用 `im_ucid`（禁止 admin_ucid / coalesce；北京校验 99.23% / 0%）→ `SKILL.md` + `tables/feed_content_analyze_table.md` + `metrics/content-ecology.md`
- 详情页 `content_id` 解析 + 商机 `parent_scene_id` = `scene_id` → `tables/content_detail_flow_di.md`

### Deferred
- 大部用 `marketing_name` 还是 `region_name`（待确认，未写入 skill）
- 流量是否叠加五场景卡片曝光（待确认）
- 北京结果表 `rpt_bj_*_result_di`（项目专用，不进团队字典）
