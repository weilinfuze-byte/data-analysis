# 维度字典

> 维度 → 字段映射。指标级切片见 [metrics.md](metrics.md)。

## 站点与端

| 维度 | 字段 | 标准值 |
|------|------|--------|
| site | `site` | beike, lianjia |
| dp | `dp` | app, xcx, m |
| 合并口径 | — | 「贝壳+链家」= 两站 UNION |

## 用户标识

| 维度 | 字段 | 用途 |
|------|------|------|
| 设备 | `duid` | DAU、MAU、留存、AB、Feed 漏斗、**内容生态人数 UV** |
| 用户 | `ucid` | 商机、成交、用户画像 |
| C 端 IM | `from_ucid LIKE '200%'` | P2C 开口说话 |
| 专家账号 | `to_ucid = 'osa_jiaoyizhuanjia'` | P2C 会话目标 |

### duid vs ucid

- `duid` = 设备 ID，未登录也有
- `ucid` = 账号 ID，**只有登录之后才有**
- 一个设备可以登录多个账号；一个账号可以在多个设备登录
- **所有人数 / UV 指标**（含内容生态）统一用 `duid` 去重；`ucid` 仅用于商机、成交、画像等账号级场景（2026-08 confirmed）

## 时间与分区

| 维度 | 字段 | 说明 |
|------|------|------|
| 活跃日 | `active_date` | 行为/曝光表 |
| 统计日 | `stat_date` | uicode_flow_di |
| 分区 | `pt` | `YYYYMMDDHHMMSS`，必带 |
| 调度参数 | `${-1d_pt}` | 昨天分区 |
| 日期参数 | `${-1d_yyyy-MM-dd}` | 昨天 yyyy-MM-dd |

## 页面与业务

| 维度 | 字段 | 示例 |
|------|------|------|
| 页面 | `uicode` | `ershou/detail`（二手房源详情页 App）, `homepage1` |
| 业务线 | `business_name` | 二手, 新房, 家装, 交易 |
| 城市 | `city_code`, `city_name` | 北京=`110000`（国标）；类型因表而异，见下 |
| 事件 | `evt_id` | 行为明细表：`'1,3'`（整体字符串）；流量房源表可试 `IN ('1','3')` |
| 房源 id | `c_housedel_id` / `b_housedel_id` | C 端 / B 端；JOIN 房源维表取小区用 **`c_housedel_id`** |
| 小区 | `resblock_id`, `resblock_name` | 来自房源扩展维表 |

### city_code 类型差异（易踩坑）

| 表 | city_code 类型 | 北京过滤示例 |
|----|----------------|--------------|
| `rpt_comm_log_housedel_info_di` | string | `city_code = '110000'` |
| `rpt_comm_spr_hdel_housedel_info_da` | int | `city_code = 110000` |
| `rpt_log_bi_user_behivor_detail_flow_di` | int | `city_code = 110000` |

流量表 `city_code` = 埋点上报城市；维表 = 房源所在城市。严谨口径以维表为准。

## JSON action 常用键

| 维度 | 提取方式 | 用途 |
|------|----------|------|
| AB 分组 | `get_json_object(action,'$.ab_test_sign')` | 实验分组 |
| AB 分组（P2C） | `get_json_object(action,'$.ab_test')` | 房源详情 AB |
| Tab 名称 | `get_json_object(action,'$.tab_name')` | 动态主页 Tab |
| 业务类型 | `get_json_object(action,'$.business_type')` | 入口过滤 |
| Feed 位置 | `get_json_object(action,'$.expo_position')` | Feed 曝光深度 |
| Feed ID | `get_json_object(action,'$.fb_expo_id')` | Feed 去重曝光 |
| 房源 id | `get_json_object(action,'$.housedel_id')` | 二手详情页 `ershou/detail` 页面曝光解析房源；用前建议抽样确认 key 名 |
| 首页feed一级分类 | `get_json_object(action,'$.fb_item_type')` | 落表字段 `item_type`；≠ 搜索竖卡的 `$.item_type` |
| 搜索结果页物料类型 | `get_json_object(action,'$.item_type')` | 80326/80327；点后推筛 `'二导新户型卡'` |
| 首页feed内容体裁 | `get_json_object(action,'$.type')` | 落表字段 `share_media`；≠ 搜索的 `$.share_media` |
| 首页feed内容id | `get_json_object(action,'$.content_id')` | 落表字段 `content_id`；≠ 搜索竖卡的 `$.fb_item_id` |

## AB 实验衍生维度

```sql
CASE
    WHEN t1.site = 'beike'   AND t1.client_app_version >= '{beike_min_ver}' THEN '已更新APP'
    WHEN t1.site = 'lianjia' AND t1.client_app_version >= '{lianjia_min_ver}' THEN '已更新APP'
    ELSE '未更新APP'
END AS if_update
```

