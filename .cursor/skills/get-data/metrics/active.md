# 活跃指标

> 硬规则：以下定义 verbatim 使用，不可替换。

### 页面 DAU

- 别名：DAU、日活
- 公式：`COUNT(DISTINCT duid) WHERE evt_id = '1,3'`
- 表：[behavior_flow_di](../tables/behavior_flow_di.md) 或 traffic UNION CTE
- 切片：active_date, uicode, site, dp, city_name, ab_tag
- 注意：P2C 底表用 **ucid** 去重（见 [p2c.md](p2c.md)）

### 页面 MAU

- 公式：`COUNT(DISTINCT duid)` 按月
- 表：`rpt.rpt_log_bi_user_uicode_flow_di`
- 条件：`is_dau = 1`，`substr(stat_date, 1, 7)` 为月份

### 曝光渗透率

- 公式：`expo_uv / dau`
- 写法：`count(distinct expo.duid) / count(distinct dau.duid)`

### Feed 有效曝光 UV

- 来源：和平老师口径（`04 推荐/FROM 和平老师/`）
- 按 feed_type 匹配不同 evt_id（大首页 40400、二手 13942 等）
- 有效曝光需 JOIN 滑动 evt_id（54872、60251 等）

### 首页feed曝光（硬规则，2026-09）

按场景选口径，**禁止**把一种默认套到所有 SQL：

| 场景 | 曝光 | PV | UV | 点击 |
|------|------|----|----|------|
| 周报内容卡 / 物料 CTR | `40400 ∩ 54872` | `fb_expo_id × duid` | `duid` | `40397` |
| 日常监控日表 | 全量 `40400` **+** 有效 `40400∩54872` | `count(1)` **+** `count(distinct fb_expo_id)` | `duid` | `40397`（不限滑动） |
| AB / 内容占比 | **每次问用户** | **每次问用户** | `duid` | `40397` |

- 有效曝光：先 `54872` 用户集合（默认不加 tab），再 JOIN `40400`
- 物料一级：优先 `show_card_type`，空则 `item_type`（监控日表）；周报/物料 CTR 勿把 `item_type` 当一级
- `tab_id` 空值归并 `推荐`（监控日表 Locked）
- 内容卡：剔除法，见 [homepage_feed_content_card_filter.md](../docs/homepage_feed_content_card_filter.md)
- AB 桶映射不写死：见 [dimensions.md](../dimensions.md)
- 模板 / 项目：物料 CTR → [homepage_feed_material_ctr.md](../templates/homepage_feed_material_ctr.md)；监控日表 → `首页feed指标表/`
- 埋点：[events/beike_evt_id.md](../events/beike_evt_id.md)

### 停留时长

- 表：`rpt.rpt_log_bi_user_uicode_flow_di`
- ETL 示例：`rpt.rpt_zhoubao_beike_app_duration`
