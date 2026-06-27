# 输出模板

## 目录结构

```
.trae/skills/<module-name>-sdk/
├── SKILL.md                              # 入口文件
└── references/
    ├── output-template.md                # 本文件（输出模板和格式规则）
    └── <package-name>/                   # 包名原样作为单级目录名
        └── <ClassName>.md               # 每个类一个文件
```

## SKILL.md 模板

```markdown
---
name: "<module>-sdk"
description: "Use when coding with <module> SDK, need API reference for <module summary>."
---

# <模块名> SDK 参考

<模块一句话概述>

## 依赖引入

java maven 工程的依赖引入参考：'[jsf-bom/README.md](../../jsf-bom/README.md)'

| ArtifactId | 说明 |
|-----------|------|
| `<artifactId>` | <一句话描述> |

## 类索引

| 类 | 包 | 说明 | 文档 |
|----|-----|------|------|
| `ClassName` | io.soil.waf | 一句话描述 | [ClassName](references/io.soil.waf/ClassName.md) |
```

## 类文档模板（references/<package-name>/<ClassName>.md）

```markdown
# ClassName

> One-line condensed description

- **包**: io.soil.waf
- **父类**: ParentClass (omit if Object)
- **实现**: InterfaceA, Serializable (omit if none)

## 构造 (omit if only default)

| 签名 | 说明 |
|------|------|
| `ClassName()` | 无参构造 |

## 方法

### methodName

`ResultType methodName(ParamType1 param1, ParamType2 param2)`

> Condensed description

**参数**:
- `param1` (ParamType1) — 参数说明

**返回**: ResultType — 返回值说明 (omit if void)

**异常**: (omit if none)
- `SomeException` — 异常说明

**示例**:
```java
ClassName obj = new ClassName();
ResultType result = obj.methodName(param1, param2);
```

## 字段 (omit if none)

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | String | 名称 |

## Builder 模式 [Lombok 生成] (omit if no @Builder)

```java
ClassName obj = ClassName.builder()
    .name("示例值")
    .build();
```

## 枚举值 (omit if not enum)

| 值 | 说明 |
|----|------|
| `VALUE_A` | 值A说明 |
```

## 格式规则

1. **SKILL.md 为入口** — 包含 frontmatter + 模块概述 + 依赖引入 + 类索引表（含文档链接）
2. **每个类独立文件** — 位于 `references/<package-name>/<ClassName>.md`
3. **包名单级目录** — 包名原样作为目录名（如 `io.soil.waf.config/`），不拆分为多级
4. **类文档标题层级** — 类用 `#`，方法用 `##`，构造/字段/枚举用 `##`
5. **类型引用** — 同包内用锚点 `#ClassName`，跨包用相对路径 `../<package-name>/ClassName.md`
6. **方法排序** — 常用方法在前，辅助方法在后
7. **示例必须可运行** — 含完整对象创建和调用链
8. **构造/字段/枚举用表格**
9. **空描述标为** `*(无描述)*`
10. **Builder 独占一节**