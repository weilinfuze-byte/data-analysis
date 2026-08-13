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

### 首页feed曝光（硬规则，2026-08）

- **任何**首页 feed 曝光相关指标（UV / PV / PCTR·UCTR 分母 / 渗透）= `40400 ∩ 54872`
- **禁止**裸用 `40400` 当曝光
- 点击仍为 `40397`；PCTR = 点击PV/有效曝光PV，UCTR = 点击UV/有效曝光UV
- 去重键：**duid**（与内容生态统一，见 [content-ecology.md](content-ecology.md)）
- 物料维度：一级 `item_type`、二级 `card_type`；先滑动用户集合再 JOIN 40400
- SQL：[templates/homepage_feed_material_ctr.md](../templates/homepage_feed_material_ctr.md)；埋点 [events/beike_evt_id.md](../events/beike_evt_id.md)

### 停留时长

- 表：`rpt.rpt_log_bi_user_uicode_flow_di`
- ETL 示例：`rpt.rpt_zhoubao_beike_app_duration`
