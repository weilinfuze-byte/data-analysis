---
name: create-hive-table
description: >-
  贝壳 Hive 结果表 / 中间表：默认写带 DDL 注释的落表 SQL 文件给用户自己去数据工厂建表；
  仅当用户明确要求操作工厂 UI 时才打开浏览器填表。触发：建表、新建表、DDL、
  CREATE TABLE、结果指标表、底表落表、数据工厂建表。
---

# 贝壳 Hive 建表 Skill

> 取数口径 / 埋点 / SQL 风格仍走 [get-data](../get-data/SKILL.md)。
> 内部入口：`http://factory.data.ke.com/tableSearch`（需公司 SSO；勿索要账号密码）。

## 默认交付模式（硬规则）

用户说「建表 / 落表 / 写 ETL / DDL / 新建表」且**没有明确**要求 Agent 操作数据工厂时：

1. **只写/改项目目录下的 `.sql` 文件**（文件头：中文名、英文名、工厂表单填法、完整 DDL 注释含每字段中文 COMMENT；文件体：Tez set + CTE + INSERT OVERWRITE）
2. **禁止** `browser_navigate` / 内置浏览器打开数据工厂建表页
3. **禁止**额外新建 `factory_create_tables.md` 等「工厂复制粘贴」文档；工厂信息写在 SQL 文件头即可（可选：同目录 `rpt_*.md` 表说明，不替代 SQL）
4. 交付后用 `open_resource` **打开该 `.sql`**（见 [get-data](../get-data/SKILL.md)）；不要优先打开 `.md`

仅当用户明确说以下之一，才走「二、数据工厂 UI」：

- 「打开数据工厂」「帮我填工厂 / 帮我建表（你操作）」「干吧（填表）」
- 「一步一步填」「你来点新建表」

未点名 → 一律按写 SQL 文件处理，并简短提示用户自行去工厂粘贴 DDL。

## 何时使用

- **默认**：给 ETL SQL 补建表 DDL 注释 + INSERT，用户自己去工厂建表
- **显式要求时**：在数据工厂 UI 代填基本信息 / 生命周期
- 拟定中英文表名并对齐工厂表单填写口径（写在 SQL 文件头）

---

## 一、SQL 侧 DDL 与落表规范（默认路径）

### 命名

| 项 | 规则 | 示例 |
|----|------|------|
| 英文完整表名 | `rpt.rpt_{业务}_{主题}_result_di` | `rpt.rpt_content_ecology_user_retention_bj_result_di` |
| 中文名 | 写文件头；不写进 DDL 表级 COMMENT | 内容生态用户层面留存结果指标表_北京 |
| HDFS | `hdfs://ns-fed/user/bigdata/rpt/{表名不含库}` | 与 `rpt_` 开头的表名一致 |
| 分区 | `pt string` | — |

### 表名前缀规则（硬规则，易错）

- SQL / DDL 完整表名：`rpt.rpt_{业务}_{主题}_result_di`（带库前缀 + 表名里的 `rpt_`）
- 工厂页：库/层级选 **rpt** 后，输入框**前面已默认显示 `rpt_`**
- 因此表单「表名称」**只填去掉 `rpt_` 后的后半段**

| SQL 完整名 | 工厂表单只填 |
|------------|--------------|
| `rpt.rpt_content_ecology_user_retention_bj_result_di` | `content_ecology_user_retention_bj_result_di` |

禁止：在已选库 `rpt`、前缀已是 `rpt_` 的情况下，再手写一遍 `rpt_`（会变成 `rpt_rpt_...`）。

### DDL 默认模板（锁定）

**默认只有下面这些。** 每次：① 改完整表名 ② 括号内加字段。分隔符 / 存储 / LOCATION 壳子不动。

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS rpt.{table_name} (

)
partitioned by (pt string)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\u0001'
COLLECTION ITEMS TERMINATED BY '\u0002'
MAP KEYS TERMINATED BY '\u0003'
STORED AS orc
LOCATION 'hdfs://ns-fed/user/bigdata/rpt/{table_name}'
```

字段类型：`string` / `bigint` / `double`；**每个字段** `COMMENT` 用中文。不要加表级 `COMMENT`。

### 写入 SQL 文件（硬规则）

1. DDL **整段注释**写在文件开头（说明之后、`set` / `WITH` 之前）
2. `INSERT OVERWRITE` 在 CTE 之后、最终 `SELECT` 之前
3. **禁止 ORDER BY**（Tez 下 `ORDER BY t1.col` 会报 Invalid alias）
4. CTE 衔接只能 `),\nname AS`，禁止 `),\n,name AS`
5. 字段 COMMENT 不可省略（含从源表拷贝的全量字段）

```sql
-- 中文名: ...
-- 英文名: rpt.rpt_xxx_result_di
-- 建表页注意: 库选 rpt 后前缀已是 rpt_，表单只填 xxx_result_di
-- 建表语句:
-- CREATE EXTERNAL TABLE IF NOT EXISTS rpt.rpt_xxx_result_di ( ... )
-- partitioned by (pt string)
-- ...
-- LOCATION 'hdfs://ns-fed/user/bigdata/rpt/rpt_xxx_result_di'

WITH ... AS (...)
INSERT OVERWRITE TABLE rpt.rpt_xxx_result_di PARTITION (pt='${-1d_pt}')
SELECT ...
;
```

用户自行建表时：打开 `http://factory.data.ke.com/create/tohive`，按文件头口径填基本信息，在「语句添加」空壳括号内粘贴字段后点「解析」。

---

## 二、数据工厂新建表（UI 流程 · 仅显式要求时）

> 未满足上文「显式要求」触发词时，**整章跳过**，不要打开浏览器。

