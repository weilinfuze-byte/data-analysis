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
| content_tag | array\<string\> | 内容中台标签（供给侧枚举，见下文） | 否 |
| status | bigint | 状态（`4`=已上线） | 否 |
| ctime | string | 创建时间 | 否 |
| mtime | string | 修改时间 | 否 |
| publish_time_on | string | 首次上线时间 | 否 |
| publish_time | string | 上线时间 | 否 |
| admin_ucid | string | 贝壳号管理员 ucid | 否 |
| im_ucid | string | **经纪人 ucid**（内容生产人；关联员工表主键） | 否 |
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
- `im_ucid` 空值高：北京上线内容约 78% 为空（2026-08-14）；按大部/投稿人数会漏无经纪人内容

### 实体挂载数组（2026-09）

| 字段 | 用法 |
|------|------|
| `resblock_ids` | 挂小区；非空且 `size(resblock_ids) > 0` |
| `project_names` | 挂新房楼盘；非空且 `size(project_names) > 0` |
| `house_ids` | 挂房源；房源数 = `nvl(size(house_ids), 0)`（null/空=0） |
| 双挂 | 同时挂小区+楼盘：两条件同时成立 |
| 房源↔内容 | `LATERAL VIEW explode(house_ids)` 后按 `house_id` 计 `distinct content_id` |

探查 SQL：`北京内容供给/bj_content_resblock_project_dual_tag.sql` 等。

### content_tag 枚举与主理人识别（2026-08-14 confirmed）

> **勿与流量中间表的 `content_tag` 混淆**。本表 `content_tag` 是内容中台供给侧标签，类型 `array<string>`。流量侧同名字段是埋点文案/标签，且 **按表取不同 key**：首页 feed `$.content_tag`（2026-09-11）；内容 feed `$.content_title`。

<!-- as of 2026-08-14, source: 主理人视频详情页曝光/curator_content_tag_enum.sql Query1, pt=20260813000000, SPARK_KYUUBI -->

| content_tag | 含义 | 备注 |
|-------------|------|------|
| `curator_content` | **主理人内容** | 已上线约 345 条（全国，status=4，该 pt） |
| （另 2 个 tag） | 待补全 | Query1 全量仅 3 个 tag；其余 2 个待枚举贴回后补充 |

**主理人内容（推荐口径）**：

```sql
array_contains(t1.content_tag, 'curator_content')
```

**交叉校验（物料类型）**：`resource_type LIKE 'curator_%'` 亦对应主理人（见 `北京内容供给/workflow.sql` CASE 映射）。两口径不一致时用 Query3 交叉表核对。

**枚举探查**（`LATERAL VIEW explode`）：

```sql
SELECT
    t2.tag                                    AS content_tag
    ,count(DISTINCT t1.content_id)            AS content_cnt
FROM rpt.rpt_feed_content_analyze_table t1
LATERAL VIEW explode(t1.content_tag) t2 AS tag
WHERE t1.pt = '${-1d_pt}'
  AND t1.status = 4
  AND t1.content_id IS NOT NULL
  AND cast(t1.content_id AS string) NOT IN ('-911', 'null')
  AND t2.tag IS NOT NULL
  AND trim(t2.tag) <> ''
GROUP BY
    t2.tag
ORDER BY
    content_cnt DESC
```

**覆盖率**：`explode` 会丢掉 `content_tag` 为空的行；核对漏标用 `count(distinct content_id)` 对比全量 / 有 tag / 主理人 tag。项目 SQL：`主理人视频详情页曝光/curator_content_tag_enum.sql`（Query6–8）。

**分发日指标（给业务方）**：主理人池 = `array_contains(content_tag,'curator_content')`，**不限 status**；JOIN 五场景卡片曝光/点击（**暂不含详情页曝光**）。优先中间表版，无权限用底表版。模板 [curator_distribution_daily.md](../templates/curator_distribution_daily.md)；项目 SQL：`主理人视频详情页曝光/curator_distribution_daily.sql` / `curator_distribution_daily_base.sql`。

## 已知数据质量（2026-08 demo）

- `content_tag` / `content_quality` / `publish_time_on` 曾大量空或 epoch
- `publish_time` 部分为 epoch
- 贝壳号侧字段（`admin_ucid` 等）可能有空值

### 生产人 → 员工表（Locked）

| 项 | 口径 |
|----|------|
| 内容生产表经纪人键 | **`im_ucid` = 经纪人 ucid** |
| 关联员工表 | `im_ucid` = `rpt_comm_agent_allinfo_employee_da.employee_ucid`（字段见 [comm_agent_allinfo_employee_da.md](comm_agent_allinfo_employee_da.md)） |
| **禁止** | 勿用 `admin_ucid` 关联员工表（北京实测 0% 命中） |

**北京关联校验（2026-08-14 confirmed）**

<!-- source: 北京内容商机分大部/check_im_ucid_agent_join.sql Query2；北京 city_id=110000，status=4，pt=昨天 -->

| 关联键 | 内容量 | 键为空 | 关联成功 | 有值未关联 | 有值关联成功率 |
|--------|--------|--------|----------|------------|----------------|
| `admin_ucid` | 802,012 | 398,720 | **0** | 403,292 | **0.00%** |
| `im_ucid` | 802,012 | 627,278 | 173,381 | 1,353 | **99.23%** |

结论：**只用 `im_ucid`**；`admin_ucid` 有值也关联不上员工表。

```sql
-- 生产 → 员工（Locked）；JOIN 前剔 im_ucid 异常值
t1.im_ucid = t2.employee_ucid

and t1.im_ucid is not null
and t1.im_ucid not in ('-911','null')
```

校验 SQL：`北京内容商机分大部/check_im_ucid_agent_join.sql`

## 引用本表的指标 / 分析

- [内容生态 · 内容供给](../metrics/content-ecology.md#内容供给存量)
- 北京内容供给盘点（`resource_type` 一/二级 CASE）
- 内容商机按生产人拆：只用 `im_ucid` → 员工表 `employee_ucid`
