# rpt.rpt_comm_agent_allinfo_employee_da

> 员工全面信息明细表。公司全量员工日快照，含职务、组织层级、上级、城市等。**替代**旧员工宽表 `dw.dw_allinfo_hr_employee_da`、`rpt.rpt_allinfo_hr_employee_da`（均已标待下线/请勿申请）。

## 来自内部表检索

<!-- as of 2026-08-14, source: http://factory.data.ke.com/tableSearch -->

| 元信息 | 值 |
|--------|----|
| 表中文名 | 员工全面信息明细表 |
| 表类型 | Hive |
| 数据层级 | 应用分析数据 |
| 数据库 | rpt |
| 集群 | 公共集群 |
| 安全等级 | C2 |
| 是否分区 | 是 |
| 分区字段 | `pt`（格式 `YYYYMMDD000000`） |
| 权限包 | 通用 |
| 标签 | 核心表、高价值、行级权限、任务/天 |
| 字段数 | 123 |
| 生命周期 | 365 天 |

**描述摘要**：公共模型；业务过程为公司所有员工明细；**表粒度 `employee_ucid`**（一人一行/天）。

## 权限

标签含**行级权限**；受控字段 **`city_code`**。查不到某城市员工时，先核对城市权限，再怀疑工号/组织编码。

## 用途

- 员工维表：`employee_ucid` ↔ 业务表 `ucid`，补职务/组织属性
- 内容生产人：`rpt_feed_content_analyze_table.im_ucid` = `employee_ucid`（**禁止** `admin_ucid`）
- 区分内外部用户：P2C DAU 等 LEFT JOIN 后判断 employee / customer
- 按组织层级圈定分析人群；探查职务/组织枚举

**不要**：不带 `pt` 扫全表；把该表当流水表；用工号去 JOIN 流量侧 `ucid`（应走 `employee_ucid`）。

## 必带过滤

```sql
WHERE pt = '${-1d_pt}'
  AND employee_ucid IS NOT NULL
  AND employee_ucid NOT IN ('-911', 'null')
```

### 常用业务过滤

| 场景 | 条件 |
|------|------|
| 在职在岗 | `on_job_status_code = 170007002` |
| 离职 | `on_job_status_code = 170007001` |
| 在职不在岗 | `on_job_status_code = 170007003` |
| 内部员工 | `employee_category_code = 170001001` |
| 加盟员工 | `employee_category_code = 170001002` |
| 分销商员工（新房） | `employee_category_code = 170001003` |

## 核心字段

### 主键 / 身份

| 字段 | 类型 | 含义 | 备注 |
|------|------|------|------|
| employee_ucid | bigint | 员工 ucid | **JOIN 键**；表粒度 |
| employee_no | bigint | 员工工号 | 系统号；不要用来 JOIN 流量 ucid |
| employee_name | string | 员工姓名 | |
| on_job_status_code | bigint | 在职状态编码 | 见上表 |
| employee_category_code | bigint | 员工类别编码 | 170001001/002/003 |

### 职务 / 职级

| 字段 | 含义 |
|------|------|
| job_code / job_name | 职务（如买卖经纪人） |
| job_category_id / job_category_name | 职务类别 |
| hr_job_seq_code / hr_job_seq_name | 职务序列（助理/运营/职能） |
| position_code / position_name | 职位 |
| job_level_name | 职级 |

### 组织层级（自上而下）

| 字段 | 含义 |
|------|------|
| corp_code / corp_name | 公司 |
| region_code / region_name | 运营管理大区/中心 |
| marketing_code / marketing_name | 营销大区/部门 |
| area_code / area_name | 业务区域/组 |
| shop_code / shop_name | 门店 |
| team_code / team_name | 店组 |
| org_code / org_name | 当前所在组织（粒度不固定） |
| city_code / city_name | 城市 |

**大部切片**：`marketing_name` 与 `region_name` 哪一层叫「大部」**待业务确认**，未确认前不要写死。

### 敏感 / 废弃

`mobile1` / `email` / `birth_date` / `cert_no` 为加密字段，勿 SELECT 明文。`mobile1_md5`、`post_status_*`、`master_*` 已废弃。

## JOIN 路径

```
业务表.ucid = employee_ucid          -- 通用员工维
内容生产.im_ucid = employee_ucid     -- 内容投稿人（Locked；禁止 admin_ucid）
```

```sql
-- 内容生产 → 员工（Locked）；JOIN 前剔 im_ucid 异常值
t1.im_ucid = t2.employee_ucid

and t1.im_ucid is not null
and t1.im_ucid not in ('-911','null')
```

```sql
-- 区分员工 vs 客户（P2C DAU 等）
LEFT JOIN (
    SELECT employee_ucid AS ucid
    FROM rpt.rpt_comm_agent_allinfo_employee_da
    WHERE pt = '${-1d_pt}'
) t2
  ON t1.ucid = t2.ucid
```

生产人校验见 [feed_content_analyze_table.md](feed_content_analyze_table.md)。

## 枚举探查

职务/组织字段枚举：`UNION ALL` 按维度聚合 `count(distinct employee_ucid)`。门店/店组/组织编码基数大，建议加 `city_name` 收窄。

参考 SQL：`员工全面信息明细表/employee_job_org_enum.sql`

## 替代关系

| 旧表 | 状态 |
|------|------|
| `dw.dw_allinfo_hr_employee_da` | 待下线，请申请本表 |
| `rpt.rpt_allinfo_hr_employee_da` | 请勿申请，请申请本表 |
| `rpt.rpt_ehr_info_da` | 员工核心信息（无敏感数据），字段更少 |

衍生表（按城市/场景复制，非默认首选）：`rpt_comm_agent_allinfo_employee_da_jj`（经纪人）、`_bj`、`_gzdc` 等。

## 已知坑

- **行级权限**按 `city_code` 裁剪，全公司枚举探查结果不完整
- 未滤 `on_job_status_code` 时**离职员工也在**
- `org_code` 与 `shop_code`/`team_code` 不是同一层级；圈门店用 `shop_code`
- 内容生产关联只用 `im_ucid`（北京 2026-08-14：有值关联成功率 99.23%；`admin_ucid` 0%）
