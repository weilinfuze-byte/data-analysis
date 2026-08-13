---
name: get-data
version: 1.0.0-beike
description: 贝壳 Hive SQL 取数规范与数据字典。写 SQL、查表字段、查埋点 evt_id、查指标口径时触发。
---

# 贝壳 Hive SQL Skill

> 使用当前 Cursor 会话登录的公司 SSO 账号（不要写死姓名/工号）。
> 数仓：Hive + Tez。调度参数：`${-1d_pt}`、`${-1d_yyyy-MM-dd}`、`${-7d_pt}`。
> 本仓库 `.cursor/skills/get-data/` 是团队共享字典；写 SQL 前先查这里，不要依赖某人本机的历史 SQL 目录。
> 内部表信息查询：`http://factory.data.ke.com/tableSearch`。

## 全局规则

- 表名格式：`{layer}.{table}`，如 `rpt.rpt_log_bi_user_behivor_detail_flow_di`
- **分区必带**：`pt = '${-1d_pt}'` 或 `pt between 'YYYYMMDD000000' and '${-1d_pt}'`
- **禁止**不带 pt 扫全表
- 底表 ETL 必须带 Tez 加速 set 块（见下方）
- 两层架构：【看板底表】`insert overwrite table rpt.rpt_xxx_di partition (pt=...)` → 【看板模型】`SELECT ... AS \`中文列名\``
- **建表 / DDL**：见配套 skill [create-hive-table](../create-hive-table/SKILL.md)（DDL 注释写文件头；INSERT 在最终 SELECT 前）
- **SQL 书写风格**（硬规则）：见 [docs/sql-style.md](docs/sql-style.md)
  - SELECT 字段逗号前置（写在下一行字段前）
  - CTE 衔接：`)` 换行后 `,name AS (`（逗号在下一 CTE 名前；禁止 `),\n,` 双逗号）
  - 表别名统一 `t1` / `t2` / `t3`…
  - 结果列名用英文；优先 `LEFT JOIN`
  - **非建表直接查数**：中文别名只用反引号 `` AS `中文` ``，**禁止**双引号 `AS "中文"`
- 写 SQL 前必须先查 tables/、metrics/、events/，禁止猜字段名
- **内容生态取数：中间表优先**（硬规则）：字典已有该场景中间表时，分发 / 消费 / 周报 / 物料 CTR **先扫中间表**，禁止默认扫 `rpt.rpt_comm_log_beike_exp_detail_di` / `rpt.rpt_log_bi_user_behivor_detail_flow_di`。例外：Locked 模板明确写「走底表」（如点后推二导新户型卡），或该页面尚未建中间表。中间表索引见 [tables.md](tables.md)
- 本地字典没有的表，先查内部表检索：`http://factory.data.ke.com/tableSearch`
- 若内部表检索需要登录，唤起 Cursor 内置浏览器，并提示用户在前端完成 SSO 登录；不要索要账号密码
- **查表权限 / 申请查询·开发权限**：见配套 skill [hive-table-permission](../hive-table-permission/SKILL.md)
- **改完 SQL 后**（硬规则）：每次新建或修改 `.sql` 后，回复用户前必须用 `cursor-app-control` MCP 的 `open_resource` **只打开该 `.sql` 文件**（编辑器右侧）；改多个 SQL 时至少打开本次主要交付文件；URI 用绝对路径，中文/空格需 URL encode。**禁止**打开 Source Control / Changes / Agent diffs 面板

## 改完 SQL 后打开文件

1. SQL 写入/修改完成后，**最后一动**调用 `open_resource` 打开对应 `.sql`（`file://` 指向该文件）
2. 用户说「打开 xxx.sql」时也走同样方式
3. **只打开 SQL 文件本身**。不要用 `open_resource` 打开 git / Source Control / Changes / Agent diffs；用户没点名这些面板时，不要把它们带到前台
4. 示例：

```
CallMcpTool server=cursor-app-control toolName=open_resource
arguments: { "uri": "file:///Users/.../content_detail_flow.sql" }
```

## Tez 加速标准块（底表任务必带）

```sql
set hive.exec.orc.split.strategy=BI;
set hive.auto.convert.join = true;
set hive.mapjoin.smalltable.filesize=300000000;
set hive.auto.convert.join.noconditionaltask = true;
set hive.auto.convert.join.noconditionaltask.size = 500000000;
```

**禁止**再加 `set hive.cte.materialize.threshold=...`（本集群不支持，SET 阶段直接报错）。

## 写 SQL 前必问的 4 维度

若用户未指定，**必须询问**，不要假设默认值：

| 维度 | 常见选项 |
|------|----------|
| 站点 | beike / lianjia / 贝壳+链家 |
| 端 | app / xcx / m |
| 业务线 | 二手 / 新房 / 大首页 / 推荐 / 榜单 / 我家 / 交易专家(P2C) |
| 日期 | 昨天 / 近 7 天 / 固定窗口 |

