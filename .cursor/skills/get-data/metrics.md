# 指标定义索引

> **硬规则**：metrics/ 中已有定义的指标，写 SQL 时必须 verbatim 使用，不可替换公式。

| 类别 | 包含 | 文件 |
|------|------|------|
| **活跃** | DAU、MAU、停留、Feed 曝光 | [metrics/active.md](metrics/active.md) |
| **漏斗** | 曝光/点击、PCTR、UCTR、渗透率、点后推二导新户型卡 | [metrics/funnel.md](metrics/funnel.md) |
| **留存** | 7日留存、1–7日复访；建表用成熟日 / 普通查询自关联 | [metrics/retention.md](metrics/retention.md) |
| **内容生态** | 分发/消费/互动 UV·PV、UCTR/PCTR、消费次数、三场景整体/分场景周报日均（**duid 去重**） | [metrics/content-ecology.md](metrics/content-ecology.md) |
| **核访** | 新房核访、二手核访（PV / 去重盘或房 / ≠带看） | [metrics/hefang.md](metrics/hefang.md) |
| **商机/成交** | 页面商机(adid)、溯源商机(uicode/ele)、三次握手(可选)、转委托/带看、新二带看、新二成交 | [metrics/commerce.md](metrics/commerce.md) |
| **P2C** | 交易专家 DAU、开口、工具完整使用、卡片 | [metrics/p2c.md](metrics/p2c.md) |
