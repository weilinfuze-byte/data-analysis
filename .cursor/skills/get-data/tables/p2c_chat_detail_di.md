# rpt.rpt_p2c_chat_detail_di / Roomie 会话

## 底表：rpt.rpt_p2c_chat_detail_di

ETL 来源：[templates/p2c_chat_detail.md](../templates/p2c_chat_detail.md)

| 字段 | 说明 |
|------|------|
| msg_date | 消息日期 |
| from_role | 专家 / 用户 |
| ori_msg_type_desc | 文本 / 卡片 |
| msg_src_type | 手动输入 / 工具默认 / 系统默认 / 猜你想问 / 推荐问题 |
| tool_name | 购房能力评估、房贷方案等 |
| tool_card_type | 信息卡 / 结果卡 |
| from_ucid, to_ucid | 发送方/接收方 |
| session_id, round_num | 会话 ID / 当日轮数 |

## 原始表

### olap.olap_plat_huiju_chat_workbench_private_chat_record_da

私聊消息原始记录。过滤：

```sql
WHERE pt = '${-1d_pt}'
  AND substr(msg_time, 1, 10) = '${-1d_yyyy-MM-dd}'
  AND robot_name = '交易专家'
```

JSON 解析字段：`from_ucid`, `to_ucid`, `msg_src`, `tool_key`, `tool_value`, `card_status`, `cardID`

### olap.olap_plat_huiju_chat_workbench_user_session_da

会话维度：assign_time, end_time, session_status, round_num

## 开口说话判定（会话分析）

```sql
WHERE from_role = '用户'
  AND ori_msg_type_desc = '文本'
  AND msg_src_type = '手动输入'
```

## tool_value 映射

| tool_value | 工具 |
|------------|------|
| 1 | 购房能力评估 |
| 2 | 房贷方案 |
| 3 | 税费计算 |
| 4 | 购房成本规划 |
| cardID 1020 | 房源信息卡 |
| cardID 1022 | 专家欢迎卡 |