不要默认查全历史；除非用户明确要求，限制在最近 30 天或 6 个月内。

## duid 与 ucid（硬规则）

| 字段 | 含义 | 说明 |
|------|------|------|
| `duid` | 设备 ID | 未登录也有 |
| `ucid` | 账号 ID | **只有登录之后才有** |

关系：

- 一个设备可以登录多个账号
- 一个账号可以在多个设备登录

**人数 / UV 口径变更（2026-08 confirmed）**：所有人数指标统一改为 **`duid` 去重**（含内容生态：卡片曝光/点击人数、内容消费人数、留存/复访等）。原先用 `ucid` 去重的历史口径已废弃，新 SQL 不要继续用 `ucid` 算 UV。

## 去重键规范（硬规则）

| 场景 | 去重键 |
|------|--------|
| DAU / MAU / 留存 / AB / Feed 漏斗 / **内容生态人数 UV** | **duid** |
| 商机 / 成交 / 用户画像 | **ucid** |
| P2C 会话开口（IM） | **from_ucid**（`LIKE '200%'`） |

同一份报告内不可混用 duid 与 ucid。内容生态指标详见 [metrics/content-ecology.md](metrics/content-ecology.md)。

## 通用异常值过滤（硬规则）

做 UV/人数去重、以及**任何关联键 JOIN 前**，必须先剔异常值。不限字段名（`ucid` / `duid` / `cust_ucid` / `housedel_id` / `resblock_id` 等凡作关联键的均适用）：

```sql
and {key} is not null
and {key} not in ('-911','null')
```

- **禁止**再剔 `''`、`' '`（会把结果滤空）
- 在关联前于各侧子查询内写好，不要等到 JOIN 后再补

客源桥 `dw.dw_cdel_custdel_da.customer_uid`（新房成交 / 带看 → ucid）保留专用口径（多剔 `'0'`）：

```sql
and customer_uid not in ('-911','0')
and customer_uid is not null
```

## 标准流量字段块

从行为/曝光表 SELECT 时，保持列对齐以便 UNION ALL：

```sql
active_date, dp, site, uicode, pid, evt_id, action,
duid, ucid, client_time, client_os_type, client_os_version,
client_app_version, city_code, city_name, business_name
```

## 写 SQL 前查字典

