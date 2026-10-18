# 目录结构
```
./skills/<module-name>-doc/
└── references/
    └── <package-name>/
        └── <ClassName>.md               # 每个类一个文件（见 class-template.md）
```


# 类文档模板

每个类一个文件，位于 `references/<package-name>/<ClassName>.md`。

```markdown
# ClassName

> One-line condensed description

- **包**: `<package-name>`
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

## 相关格式规则

1. **每个类独立文件** — 位于 `references/<package-name>/<ClassName>.md`
2. **包名单级目录** — 包名原样作为目录名（如 `<package-name>/`），不拆分为多级
3. **类文档标题层级** — 类用 `#`，方法用 `##`，构造/字段/枚举用 `##`
4. **类型引用** — 同包内用锚点 `#ClassName`，跨包用相对路径 `../<package-name>/ClassName.md`
5. **方法排序** — 常用方法在前，辅助方法在后
6. **示例必须可运行** — 含完整对象创建和调用链
7. **构造/字段/枚举用表格**
8. **空描述标为** `*(无描述)*`
9. **Builder 独占一节**
10. **文件编码 UTF-8 无 BOM** — 所有输出文件必须使用 UTF-8 编码，不带 BOM 头

## 常见错误

| 错误 | 正确做法 |
|------|---------|
| 逐个列出 @Data 的 getter/setter | 一行概括"所有字段均有 getter/setter" |
| Javadoc 原文照搬不浓缩 | 深度浓缩为精炼表达 |
| 增量更新时全量重写 | 仅覆盖变更类的 .md 文件 |
