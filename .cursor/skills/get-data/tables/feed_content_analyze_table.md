# rpt.rpt_feed_content_analyze_table

> 内容中台存量内容分析底表（内容物料参数）。
> as of 2026-08-07, source: 数据工厂 DDL（更正版；此前流量字段 DDL 作废）
> <!-- as of 2026-08-07, source: CREATE EXTERNAL TABLE rpt.rpt_feed_content_analyze_table -->

| 元信息 | 值 |
|--------|----|
| 中文名 | Feed 内容分析表 / 内容中台存量内容底表 |
| 全名 | `rpt.rpt_feed_content_analyze_table` |
| 粒度 | 内容 × 城市（以 `content_id` + `city_id` 为主），按日分区 `pt` |
| 存储 | ORC External；`FIELDS TERMINATED BY '\u0001'` |
| HDFS | `hdfs://ns-fed/user/bigdata/rpt/rpt_feed_content_analyze_table` |
| 工厂表单 | 库选 `rpt` 后只填 `feed_content_analyze_table` |

## 用途

- 内容供给盘点（城市 × `resource_type` × 上线状态 × 发布时间）
- 内容物料参数（房源/小区/商圈/板块等实体、贝壳号、质量标签）
- **勿与** `rpt.rpt_content_detail_flow_di`（内容详情页**流量**中间表）混淆

## 核心字段（数据工厂 DDL 确认）

| 字段 | 类型 | 含义 | 是否分区 |
|------|------|------|----------|
| content_id | bigint | 内容 id | 否 |
| city_id | string | 城市 id | 否 |
| resource_type | string | 内容资源类型（映射一/二级分类） | 否 |
| content_tag | array\<string\> | 标签 | 否 |
| status | bigint | 状态（`4`=已上线） | 否 |
| ctime | string | 创建时间 | 否 |
| mtime | string | 修改时间 | 否 |
| publish_time_on | string | 首次上线时间 | 否 |
| publish_time | string | 上线时间 | 否 |
| admin_ucid | string | admin_ucid | 否 |
| im_ucid | string | im_ucid | 否 |
| user_code | string | user_code | 否 |
| role_type | bigint | role_type | 否 |
| beikehao_id | int | 贝壳号 id | 否 |
| beikehao_name | string | 贝壳号名称 | 否 |
| content_quality | string | 内容质量 | 否 |
| title | string | 内容标题 | 否 |
| head_pic | string | 内容封面 | 否 |
| house_ids | array\<string\> | 房源 id | 否 |
| project_names | array\<string\> | 新房楼盘 | 否 |
| resblock_ids | array\<string\> | 小区 id | 否 |
| district_ids | array\<string\> | 城区 id | 否 |
| bizcircle_ids | array\<string\> | 商圈 id | 否 |
| plate_ids | array\<string\> | 板块 id | 否 |
| biz_format | string | 业态 | 否 |
| entity_type1~5 | string | 实体类型 1~5 | 否 |
| entity_id1~5 | string | 实体 id 1~5 | 否 |
| pt | string | 分区字段 | 是 |

### 使用注意

- 供给盘点常用：`city_id` + `status = 4` + `resource_type` + `publish_time`
- `content_id` 关联前：`is not null and cast(content_id as string) not in ('-911','null')`
- `publish_time` / `publish_time_on` 可能出现 `1970-01-01` epoch，分析前剔除
- 一/二级分类不在表内，按物料表对 `resource_type` 做 CASE；未命中 = `其他`
- 日照类部分 `resource_type` 在物料表中二手/新房重复，需业务确认拆分

## 已知数据质量（2026-08 demo）

- `content_tag` / `content_quality` / `publish_time_on` 曾大量空或 epoch
- `publish_time` 部分为 epoch
- 贝壳号侧字段（`admin_ucid` 等）可能有空值
