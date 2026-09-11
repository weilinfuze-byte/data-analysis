# 首页 feed 内容卡口径（card_type 剔除法）

> as of 2026-09-03 confirmed（家装/风格测试等改判为内容）  
> 项目字典：`首页feed内容占比实验/content_card_type_dict.md`

## 判定（硬规则）

- **是内容**：`card_type IS NOT NULL` 且 **不在**下方非内容黑名单，且 `item_type NOT IN ('xinfang_project_name', 'ershou_house')`
- **非内容**：`card_type` ∈ 黑名单，或 `card_type` 为空，或 `item_type` ∈ `('xinfang_project_name', 'ershou_house')`
- 名单外新类型：按剔除法 **算作内容**（禁止再用 `card_type` 白名单）

## 2026-09-03 变更（二）

新增 `item_type` 剔除条件：`xinfang_project_name`、`ershou_house` 不算内容物料。

## 2026-09-03 变更（一）

以下原黑名单类型 **改判为内容**（已移出非内容名单）：

- 小区装修
- 装修报价
- 户型装修
- 家装服务承诺
- 家装门店
- 家装施工介绍
- 风格测试卡片

## SQL 片段

```sql
and t1.card_type is not null
and t1.card_type not in (
    'banner'
    ,'人工文章'
    ,'FEED满意度'
    ,'NPS卡片'
    ,'VR卡片'
    ,'板块单价卡'
    ,'板块热度分析卡'
    ,'板块优劣势卡'
    ,'城区板块分析卡'
    ,'带价邀请'
    ,'短评卡片'
    ,'二导新问询卡'
    ,'房源榜单卡'
    ,'房源对比卡片'
    ,'房源卡片'
    ,'负反馈卡片'
    ,'公寓'
    ,'共筑好家内容页'
    ,'共筑好家圈子页'
    ,'户型楼盘'
    ,'排行榜'
    ,'平台直播间'
    ,'普通省心租'
    ,'普通邀请'
    ,'诉求收集'
    ,'特价房'
    ,'土拍'
    ,'未来规划卡'
    ,'小工具卡片'
    ,'小区榜单卡'
    ,'新房楼盘'
    ,'样板间'
    ,'直播卡片'
    ,'专题卡片'
    ,'租赁房源'
)
and t1.item_type not in ('xinfang_project_name', 'ershou_house')
```

## 适用场景

- 首页 feed 内容卡周报 / 看板（`weekly_feed_scene_metrics.sql`）
- 首页 feed 内容占比 AB 实验（`ab_daily_metrics.sql`）
- 首页 feed 整体日指标表（`首页feed指标表/homepage_feed_daily_metrics_bj.sql`）
- 与 `tab_id = '推荐'`、`40400 ∩ 54872`（曝光）组合使用（周报内容卡场景）
