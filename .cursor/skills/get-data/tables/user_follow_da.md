# 用户关注表（贝壳 + 链家）

> 用户对房源 / 小区 / 楼盘等实体的关注关系。圈选、排除已关注、关注归一小区时用。
> SQL 模板：[user_follow.md](../templates/user_follow.md)

<!-- as of 2026-07-31, source: http://factory.data.ke.com/tableSearch -->

## 双表对照

| | 贝壳 | 链家 |
|--|------|------|
| 表 | `dw.dw_plat_user_housedel_fllow_da` | `dw.dw_plat_lianjia_user_user_favorite_da` |
| 中文名 | 用户房源关注表 | 用户关注表 |
| 用户字段 | `user_ucid`（string） | `user_id`（bigint，取出时 CAST 成 string） |
| 有效关注 | `follow_status = '1'`（0无效/1有效） | `status = '1'`（0无效/1有效） |
| 关注时间 | 优先 `follow_time`；另有 `create_time` | `create_time`（原 ctime） |
| 字段数 | 21 | 16 |
| 分区 | `pt`（日任务） | `pt`（日任务） |
| 标签 | 高价值、DW2.0、平台主题域 | 高价值、DW2.0、平台主题域、M大存储 |
| 数据负责人 | 苏万磊（suwanlei001@ke.com） | 董家齐（dongjiaqi011@ke.com） |
| 空间 | 数据资产开发团队 / 公共集群 | 同左 |

## entity_type（待确认）

两侧都有 `entity_type` + `entity_id`。枚举业务含义**尚未用数据验证**，写 SQL 时保留「待确认」注释。

| 取值 | 来源线索 | 状态 |
|------|----------|------|
| `resblock` | 历史 SQL 注释「小区」 | **待确认** |
| `project` | 历史 SQL 注释「楼盘」 | **待确认** |
| `house` / `House` | 用户列举；链家工厂文档写 `House/resblock/search` | **待确认** |
| `secondhand` | 历史 SQL 与 `ershoufang` 并列作二手房 | **待确认** |
| `ershoufang` | 同上 | **待确认** |
| `search` | 链家工厂文档：搜索条件 | **待确认** |

注意：贝壳历史脚本常见 `secondhand`/`ershoufang`/`resblock`/`project`；链家工厂文档写 `House/resblock/search`。大小写与别名是否等价，**不要假设**，先 `GROUP BY entity_type` 探数。

## 贝壳关键字段

| 字段 | 含义 |
|------|------|
| `user_ucid` | 用户 ucid |
| `entity_type` / `entity_id` | 关注实体类型 / ID |
| `parent_entity_id` / `grand_entity_id` | 父类 / 二级父类实体 |
| `follow_status` | 状态位：0无效，1有效 |
| `follow_time` | 关注时间（探数时排除 `1000-01-01 00:00:00`） |
| `follow_price` / `follow_source` | 关注时价格 / 来源 |
| `create_time` / `update_time` | 创建 / 修改时间 |
| `pt` | 分区 |

## 链家关键字段

| 字段 | 含义 |
|------|------|
| `user_id` | 用户 id |
| `entity_type` / `entity_id` | 关注实体类型 / ID |
| `status` | 0无效，1有效 |
| `create_time` / `update_time` | 创建 / 修改时间 |
| `city_code` | 城市编码 |
| `favorite_id` / `topic_sign` / `detail_json` | 关注 id / 签名 / 详情 JSON |
| `pt` | 分区 |

## 必带过滤

```sql
WHERE pt = '${-1d_pt}'
-- 贝壳
  AND follow_status = '1'
  AND follow_time != '1000-01-01 00:00:00'
-- 链家
  AND status = '1'
```

## 关联表

| 表 | 用途 |
|----|------|
| `rpt.rpt_comm_hdel_housedel_info_da` | 二手房 `entity_id`（housedel_id）→ `resblock_id`（关注归一小区） |

## 历史用法

| 场景 | 路径（`01 商业分析师/`） |
|------|--------------------------|
| 近 60 天关注小区 + 居室画像 | `01 经纪业务/05 榜单/20240730 榜单推送用户圈选/` |
| 浏览房源≥3 天且未关注 | 同上 `--近7天浏览某房源大于3天且未关注.sql` |
| 社区指南 Push（关注归一小区） | `01 经纪业务/01 业主端/20240606 社区指南push触达用户/` |

## 坑点

- 表名拼写：贝壳是 `fllow`（少一个 o），不是 `follow`
- 链家窗口条件历史稿写成 `= date_sub(..., 60)`，应改为 `>=`
- 贝壳部分历史脚本用 `create_time` 卡日，探数/正式口径优先 `follow_time`
- 两侧 `entity_type` 取值可能不一致，UNION 前先分别探枚举
