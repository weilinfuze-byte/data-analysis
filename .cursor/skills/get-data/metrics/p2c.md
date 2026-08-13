# P2C 交易专家指标

> 详见 [business/p2c-transaction-expert.md](../business/p2c-transaction-expert.md)

### 交易专家 DAU

- 公式：`COUNT(DISTINCT ucid) WHERE evt_id = '1,3'`
- 页面 uicode 含：
  - `osa_jiaoyizhuanjia`, `transaction_expert_person`, `transaction_expert_articlelist`, `transaction_expert_articledetail`
  - 动态主页 union 段（moments / homepage tab / 专属管家入口）
- 底表：`rpt.rpt_p2c_dau_result_di`
- 模板：[templates/p2c_dau_etl.md](../templates/p2c_dau_etl.md)

### 会话页 DAU（active_uv）

- 公式：`uicode='osa_jiaoyizhuanjia' AND evt_id='1,3'` 去重 ucid
- 底表：`rpt.rpt_p2c_huihua_rusult_di`

### 开口人数（kaikou_uv）

- 表：`olap.olap_im_base_with_payload_di`
- 公式：`COUNT(DISTINCT from_ucid)` 
- 条件：`from_ucid LIKE '200%'`, `to_ucid='osa_jiaoyizhuanjia'`, `msg_type NOT IN (101,800,801,808,809)`

### 工具完整使用（gongju_uv）

- 方式一：结果卡曝光 `evt_id IN (92247, 92259, 92272, 92290)` 去重 ucid
- 方式二：四工具 ODS `result_info IS NOT NULL` 去重 ucid

### 入口 PCTR / UCTR

| 入口 | 曝光 evt_id | 点击 evt_id |
|------|-------------|-------------|
| 底部轮播（专属管家） | 91912 | 91914 |
| 底部轮播（交易页） | 92395 | 92396 |
| 消息列表 | 91989 | 91990 |
| 动态主页切换 | 91921 | 91922 |

- pctr = click_pv / expo_pv；uctr = click_uv / expo_uv
- 底表：`rpt.rpt_p2c_rukou_rusult_di`
- 模板：[templates/p2c_entry_funnel.md](../templates/p2c_entry_funnel.md)

### 信息卡 / 结果卡

- ODS：`result_info IS NULL/''` → 信息卡；NOT NULL → 结果卡
- 会话：`card_status IN (0,1)` → 信息卡；`IN (2,3,4)` → 结果卡

### 深度使用用户占比

近 N 天 UNION 去重 ucid，满足任一：
1. 工具 ODS 有 result_info
2. 内容列表页 evt_id='1,3'
3. 用户手动输入文本（chat_detail）
