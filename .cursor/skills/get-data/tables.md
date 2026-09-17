# 贝壳表索引

> 优先用 rpt 层汇总表；dw/ods 仅在 rpt 不够用时下钻。
> 引用频次统计自 `01 商业分析师/` 716 份 SQL。
> 新表或字段不确定时，先查内部表检索：`http://factory.data.ke.com/tableSearch`。

## 查表优先级

1. 先读本文件和 `tables/*.md`，使用已沉淀的稳定口径
2. **内容生态**：已有流量中间表的场景，先扫中间表，不要默认扫曝光/行为底表
3. 本地没有的表，打开 `http://factory.data.ke.com/tableSearch` 用完整表名查询
4. 用历史 SQL 验证实际用法
5. 将确认后的字段、分区、坑点沉淀回对应 `tables/*.md`

内部表检索流程见 [docs/internal-table-search.md](docs/internal-table-search.md)。

## 核心表（有 detail 文件）

| 表 | 用途 | 频次 | Detail |
|----|------|------|--------|
| `rpt.rpt_log_bi_user_behivor_detail_flow_di` | 点击/行为/页面浏览 | 349 | [behavior_flow_di.md](tables/behavior_flow_di.md) |
| `rpt.rpt_comm_log_beike_exp_detail_di` | 贝壳元素曝光 | 124 | [beike_exp_detail_di.md](tables/beike_exp_detail_di.md) |
| `rpt.rpt_comm_log_lianjia_exp_detail_di` | 链家元素曝光 | 54 | [lianjia_exp_detail_di.md](tables/lianjia_exp_detail_di.md) |
| `rpt.rpt_content_detail_flow_di` | 新二内容详情页流量中间表（不含家装） | — | [content_detail_flow_di.md](tables/content_detail_flow_di.md) |
| `rpt.rpt_content_search_result_flow_di` | 搜索结果页内容流量中间表 | — | [content_search_result_flow_di.md](tables/content_search_result_flow_di.md) |
| `rpt.rpt_content_feed_flow_di` | 内容feed流量中间表 | — | [content_feed_flow_di.md](tables/content_feed_flow_di.md) |
| `rpt.rpt_homepage_feed_flow_di` | 首页feed流量中间表 | — | [homepage_feed_flow_di.md](tables/homepage_feed_flow_di.md) |
| `rpt.rpt_content_resblock_detail_flow_di` | 小区详情页内容流量中间表 | — | [content_resblock_detail_flow_di.md](tables/content_resblock_detail_flow_di.md) |
| `rpt.rpt_content_ershou_detail_flow_di` | 二手房源详情页内容流量中间表 | — | [content_ershou_detail_flow_di.md](tables/content_ershou_detail_flow_di.md) |
| `rpt.rpt_feed_content_analyze_table` | 内容中台存量内容底表 | — | [feed_content_analyze_table.md](tables/feed_content_analyze_table.md) |
| `ods.ods_beike_feed_cms_feed_beikehao_da` | 贝壳号 ODS（校验 beikehao_id / im_ucid） | — | [ods_beike_feed_cms_feed_beikehao_da.md](tables/ods_beike_feed_cms_feed_beikehao_da.md) |
| `rpt.rpt_log_bi_user_uicode_flow_di` | 页面级 DAU/MAU/停留 | 41 | [uicode_flow_di.md](tables/uicode_flow_di.md) |
| `rpt.rpt_asm_sj_trans_detail_da` | 商机转化明细表 | 73 | [asm_sj_trans_detail_da.md](tables/asm_sj_trans_detail_da.md) |
| `rpt.rpt_content_sj_trans_detail_da` | 内容商机明细中间表（三类+全字段） | — | [content_sj_trans_detail_da.md](tables/content_sj_trans_detail_da.md) |
| `shangyehua.shangyehua_shangyehua_commerce_scene_calculate_distance_di` | 商机溯源（路径步长-关联元素） | — | [commerce_scene_calculate_distance_di.md](tables/commerce_scene_calculate_distance_di.md) |

## P2C 交易专家

| 表 | 用途 | Detail |
|----|------|--------|
| `rpt.rpt_p2c_dau_result_di` | P2C 各页面 DAU 底表 | [p2c_result_tables.md](tables/p2c_result_tables.md) |
| `rpt.rpt_p2c_chat_detail_di` | 会话消息明细底表 | [p2c_chat_detail_di.md](tables/p2c_chat_detail_di.md) |
| `olap.olap_plat_huiju_chat_workbench_private_chat_record_da` | Roomie 私聊原始消息 | [p2c_chat_detail_di.md](tables/p2c_chat_detail_di.md) |
| `olap.olap_im_base_with_payload_di` | IM 消息（开口说话） | [im_base_with_payload_di.md](tables/im_base_with_payload_di.md) |
| `ods.ods_plat_trade_cost_*_da` | 四工具 ODS | [trade_cost_tools_ods.md](tables/trade_cost_tools_ods.md) |

## 房源 / 小区浏览

