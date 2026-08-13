# 团队项目 Skills

打开本仓库后，Cursor 会自动加载 `.cursor/skills/`。同事**不用拷到** `~/.cursor/skills/`。

推荐闭环：`new-analysis` → `get-data` + `analysis-method` → `analysis-report` → `close-project`。

| Skill | 作用 |
|-------|------|
| `new-analysis` | 新建分析项目（status.md + SQL） |
| `analysis-method` | 归因 / 漏斗 / 维度拆解 / 实验防坑 |
| `get-data` | Hive 取数规范 + 表/指标/埋点/模板字典 |
| `create-hive-table` | 结果底表 DDL / INSERT |
| `hive-table-permission` | 数据工厂查权限、走前端申请 |
| `analysis-report` | 分析报告写作规范 |
| `close-project` | 收尾，把可复用知识沉回本目录 |

## 同事怎么用

1. Clone 本仓库，用 Cursor 打开仓库根目录（不要只打开某个子文件夹）。
2. 新开 Agent 对话；需要时用 `/get-data` 等显式调用。
3. 之后日常 `git pull`，skill 会跟着更新。

首次用 `get-data` / 申请权限：在 Cursor 内置浏览器完成公司 SSO，不要把账号密码发给 Agent。权限申请者必须是当前登录用户。

## 你更新之后

改 `.cursor/skills/` → commit → push。同事 pull 后即可用到新版本。沉淀字典时写这里，不要写到个人目录 `~/.cursor/skills/`。

未包含个人健康 / 运动相关 skills。
