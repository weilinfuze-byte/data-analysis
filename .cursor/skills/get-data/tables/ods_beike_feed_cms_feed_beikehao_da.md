# ods.ods_beike_feed_cms_feed_beikehao_da

> 贝壳号 ODS。用于校验内容生产表 `beikehao_id` / `im_ucid` 是否与号侧一致。
> as of 2026-09-11, source: 北京内容商机分大部/check_content_vs_beikehao_im_ucid.sql

| 元信息 | 值 |
|--------|----|
| 全名 | `ods.ods_beike_feed_cms_feed_beikehao_da` |
| 分区 | `pt` |
| 关联内容表 | `ods.id` = `rpt.rpt_feed_content_analyze_table.beikehao_id` |

## 常用字段

| 字段 | 含义 |
|------|------|
| `id` | 贝壳号 id（= 内容表 `beikehao_id`） |
| `im_ucid` | 号侧经纪人 / IM ucid |

## 校验要点

- 对比两侧 `im_ucid` 是否同一人时：先按 `id = beikehao_id` JOIN，再比 `im_ucid`
- 员工组织仍走内容表 **`im_ucid` = `employee_ucid`**（见 [feed_content_analyze_table.md](feed_content_analyze_table.md)）；不要用号侧字段替代该 Locked 规则，除非用户明确要求