| 表 | 用途 | Detail |
|----|------|--------|
| `rpt.rpt_comm_log_housedel_info_di` | 流量房源浏览明细（含核访标记） | [comm_log_housedel_info_di.md](tables/comm_log_housedel_info_di.md) |
| `rpt.rpt_comm_spr_hdel_housedel_info_da` | 房源明细扩展（小区/商圈维） | [comm_spr_hdel_housedel_info_da.md](tables/comm_spr_hdel_housedel_info_da.md) |
| `dw.dw_plat_user_housedel_fllow_da` | 贝壳用户关注 | [user_follow_da.md](tables/user_follow_da.md) |
| `dw.dw_plat_lianjia_user_user_favorite_da` | 链家用户关注 | [user_follow_da.md](tables/user_follow_da.md) |

## 带看 / 客源 / 成交

| 表 | 用途 | Detail |
|----|------|--------|
| `rpt.rpt_shh_show_showing_housedel_info_da` | 二手带看明细 | [shh_show_showing_housedel_info_da.md](tables/shh_show_showing_housedel_info_da.md) |
| `rpt.rpt_nh_show_house_showing_info_da` | 新房带看明细 | [nh_show_house_showing_info_da.md](tables/nh_show_house_showing_info_da.md) |
| `dw.dw_cdel_custdel_da` | 客源（custdel→ucid） | [cdel_custdel_da.md](tables/cdel_custdel_da.md) |
| `rpt.rpt_shh_rent_deal_agreement_detail_da` | 二手成交基础信息（买卖靠 del_type 筛） | [shh_rent_deal_agreement_detail_da.md](tables/shh_rent_deal_agreement_detail_da.md) |
| `rpt.rpt_nh_output_deal_info_online_custdel_da` | 新房成交（线上客源标签） | [nh_output_deal_info_online_custdel_da.md](tables/nh_output_deal_info_online_custdel_da.md) |
| `rpt.rpt_shh_deal_agreement_da` | 二手成交（房源侧常用） | |

## 员工 / 组织

| 表 | 用途 | Detail |
|----|------|--------|
| `rpt.rpt_comm_agent_allinfo_employee_da` | 公司全量员工日快照（职务/组织/上级） | [comm_agent_allinfo_employee_da.md](tables/comm_agent_allinfo_employee_da.md) |

> 旧表 `dw.dw_allinfo_hr_employee_da`、`rpt.rpt_allinfo_hr_employee_da` 待下线/请勿申请，统一用上表。

## 其他常用表

| 表 | 用途 |
|----|------|
| `rpt.rpt_feed_all_user_di` | 推荐 Feed 用户 |
| `rpt.rpt_comm_hdel_housedel_info_da` | 房源信息（字段待核实；小区 JOIN 优先用 spr 扩展表） |
| `dw.dw_log_commerce_stream_clue_inf_di` | 商业线索流 |
| `dim.dim_beautyhome_city_expand` | 城市维表（家装/扩展城市） |
| `dim.dim_pub_city_da` | 城市公共维表 |
| `olap.olap_myhome_ll_di` | 我家流量 |
| `olap.olap_yezhu_duid_ac_da` | 业主 AC 标签（duid） |

## 核心 JOIN 路径

```
行为/曝光（duid）
    ↓ evt_id='1,3' + uicode 过滤
页面 DAU / AB 分组

行为/曝光（ucid）+ 商机表（cust_ucid）
    ↓
转商机率 / 用户调研人群

uicode_flow_di（is_dau=1）
    ↓ substr(stat_date,1,7)
MAU / 停留 / 月报渗透

流量房源浏览（c_housedel_id）+ 房源扩展维表（housedel_id）
    ↓ resblock_id
小区粒度浏览用户数

二手带看（custdel_id）
    UNION ALL
新房带看（custdel_id）+ 客源表（customer_uid）
    ↓ ucid + type + showing_date
新二有效带看用户日清单

二手成交（cust_ucid）
    UNION ALL
新房成交（custdel_id）+ 客源表（customer_uid）
    ↓ ucid + type + sign_date
新二成交用户日清单

内容生产表（im_ucid）
    ↓ 禁止 admin_ucid / coalesce 兜底
员工表（employee_ucid）→ 组织维（marketing_name / region_name 需业务确认）

内容商机中间表 rpt_content_sj_trans_detail_da
    ↓ 分类型 COUNT DISTINCT commercial_couple_id（允许重叠）
    ↓ 按内容拆：parent_scene_id = 详情页 scene_id → content_id
内容商机量 / 按内容归因
```

## 流量取数三板斧

```
rpt_log_bi_user_behivor_detail_flow_di   -- 点击
UNION ALL
rpt_comm_log_beike_exp_detail_di         -- 贝壳曝光
UNION ALL
rpt_comm_log_lianjia_exp_detail_di       -- 链家曝光（可选）
```

详见 [templates/traffic_union.md](templates/traffic_union.md)。

内容生态中间表（详情页/搜索页/内容feed/首页feed/二手详情/小区详情）见 [templates/content_ecology_intermediate_flow.md](templates/content_ecology_intermediate_flow.md)。
