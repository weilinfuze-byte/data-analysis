# 贝壳 App 产品知识

> 业务数据随时间变化的内容需标注 `<!-- as of YYYY-MM -->`。

## 产品定位

贝壳 App 是房产交易综合平台，覆盖二手、新房、租赁、家装、我家（业主）、推荐 Feed 等模块。数据分析以 **埋点行为表 + 商机/成交表** 为核心。

## 站点与端

| 维度 | 取值 | 说明 |
|------|------|------|
| site | beike / lianjia | 两站需分别取或 UNION |
| dp | app / xcx / m | app 为主力端；xcx 小程序 uicode 可能不同 |

## 主要业务模块

| 模块 | 典型 uicode | SQL 目录参考 |
|------|-------------|--------------|
| 二手 | `ershou/detail`, `house_detail`(xcx) | `01 商业分析师/01 经纪业务/09 二手/` |
| 大首页 | `homepage1` | `06 大首页/` |
| 推荐 Feed | `homepage1`, `homepage/ershou_homev2`, `profile2` | `04 推荐/` |
| 榜单 | `homepage_bangdan`, `ershou/bangdan` | `05 榜单/` |
| 我家/业主 | myhome 系列表 | `01 业主端/` |
| 交易专家 P2C | `osa_jiaoyizhuanjia` 等 | `04 交易P2C/01 数据分析/` |

## 用户旅程（经纪业务典型）

```
App 打开 → 频道/Feed 浏览 → 房源/小区详情 → 商机产生 → 带看 → 成交
```

## AB 实验惯例

- 分组：`get_json_object(action,'$.ab_test_sign')` 或 `$.ab_test`
- 分析单位：**duid**（设备）
- 必须过滤版本：beike / lianjia 最低版本号不同
- 排除 `ab_tag = '其他'`

## 商机惯例

- 表：`rpt.rpt_asm_sj_trans_detail_da`（商机转化明细表，table_id=125732）
- 页面商机：**`is_commercial_couple = 1`** + 目标页 **`adid`**
- 溯源商机：溯源表 `shangyehua_shangyehua_commerce_scene_calculate_distance_di`（`uicode` / `ele_app_id` + `distance` 步长）JOIN 商机明细
- **`is_del = 1` = 转委托**（不是有效商机）；无效看 `is_invalid`
- 用户键：`cust_ucid`；商机对键：`commercial_couple_id`
- 三次握手 ⊆ 商机，按需
- 模板：页面商机 [page_sj_by_adid.md](../templates/page_sj_by_adid.md)；溯源 [sj_attribution_by_scene.md](../templates/sj_attribution_by_scene.md)

## Feed 推荐（和平老师口径）

- 曝光/点击 evt_id 因 feed 类型而异（大首页、新房、二手、个人中心、关注）
- 「有效曝光」需区分滑动曝光 vs 无滑动曝光
- 详见 `01 商业分析师/01 经纪业务/04 推荐/FROM 和平老师/`

## 两层看板架构

| 层 | 命名 | 作用 |
|----|------|------|
| 底表 | `insert overwrite table rpt.rpt_xxx_di` | ETL，按 pt 分区 |
| 模型 | `SELECT ... AS "中文列名"` | BI 消费层 |
