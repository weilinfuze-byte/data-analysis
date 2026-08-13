# P2C 会话明细底表（Locked）

> 来源：`04 交易P2C/01 数据分析/【数据底表】会话明细.sql`
> 复杂 CASE 逻辑（msg_src_type、tool_name、tool_card_type）勿随意修改。

## 数据源

1. `olap.olap_plat_huiju_chat_workbench_private_chat_record_da` → chat_data CTE
2. `olap.olap_plat_huiju_chat_workbench_user_session_da` → sess_data CTE

## chat_data 过滤

```sql
WHERE pt = '${-1d_pt}'
  AND substr(msg_time, 1, 10) = '${-1d_yyyy-MM-dd}'
  AND robot_name = '交易专家'
```

## 关键衍生字段

| 字段 | 逻辑摘要 |
|------|----------|
| from_role | sender_type=0 → 专家，否则用户 |
| ori_msg_type_desc | 330/331→卡片，-1→文本 |
| msg_src_type | 见 business/p2c-transaction-expert.md |
| tool_name | tool_value 1-4 + cardID 1020/1022 |
| tool_card_type | card_status 0,1→信息卡；2,3,4→结果卡 |

## 输出

```sql
INSERT OVERWRITE TABLE rpt.rpt_p2c_chat_detail_di PARTITION (pt = '${-1d_pt}')
SELECT ... FROM chat_data t1
LEFT JOIN sess_data t2 ON t1.session_id = t2.sess_id
```

## 看板模型过滤

```sql
WHERE ori_msg_type_desc IN ('文本', '卡片')
```