| Concern | Read first |
|---------|------------|
| 表结构 / 字段 | [tables.md](tables.md) → tables/*.md |
| 新表 / 字段不确定 | [docs/internal-table-search.md](docs/internal-table-search.md) + `http://factory.data.ke.com/tableSearch` |
| 指标口径 | [metrics.md](metrics.md) → metrics/*.md（含 [metrics/hefang.md](metrics/hefang.md) 新房/二手核访） |
| evt_id 含义 | [events/beike_evt_id.md](events/beike_evt_id.md) |
| App 发版 / uicode 迁移（禁止按 active_date 切埋点） | [docs/app-version-uicode-migration.md](docs/app-version-uicode-migration.md) |
| 切片维度 | [dimensions.md](dimensions.md) |
| 产品背景 | [business/beike-app.md](business/beike-app.md) |
| P2C 交易专家 | [business/p2c-transaction-expert.md](business/p2c-transaction-expert.md) |

**禁止**：
- 未读字典就写 evt_id / uicode 过滤
- 内容生态已有中间表时仍去扫曝光/行为底表（点后推等 Locked「走底表」模板除外）
- 用 `active_date` 切换 uicode / evt_id（发版日只作注释；新旧并行用 `IN` 全集，见 [app-version-uicode-migration.md](docs/app-version-uicode-migration.md)）
- metrics/ 已有标准定义时自行发明公式
- 未验证数据存在就写完整分析框架
- 表不在字典中时凭记忆猜字段名或分区规则
- 内部站点未登录时向用户索要账号密码

## 使用已有指标时，先查规范定义

触发场景：指标看起来太高/太低、迭代现有看板、对齐他人口径。

1. 查 `metrics.md` → `metrics/*.md`
2. 查本仓库已有项目 SQL（各分析目录下的 `.sql`）和 [templates/](templates/)；不要假设同事本机有分享者的历史看板目录

## Locked SQL 模板

以下场景**先读模板，只替换标记参数**，不改 CTE 结构、JOIN 路径、过滤逻辑：

| 触发场景 | 模板 |
|----------|------|
| 页面流量 UNION（点击+曝光） | [templates/traffic_union.md](templates/traffic_union.md) |
| AB 实验（duid + 版本过滤） | [templates/ab_test_duid.md](templates/ab_test_duid.md) |
| N 日留存 / 复访 | [templates/retention_fufang.md](templates/retention_fufang.md) |
| 页面商机（按 adid 展位） | [templates/page_sj_by_adid.md](templates/page_sj_by_adid.md) |
| 商机溯源（uicode / ele_app_id） | [templates/sj_attribution_by_scene.md](templates/sj_attribution_by_scene.md) |
| 新二成交用户日清单 | [templates/deal_ershou_xinfang.md](templates/deal_ershou_xinfang.md) |
| 新二有效带看用户日清单 | [templates/show_ershou_xinfang.md](templates/show_ershou_xinfang.md) |
| P2C DAU 底表 | [templates/p2c_dau_etl.md](templates/p2c_dau_etl.md) |
| P2C 入口曝光点击 | [templates/p2c_entry_funnel.md](templates/p2c_entry_funnel.md) |
| P2C 会话明细 | [templates/p2c_chat_detail.md](templates/p2c_chat_detail.md) |
| 用户关注实体（贝壳+链家） | [templates/user_follow.md](templates/user_follow.md) |
| 结果底表建表 DDL | [create-hive-table](../create-hive-table/SKILL.md) |
| 内容生态中间表 ETL（详情页/搜索页/内容feed/首页feed/二手详情/小区详情） | [templates/content_ecology_intermediate_flow.md](templates/content_ecology_intermediate_flow.md) |
| 内容详情页每日流量（中间表聚合） | [templates/content_detail_daily_traffic.md](templates/content_detail_daily_traffic.md) |
| 搜索结果页内容横卡 CTR | [templates/search_content_card_ctr.md](templates/search_content_card_ctr.md) |
| 点后推二导新户型卡 CTR（搜索+二手首页，流量底表） | [templates/ershou_push_huxing_card_ctr.md](templates/ershou_push_huxing_card_ctr.md) |
| 首页feed物料 PCTR/UCTR（一级×二级） | [templates/homepage_feed_material_ctr.md](templates/homepage_feed_material_ctr.md) |
| 内容卡片周报（整体/分场景日指标） | [templates/content_weekly_scene_metrics.md](templates/content_weekly_scene_metrics.md) |

## 输出规范

- 每个比率必须展示分子分母
- evt_id 必须注明业务含义（查 events/ 或 inline 注释）
- 新指标若 metrics/ 无定义，列出候选定义让用户选择
- 结论必须声明口径（如「DAU = evt_id 1,3 去重 duid」）

## 维护字典

SQL 因字段/类型与字典冲突失败时，修 SQL **并更新** 本仓库 `.cursor/skills/get-data/` 下的 tables/*.md 或 metrics/*.md（不要写到 `~/.cursor/skills/`）。确认后提醒用户 commit / push，同事 `git pull` 才能拿到。

### 写 SQL 过程中的自动沉淀

和用户一起写 SQL 时，如果发现新的可复用信息，必须先暂存并在本轮或收尾时向用户确认，确认后再更新 Skill。不要未经确认直接沉淀。

需要触发确认的新增信息包括：

- 新 `uicode` 或已有 `uicode` 的页面名称修正
- 新 `evt_id` 或已有 `evt_id` 的业务含义修正
- 新表、表中文名、字段、分区字段、权限/负责人信息
- 新指标口径、分子分母、过滤条件
- 新 SQL 模板、JOIN 路径、已踩坑

确认话术示例：

> 这次 SQL 里出现了新的 `uicode = 'xxx'`，我理解它是「xxx 页面」。是否确认写入 Skill？

确认后按内容类型写入：

| 新信息 | 写入位置 |
|--------|----------|
| `uicode` / 页面名称 | `dimensions.md` 或新增 `events/uicode_mapping.md` |
| `evt_id` / 事件含义 | `events/beike_evt_id.md` |
| 新表 / 字段 / 分区 | `tables.md` + `tables/*.md` |
| 新指标口径 | `metrics.md` + `metrics/*.md` |
| 新 SQL 模板 | `templates/*.md` + Locked Templates 表 |
| 业务知识 / 产品规则 | `business/*.md` |

新增表或字段口径来自内部表检索时，在对应 `tables/*.md` 中注明：

```md
<!-- as of YYYY-MM-DD, source: http://factory.data.ke.com/tableSearch -->
```

定期整理规则见 [docs/content-routing.md](docs/content-routing.md)。

## 字典索引

| 查什么 | 读哪里 |
|--------|--------|
| 表索引 | [tables.md](tables.md) |
| 指标索引 | [metrics.md](metrics.md) |
| 维度 | [dimensions.md](dimensions.md) |
| 埋点 | [events/beike_evt_id.md](events/beike_evt_id.md) |
| 业务 | [business/](business/) |
| 模板 | [templates/](templates/) |
| SQL 书写规范 | [docs/sql-style.md](docs/sql-style.md) |
| App 发版与 uicode 迁移 | [docs/app-version-uicode-migration.md](docs/app-version-uicode-migration.md) |
| 内部表检索 | [docs/internal-table-search.md](docs/internal-table-search.md) |
