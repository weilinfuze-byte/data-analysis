# SQL 模板

> Locked templates：只替换标记参数，不改 CTE 结构。

| 模板 | 场景 |
|------|------|
| [traffic_union.md](traffic_union.md) | 点击+曝光 UNION（经纪业务通用） |
| [ab_test_duid.md](ab_test_duid.md) | AB 实验 duid 分组 + 版本过滤 |
| [retention_fufang.md](retention_fufang.md) | N 日留存 / 复访 |
| [page_sj_by_adid.md](page_sj_by_adid.md) | 页面商机（按 adid 展位；三次握手可选） |
| [deal_ershou_xinfang.md](deal_ershou_xinfang.md) | 新二成交用户日清单（ucid + type + sign_date） |
| [show_ershou_xinfang.md](show_ershou_xinfang.md) | 新二有效带看用户日清单（ucid + type + showing_date） |
| [sj_attribution_by_scene.md](sj_attribution_by_scene.md) | 商机溯源（uicode / ele_app_id + 步长） |
| [p2c_dau_etl.md](p2c_dau_etl.md) | P2C DAU 底表 |
| [p2c_entry_funnel.md](p2c_entry_funnel.md) | P2C 入口曝光点击 |
| [p2c_chat_detail.md](p2c_chat_detail.md) | P2C 会话明细 ETL |
| [user_follow.md](user_follow.md) | 用户关注实体清单（贝壳+链家；entity_type 待确认） |
| [content_ecology_intermediate_flow.md](content_ecology_intermediate_flow.md) | 内容详情页/搜索结果页/内容feed/首页feed/二手详情/小区详情中间表 ETL |
| [content_detail_daily_traffic.md](content_detail_daily_traffic.md) | 内容详情页每日流量（从中间表聚合） |
| [search_content_card_ctr.md](search_content_card_ctr.md) | 搜索结果页内容横卡 UV/PV/UCTR/PCTR |
| [ershou_push_huxing_card_ctr.md](ershou_push_huxing_card_ctr.md) | 点后推二导新户型卡：搜索结果页+二手首页 CTR（流量底表） |
| [homepage_feed_material_ctr.md](homepage_feed_material_ctr.md) | 首页feed 一级×二级物料 PCTR/UCTR |
| [content_weekly_scene_metrics.md](content_weekly_scene_metrics.md) | 内容卡片周报：整体/分场景日指标 + Excel 表样 |

新增模板时在此注册，并在 [SKILL.md](../SKILL.md) Locked Templates 表同步。
