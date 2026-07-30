# 条目模板 — 能力 A：生成 AI KB Skill

> 本文件仅覆盖**能力 A（生成 AI KB Skill，默认）**的模板。
> - 能力 B（README.md）模板见 `../readme/template.md`
> - 产出规范见同目录 `./produce.md`
>
> 生成规则与关键约束（依赖集中 `introduce.md`、配置集中 `config.md`、类文档仅「类调用」、Maven-only、`@ai-doc` 准入）见同目录 `produce.md` §6/§7；本文件仅提供模板。
> 标注 `(omit)` 的字段/段落，无对应内容时整段省略。

---

## 模板 1：生成的 SKILL.md（能力 A 技能入口）


```markdown
---
name: "<project>"
description: "<Project> 外部调用知识库：JAR SDK 与 Spring REST 的 依赖坐标 / 模块使用配置 / 类调用。AI Agent 在需要调用本项目对外能力时加载。"
---

# <Project> 知识库

本技能包含本项目对外能力的调用知识。使用方式：

1. 从 [introduce.md](introduce.md) 取所需子模块的 Maven 坐标，生成 `pom.xml` 的 `<dependency>`
2. 引入模块或更新模块配置时，读 `config.md` 了解模块使用配置
3. 进入 `sdk/` 或 `rest/` 下类文档，按「类调用」生成调用代码（配置前置已在 `config.md` 完成）

> 依赖引入统一见 [introduce.md#<子模块名>](introduce.md)，`<子模块名>` 即调用文档所在目录名（如 `<submodule>/sdk/...` → `introduce.md#<submodule>`）。
> 各子模块的模块使用配置见 `config.md`；完整约定见项目 API 调用规范。
```

---

## 模板 2：introduce.md（统一说明 + 依赖坐标）

> 各子模块的简要说明与依赖坐标（每子模块一次，去重）。坐标按 Maven `groupId:artifactId:version` 生成 `pom.xml` 的 `<dependency>`。

```markdown
# 知识库总览与依赖坐标


## <submodule-A>

<子模块一句话说明>

### 依赖坐标（Maven）
`com.example:submodule-a:1.0.0`

---

## <submodule-B>

<子模块一句话说明>

### 依赖坐标（Maven）
`com.example:submodule-b:2.0.0`
```
```

---

## 模板 3：config.md（子模块使用配置，能力 A）

```markdown
# <submodule> 模块使用配置

> 依赖引入：见 [introduce.md](../introduce.md#<submodule>)

## 启用与配置

- 启用方式：<如 @EnableXxx / 自动装配条件 / 无额外启用步骤>
- `application.yml` 关键配置：
```yaml
<submodule>:
  enabled: true
  endpoint: https://...
```
- 自动配置类 / 所需 Bean：<...>

## 前置依赖

<模块级前置条件，如数据库、消息中间件、外部服务地址>
```

---

## 模板 4：SDK 类调用知识 `<submodule>/sdk/<pkg>/<Class>.md`

```markdown
# `ClassName` (JAR SDK)

`package com.example.sdk`

<类 Javadoc 第一句描述用途>

---

## 类调用

### `ReturnType entryMethod(ParamType1 p1, ParamType2 p2)`

→ **ReturnType** — <描述>

| Param | Type | Description |
|-------|------|-------------|
| `p1` | `ParamType1` | <描述> |
| `p2` | `ParamType2` | <描述> |

调用示例：
```java
ClassName client = new ClassName()
    .setEndpoint("https://api.example.com")
    .setTimeout(3000);
ReturnType result = client.entryMethod(p1, p2);
```

<!-- 若参数/返回为 POJO，按下展开字段；POJO 上的 Lombok 用于解析字段，非文档识别标识 -->

### 请求 / 返回 POJO 结构

**`ParamType1`（请求参数）** — 字段取其 Lombok 还原后的可读成员：

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | `String` | <来自字段 Javadoc> |
| `timeout` | `int` | 超时秒数 |

构造示例（Lombok `@Data` + `@Builder`）：
```java
ParamType1 p1 = ParamType1.builder().name("x").timeout(3).build();
```

**`ReturnType`（返回信息）**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | `int` | 结果码 |
| `data` | `DataDTO` | 业务数据（嵌套 POJO 递归展开） |
```

---

## 模板 5：REST 类调用知识 `<submodule>/rest/<pkg>/<Class>.md`

> `Type` 标注 `Server`（对外暴露的 REST 接口）。本 skill **不生成调用外部服务的客户端知识**。

```markdown
# `ClassName` (Spring REST — Server)

`package com.example.api`

<类 Javadoc 第一句描述用途>

---

## 类调用（HTTP 调用示例）

### `POST /api/v1/orders/{id}/ship`

| 类型 | 名称 | 说明 |
|------|------|------|
| Path | `id` | 订单 ID |
| Body | `ShipRequest` | `{ "carrier": "SF", "trackNo": "..." }` |
| 响应 | `ShipResponse` | `{ "shipId": "...", "status": "SHIPPED" }` |
| Header | `Authorization` | `Bearer <token>` |

`curl` 示例：
```bash
curl -X POST 'https://host/api/v1/orders/123/ship' \
  -H 'Authorization: Bearer <token>' \
  -H 'Content-Type: application/json' \
  -d '{"carrier":"SF","trackNo":"123456"}'
```

<!-- 请求体/响应为 POJO 时，按下展开字段；POJO 上的 Lombok 用于解析字段，非文档识别标识 -->

#### `ShipRequest`（请求体）字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `carrier` | `String` | 承运商编码 |
| `trackNo` | `String` | 运单号 |

> 字段取自 `ShipRequest` 的 Lombok 还原成员（`@Data`/`@Getter` 等），不单独为 POJO 生成文档条目。

#### `ShipResponse`（响应）字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `shipId` | `String` | 发货单 ID |
| `status` | `String` | 发货状态 |
```