### 1. 打开与登录

1. 打开 `http://factory.data.ke.com/tableSearch`
2. 若跳转 `login.ke.com`：提示用户在 Cursor 内置浏览器完成 SSO，登录后说「继续」
3. 登录后应看到「表查询」页，右上角有「新建表」

### 2. 建表类型

1. 点「新建表」
2. 弹窗「建表类型」里选 **Hive** →「前去创建」
3. 进入 `http://factory.data.ke.com/create/tohive`（步骤：1基本信息 → 2字段信息 → 3数据源 → 4任务调度）

### 3. 基本信息（只改下列项，其余默认不动）

| 表单项 | 怎么填 |
|--------|--------|
| 集群名 | 保持默认「公共集群」 |
| 数据层级 | **应用分析数据** |
| 库/层级 | **rpt** |
| 表名称 | 见上方「表名前缀规则」 |
| 表中文名称 | 与 SQL 文件头中文名一致，可自拟业务可读名 |
| 描述 | 根据 SQL 口径写一句简洁说明（城市/端/指标/窗口等） |
| 权限包 / 分类 / 负责人 / 空间等 | **不改**（沿用页面默认） |

### 4. 数据生命周期配置（硬规则）

| 项 | 取值 |
|----|------|
| 操作类型 | 默认「数据删除」（不改） |
| 数据周期 | 默认「365天」（不改） |
| **执行前需要确认** | 点 **是**（默认常为「否」，必须改） |
| 排除分区 | 不改 |

### 5. 第 2 步字段信息 → 语句添加（硬规则）

1. 点「下一步」进入字段信息后，切到 **语句添加**
2. **默认不是空编辑器**：会自动带出与本 skill「DDL 空壳」一致的建表语句，表名/LOCATION 已按第 1 步填好，字段括号内为空
3. 正确做法：在空壳括号里补字段，再点「解析」；**不要清空重贴整段**（除非用户明确要求）
4. 若进来是空白：异常（多为编辑器被改坏/未加载完），回到上一步再进一次，或刷新重建

### 6. 操作边界

- 用户说「填完基本信息到点下一步停止」：填完规定项 → 点下一步 → **停在字段信息**，不要擅自改语句添加
- 用户说「干吧」再批量填本 skill 规定项；未点名不要改审批/标签/组织等
- 不要擅自提交「仅创建表 / 创建并配置调度」

### 7. 描述写法示例

从 SQL 口径压缩成一句，例如：

> 北京贝壳APP内容详情页用户次日/7日内容留存与复访、APP留存与复访日指标（duid去重）

---

## 三、已落地示例

| 中文名 | SQL 完整表名 | 工厂表单填 |
|--------|--------------|------------|
| 内容生态用户层面分发及消费结果指标表 | `rpt.rpt_content_ecology_user_distribute_consume_result_di` | `content_ecology_user_distribute_consume_result_di` |
| 内容生态用户层面留存结果指标表 | `rpt.rpt_content_ecology_user_retention_result_di` | `content_ecology_user_retention_result_di` |
| 内容生态用户层面留存结果指标表_北京 | `rpt.rpt_content_ecology_user_retention_bj_result_di` | `content_ecology_user_retention_bj_result_di` |
| 内容详情页流量表 | `rpt.rpt_content_detail_flow_di` | `content_detail_flow_di` |
| 搜索结果页内容流量表 | `rpt.rpt_content_search_result_flow_di` | `content_search_result_flow_di` |
| 内容feed流量表 | `rpt.rpt_content_feed_flow_di` | `content_feed_flow_di` |
| 首页feed流量表 | `rpt.rpt_homepage_feed_flow_di` | `homepage_feed_flow_di` |
| 二手房源详情页内容流量表 | `rpt.rpt_content_ershou_detail_flow_di` | `content_ershou_detail_flow_di` |
| 小区详情页内容流量表 | `rpt.rpt_content_resblock_detail_flow_di` | `content_resblock_detail_flow_di` |
| 内容商机明细中间表 | `rpt.rpt_content_sj_trans_detail_da` | `content_sj_trans_detail_da` |

对应 SQL：`内容生态指标体系/workflow.sql`、`content_retention.sql`、`content_detail_flow.sql`、`search_result_flow.sql`、`content_feed_flow.sql`、`homepage_feed_flow.sql`、`content_ershou_detail_flow.sql`、`content_resblock_detail_flow.sql`、`北京内容商机分大部/content_sj_trans_detail_da.sql`。

---

## 四、检查清单

### 默认路径（写 SQL）

- [ ] 已写入/更新 `.sql`，未擅自开数据工厂浏览器
- [ ] 未新建 `factory_create_tables.md` 类冗余文档
- [ ] DDL 注释在文件头，壳子未改；每字段有中文 COMMENT
- [ ] LOCATION 与完整表名一致
- [ ] INSERT 在最终 SELECT 前，无 ORDER BY
- [ ] CTE 无双逗号
- [ ] 字段与 SELECT 列顺序、类型一致
- [ ] 文件头含：中文名、英文名、工厂表单只填后半段说明
- [ ] 改完后已用 `open_resource` 打开该 `.sql`（不要打开 Source Control / Changes，见 [get-data](../get-data/SKILL.md)）

### UI 路径（仅用户明确要求时代填）

- [ ] 类型选 Hive
- [ ] 数据层级 = 应用分析数据
- [ ] 库/层级 = rpt
- [ ] 表名称**未**重复手写 `rpt_`（只用后半段）
- [ ] 中文名、描述已填且与口径一致
- [ ] 执行前需要确认 = **是**
- [ ] 未改其它默认项；未擅自点下一步（除非用户要求）
