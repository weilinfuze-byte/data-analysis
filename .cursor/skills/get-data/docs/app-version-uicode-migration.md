# App 发版与 uicode / evt 迁移口径

> as of 2026-08-05。埋点表里「0624」「0806」等日期是 **App 发版 / 埋点上线日**，不是 SQL 里按 `active_date` 切流的截止日期。

## 核心概念

App 发版后，**只有更新了 App 的用户**才会进入新页面、上报新 `uicode`、新 `evt_id`、新 `action` 字段。

未更新 App 的用户继续使用旧页面，照常上报旧 `uicode` 与旧 `evt_id`。

因此：

- 同一天内，新旧两套埋点 **并行存在**
- 发版日之后的历史区间里，旧埋点仍会持续有量（直到旧版本用户自然淘汰）
- **禁止**用 `active_date >= 'YYYY-MM-DD'` 切换 `uicode` 或 `evt_id`

## SQL 硬规则

### ✅ 正确：全集 `IN`；action 按参数表单 key 直取

```sql
-- 内容 feed：两套 uicode 全部 evt 纳入
AND lower(uicode) IN ('new_kandian_homepage', 'content/kandian/recommend')

-- 参数表已给固定 key → 直接 get_json_object（0806 是发版说明，不是 JSON 后缀）
,get_json_object(action, '$.article_id') AS content_id
,get_json_object(action, '$.business_type') AS share_media
```

参数表只列一套 key 时 **不要 COALESCE**。仅当表内明确写了「evt A 用 `fb_item_id`、evt B 用 `content_id`」等多套 key 时，才用 `CASE WHEN evt_id` 或 `COALESCE`（见搜索结果页横卡/竖卡）。

### ❌ 错误：用 active_date 当版本切换

```sql
-- 会漏掉发版后仍未升级 App 的用户（旧 uicode / 旧 evt）
AND (
    lower(uicode) = 'new_kandian_homepage' AND active_date >= '2025-06-24'
 OR lower(uicode) = 'content/kandian/recommend' AND active_date < '2025-06-24'
)
```

## 埋点表日期标注的含义

| 标注 | 含义 | SQL 用法 |
|------|------|----------|
| `0624` / `0624后` | 该日 App 发版后 **新版本** 使用的 uicode / evt / action key | 写入文档与注释；过滤用 `IN` 纳入新版 |
| `0806` / `0806+` | 该日埋点参数 key 变更 | 以参数表列为准直取 key；多套 key 才 `CASE evt_id` |
| `0709+` | 该日 tab / 模块等产品形态变更 | 若新旧 evt 不同则 `IN` 两套 evt；若同一 evt 则靠 action 字段区分 |

日期标注用于 **说明哪套埋点对应哪次发版**，不是 `WHERE active_date` 的切分条件。

## 何时可以用 active_date

| 场景 | 是否用 active_date |
|------|-------------------|
| 日常分区 `pt`、指标统计窗口 | ✅ |
| 选择 uicode / evt_id 全集 | ❌ 用 `IN` |
| 解析 action 新旧 key | ❌ 用 `evt_id`（或极少数无 evt 区分时再问产品） |
| 分析「发版后新版本渗透率」 | ✅ 可结合 `client_app_version` 或发版日做专题分析 |
| AB / 实验分组 | ✅ 按实验配置，另见 ab_test 模板 |

## 何时用 client_app_version

- **全量指标**（曝光 UV、UCTR 等）：一般 **不按版本过滤**，新旧并行合计
- **版本专题**（新埋点覆盖率、发版效果）：可用 `client_app_version >= 'x.y.z'` 或版本分布表
- **禁止**用版本号替代 `IN` 全集来捞数——未升级用户不会上报新版本号，但旧埋点仍在

## 已落地示例

| 场景 | 新版 | 旧版 | 中间表 / SQL |
|------|------|------|--------------|
| 内容 feed uicode | `new_kandian_homepage` | `content/kandian/recommend` | `rpt.rpt_content_feed_flow_di`（全部 evt；action 按参数表直取） |
| 搜索综合横卡 | 80326/80327 + module | 93750/93751 | `search_result_flow.sql`（两套 action key，按 evt_id CASE） |

## 写 SQL 前自检

1. 埋点表出现「0624后」「0806+」→ 是否误写成 `active_date` 条件？
2. 同一业务页面是否 `IN` 了全部 uicode（及需要的全部 evt）？
3. action：参数表只列一套 key → 直取；多套 key 才按 `evt_id` `CASE` / `COALESCE`？
4. 注释里是否写清发版日含义，避免后人再加日期过滤？
