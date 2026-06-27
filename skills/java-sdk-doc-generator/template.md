# Markdown 输出模板

> 每个 Java 类一个 `.md` 文件，以下为结构骨架。标注 `(omit)` 的字段/段落，在无对应内容时整行/整段省略。

---

```markdown
# `ClassName`

`package com.example.package`

extends `ParentClass` implements `Interface1, Interface2` (omit)

`@Service` `@Slf4j` (omit)

`@Deprecated` since v2.0.0, forRemoval=true, use `NewClass` (omit)

Description text. *(No description provided)*

---

## Methods

### `ReturnType methodName(ParamType1 param1, ParamType2 param2)`

`@GetMapping("/path")` `@PreAuthorize("hasRole('admin')")` (omit)

→ **ReturnType** — Description

throws `IllegalArgumentException` — when param is null (omit)

`@Deprecated` since v2.0.0, use `newMethod` (omit)

Description text. *(No description provided)*

| Param | Type | Description |
|-------|------|-------------|
| `param1` | `ParamType1` | Description |
| `param2` | `ParamType2` | Description |

---

## Constants (omit)

| Name | Type | Value | Description |
|------|------|-------|-------------|
| `MAX_SIZE` | `int` | `1024` | Maximum buffer size |

---

## Enum Values (omit)

| Name | Description |
|------|-------------|
| `SUCCESS` | Operation completed successfully |
```