> 版本号按实验更新，写死在各项目 SQL 中。AB 分析必须过滤 `if_update = '已更新APP'`。

## 商机维度

| 维度 | 字段 | 说明 |
|------|------|------|
| 广告位 | `adid` | 广告位 ID；页面当场商机 = 该页 adid 列表 |
| 商机展位 | `port` | 工厂字段「商机展位」（与 adid 区分） |
| 商机对 | `is_commercial_couple = 1` | 页面/溯源商机常用 |
| 转委托 | `is_del = 1` | **不是**有效商机 |
| 转带看 / 转成交 | `is_show` / `is_deal` | |
| 无效商机 | `is_invalid` | 1无效 / 0非无效 / -911未知 |
| 商机对键 | `commercial_couple_id` | 商机 PV |
| 商机主键 | `commercial_id` | 表粒度；溯源关联键 |
| 客户 | `cust_ucid` | 商机用户键 |
| 三次握手 | `data_lables = '["1002"]'` | 线索表子集，按需；⊆ 商机 |
| 溯源页面 | `uicode` | 溯源表；访问过该页后路径上的商机 |
| 溯源元素 | `ele_app_id` | 溯源表；点过该按钮/模块后路径上的商机 |
| 溯源步长 | `distance` | 当前页=第1步；几步内产生的商机；string，勿 cast |

## uicode 大小写

数据中存在大小写不一致，过滤时优先：

```sql
lower(uicode) = 'communitydetailv2'
-- 或
Lower(uicode) IN ('homepage1', 'homepage/ershou_homev2')
```

## 内容生态场景映射（2026-07 confirmed）

| 场景 | scene | uicode |
|------|-------|--------|
| 内容Feeds | `content_feeds` | `new_kandian_homepage`, `content/kandian/recommend` |
| 首页feed（大首页推荐） | `homepage_feed` | `homepage1` |
| 搜索结果页 | `search_result` | `zonghesousuo/jieguo` |
| 二手详情页-头部+底部推荐 | `ershou_detail_recom` | `ershou/detail` |
| 小区详情页-头部+底部推荐 | `resblock_detail_recom` | `communitydetailv2` |
| 整体 | `overall` | 不区分 `scene`（跨场景去重） |

- 二手详情中间表：`rpt.rpt_content_ershou_detail_flow_di`，见 [tables/content_ershou_detail_flow_di.md](tables/content_ershou_detail_flow_di.md)
- 小区详情中间表：`rpt.rpt_content_resblock_detail_flow_di`，见 [tables/content_resblock_detail_flow_di.md](tables/content_resblock_detail_flow_di.md)

## 二手详情页底部 from / card_type（2026-08-13 confirmed）

> 底部曝光 `87223` / 点击 `87222`。`from` 取值：`内容` / `二手` / `新房`。

剔除（非内容卡片）：二手×房源卡片、新房×新房楼盘、新房×土拍。不要用 `card_type` 白名单。

## 内容详情页 uicode（2026-08 confirmed）

> 中间表：`rpt.rpt_content_detail_flow_di`。完整 source 规则见 [tables/content_detail_flow_di.md](tables/content_detail_flow_di.md)

| 页面 | uicode | source 限制 |
|------|--------|-------------|
| 视频详情页 | `community/shipindetail` | 无 |
| 图文详情页 | `new_kandian_article` | 无 |
| 行情数据 | `hangqing_content_app` | 无 |
| 新房日照 | `csxx_light` | 综搜/大首页/新看点 |
| 新房航拍 | `csxx_3ddetailpage` | 同上 |
| 二手日照 | `lightshadow` | 小区详情/房源详情 |
| 二手航拍 | `overall` | 同上 |
| 小区漫游 | `panorama1` | 综搜/大首页/新看点/小区详情 |

source 键：`get_json_object(action,'$.source')`，取值 `zonghesousuo_jieguo` / `homepage1` / `new_kandian_homepage` / `c_resblock_detail` / `c_house_detail`。

## 搜索结果页 tab / module（2026-08 confirmed）

> 中间表：`rpt.rpt_content_search_result_flow_di`。见 [tables/content_search_result_flow_di.md](tables/content_search_result_flow_di.md)

- 一级 tab：`action.tab_name`（如 综合、内容、评测）
- 卡片类型：`action.module_type`（内容相关：`contentFeed`、`contentCardModule`）
- 0709+：`评测` tab 改名为 `内容`
- 0806+：综合 tab 横卡迁入 80326/80327，`module_type=contentCardModule`

## 内容生态 DUID 异常值过滤（硬规则）

人数 / UV 去重键为 `duid`（2026-08 起，原 `ucid` 口径已废弃）。同通用关联键口径（JOIN 前）：

```sql
and duid is not null
and duid not in ('-911','null')
```

禁止再剔 `''`、`' '`。
