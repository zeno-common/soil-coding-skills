# SKILL.md 模板

入口文件模板，位于 `./skills/<module-name>-doc/SKILL.md`。

```markdown
---
name: "<module-name>-doc"
description: "Use when coding with <module> SDK, need API reference for <module summary>."
version: "<sdk-version>"
---

# <module-name> SDK 参考

<模块一句话概述>

## BOM 引入示例
<当前SDK 的 bom 的引入示例>

## 类索引

| 类 | 包 | 说明 | 文档 |
|----|-----|------|------|
| `ClassName` | `<package-name>` | 一句话描述 | [ClassName](references/<package-name>/ClassName.md) |
```