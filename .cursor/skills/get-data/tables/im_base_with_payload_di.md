# olap.olap_im_base_with_payload_di

> IM 消息表。用于 P2C「开口说话人数」。

## 开口说话口径

```sql
SELECT substr(send_time, 1, 10) AS send_date,
       COUNT(DISTINCT from_ucid) AS uv
FROM olap.olap_im_base_with_payload_di t1
WHERE t1.pt = '${-1d_pt}'
  AND from_ucid LIKE '200%'              -- C 端用户
  AND to_ucid = 'osa_jiaoyizhuanjia'     -- 发给交易专家
  AND msg_type NOT IN (101, 800, 801, 808, 809)  -- 排除系统消息
GROUP BY substr(send_time, 1, 10)
```

## 与 chat_detail 的区别

| 表 | 用途 |
|----|------|
| im_base_with_payload_di | 开口人数（轻量、IM 层） |
| p2c_chat_detail_di | 消息明细、来源分类、卡片分析（重） |

## 已知坑

- `from_ucid LIKE '200%'` 过滤 C 端，不含 B 端/系统号
- msg_type 排除列表勿随意删减，否则系统消息计入开口
