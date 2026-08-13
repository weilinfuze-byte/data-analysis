# 漏斗 / 转化指标

### 曝光 UV / PV

- 表：beike_exp_detail_di / lianjia_exp_detail_di
- UV：`COUNT(DISTINCT duid)`
- PV：`COUNT(1)` 或 `COUNT(ucid)`

### 点击 UV / PV

- 表：behavior_flow_di
- 同上

### UCTR（人数点击率）

- 公式：`click_uv / expo_uv`
- 写法：
```sql
count(distinct click.duid) / count(distinct expo.duid)
-- 或
count(distinct t3.duid) / count(distinct t2.duid)
```

### PCTR（次数点击率）

- 公式：`click_pv / expo_pv`
- 写法：`sum(click.pv) / sum(expo.pv)`

### 转商机率

- 分子：页面商机（`rpt_asm_sj_trans_detail_da`，`is_commercial_couple = 1` + 目标页 `adid`）；详见 [commerce.md](commerce.md)
- 分母：页面 UV（duid 或 ucid，分析前须声明）
- 注意：duid 与 ucid 不可在同报告不同段落混用
- 模板：[templates/page_sj_by_adid.md](../templates/page_sj_by_adid.md)

### 首页feed物料 PCTR / UCTR

- 表：`rpt.rpt_homepage_feed_flow_di`
- 曝光分母：`40400 ∩ 54872`（滑动有效曝光）
- 点击：`40397`
- 维度：一级 `item_type`、二级 `card_type`
- 去重：**duid**
- 模板：[templates/homepage_feed_material_ctr.md](../templates/homepage_feed_material_ctr.md)

### 点后推 · 二导新户型卡 PCTR / UCTR

> as of 2026-08-10。走流量底表，不走内容生态中间表。

| 场景 | 曝光 | 点击 | 额外过滤 |
|------|------|------|----------|
| 搜索结果页 | `80326` | `80327` | `uicode=zonghesousuo/jieguo` AND `$.item_type='二导新户型卡'` |
| 二手首页 | `93280` | `93287` | 无 uicode / item_type |

- 曝光表：`rpt.rpt_comm_log_beike_exp_detail_di`
- 点击表：`rpt.rpt_log_bi_user_behivor_detail_flow_di`
- UV：`COUNT(DISTINCT duid)`；PV：`COUNT(1)`（不是 fb_expo_id 去重）
- UCTR = click_uv / expo_uv；PCTR = click_pv / expo_pv
- 两侧先按日聚合，曝光 LEFT JOIN 点击
- 模板：[templates/ershou_push_huxing_card_ctr.md](../templates/ershou_push_huxing_card_ctr.md)

### P2C 入口 PCTR / UCTR

- 底表：`rpt.rpt_p2c_rukou_rusult_di`
- pctr = click_pv / expo_pv
- uctr = click_uv / expo_uv
