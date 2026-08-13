# 交易专家（P2C）产品知识

> 扩展模块。SQL 来源：`04 交易P2C/01 数据分析/`。

## 产品定位

贝壳 App 内「交易专家」AI 助手，帮助用户解决二手房买卖中的资质、贷款、税费、成本规划等问题。

## 核心页面（uicode）

| uicode | 页面 |
|--------|------|
| `osa_jiaoyizhuanjia` | 会话页 |
| `transaction_expert_person` | 个人主页 |
| `transaction_expert_articlelist` | 内容列表页 |
| `transaction_expert_articledetail` | 内容详情页 |
| `transactionexpert_moments` | 动态主页（需 `client_app_version >= '3.05.30'`） |
| `osa_homepage` + tab | 动态主页 Tab 切换（evt 91922） |

## 四大工具

| tool_value | 工具 | ODS 表 |
|------------|------|--------|
| 1 | 购房能力评估 | `ods_plat_trade_cost_assess_calc_record_da` |
| 2 | 房贷方案 | `ods_plat_trade_cost_home_loan_da` |
| 3 | 税费计算 | `ods_plat_trade_cost_tax_calc_record_da` |
| 4 | 购房成本规划 | `ods_plat_trade_cost_home_cost_da` |

ODS 用户 ID 字段名不统一：`calc_user_id` / `user_id` / `cal_user_id`，UNION 时统一 alias 为 `ucid`。

## 卡片类型

| 类型 | ODS 判定 | 会话 card_status |
|------|----------|------------------|
| 信息卡 | `result_info IS NULL` 或 `''` | 0, 1 |
| 结果卡 | `result_info IS NOT NULL` | 2, 3, 4 |

## 版本分界

| 版本 | 影响 |
|------|------|
| `3.05.30` | 动态主页 moments 逻辑、msg_src_type 分类 |
| `3.05.71` | 房源详情页 AB 实验 |

## 用户身份

- C 端用户：`from_ucid LIKE '200%'`
- 专家账号：`osa_jiaoyizhuanjia`
- 会话 robot_name：`交易专家`

## 深度使用用户（复合口径）

近 N 天内满足**任一**：
1. 四工具 ODS 任一有 `result_info IS NOT NULL`
2. 内容列表页 `evt_id='1,3'`
3. 会话明细：用户手动输入文本（`from_role='用户'`, `msg_src_type='手动输入'`）

## 自建底表

| 表 | 指标 |
|----|------|
| `rpt_p2c_dau_result_di` | 各页面 DAU |
| `rpt_p2c_rukou_rusult_di` | 入口曝光/点击/PCTR/UCTR |
| `rpt_p2c_huihua_rusult_di` | 会话页 DAU、开口、工具完整使用 |
| `rpt_p2c_chat_detail_di` | 消息明细 |

> 底表名 `rusult` 为历史拼写，与现网保持一致。
