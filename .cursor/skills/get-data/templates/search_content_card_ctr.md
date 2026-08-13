# 搜索结果页内容横卡 CTR（Locked）

> 从中间表 `rpt.rpt_content_search_result_flow_di` 聚合，不扫底表。
> 项目 SQL：`内容生态指标体系/search_content_card_ctr.sql`
> as of 2026-08-05

## 横卡口径

| 类型 | 条件 | 曝光 | 点击 |
|------|------|------|------|
| 新横卡（0806+） | `tab_name=综合` AND `module_type=contentCardModule` | 80326 | 80327 |
| 旧横卡（0806前） | 落表已固定 tab/module | 93750 | 93751 |

```sql
-- 曝光
(evt_id = '80326' AND tab_name = '综合' AND module_type = 'contentCardModule')
OR evt_id = '93750'

-- 点击
(evt_id = '80327' AND tab_name = '综合' AND module_type = 'contentCardModule')
OR evt_id = '93751'
```

## 指标（Locked）

| 指标 | 定义 |
|------|------|
| expo_uv / click_uv | `COUNT(DISTINCT duid)` |
| expo_pv / click_pv | `COUNT(DISTINCT concat(nvl(fb_expo_id,''), '#', duid))` —— **按 fb_expo_id × duid 去重** |
| uctr | click_uv / expo_uv |
| pctr | click_pv / expo_pv |

去重前：

```sql
and duid is not null
and duid not in ('-911','null')
```

## 输出

`active_date / expo_uv / expo_pv / click_uv / click_pv / uctr / pctr`

以曝光侧为左表 `LEFT JOIN` 点击侧。

## 注意

- 竖卡（`module_type=contentFeed`）不在此口径
- 内容 tab 竖卡不在此口径
- 中间表字段已预解析，直接用 `tab_name` / `module_type` / `fb_expo_id`，不要再 `get_json_object`
- **点后推二导新户型卡**不走本模板，见 [ershou_push_huxing_card_ctr.md](ershou_push_huxing_card_ctr.md)
