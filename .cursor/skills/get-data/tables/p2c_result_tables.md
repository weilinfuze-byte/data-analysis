# P2C 自建结果底表

> 来源 ETL：`04 交易P2C/01 数据分析/【看板底表】*.sql`

## rpt.rpt_p2c_dau_result_di

| 字段 | 说明 |
|------|------|
| active_date | 活跃日期 |
| uicode | 页面标识；`all` 为汇总 |
| uv | DAU（ucid 去重） |
| pt | 分区 |

看板模型 uicode 映射：

| uicode | 页面 |
|--------|------|
| osa_jiaoyizhuanjia | 会话页 |
| transaction_expert_person | 个人主页 |
| transaction_expert_articlelist | 内容列表页 |
| transaction_expert_articledetail | 内容详情页 |
| transactionexpert_moments | 动态主页 |
| all | 全部 |

## rpt.rpt_p2c_rukou_rusult_di

| 字段 | 说明 |
|------|------|
| name | 入口名称（底部轮播、消息列表、动态主页切换） |
| uicode | 页面 |
| expo_pv/uv, click_pv/uv | 曝光/点击 |
| pctr, uctr | 次数/人数点击率 |

## rpt.rpt_p2c_huihua_rusult_di

| 字段 | 说明 |
|------|------|
| active_uv | 会话页 DAU |
| kaikou_uv | 开口人数 |
| gongju_uv | 工具完整使用人数 |

## 查询示例

```sql
SELECT active_date AS "活跃日期", uv AS "DAU"
FROM rpt.rpt_p2c_dau_result_di
WHERE pt BETWEEN '20260305000000' AND '${-1d_pt}'
```
