# 条目模板 — 能力 B：生成 README.md

> 本文件仅覆盖**能力 B（生成标准 Java 工程 README.md）**的模板。
> - 能力 A（AI KB Skill）模板见 `../kb/template.md`
> - 产出规范见同目录 `./produce.md`
>
> README 为常规工程说明，**不**承载外部调用细节。构建与依赖说明仅给 Maven（不提供 Gradle）。

---

## 模板 0：README.md（能力 B —— 标准 Java 工程 README）

```markdown
# <Project Name>

<项目一句话描述，取自根 pom 的 name/description 或工程说明>

## 项目简介

<从根 pom description / 工程说明提取的概述，2-4 句>

## 模块说明

| 模块 | 说明 |
|------|------|
| `<submodule-A>` | <子模块简述> |
| `<submodule-B>` | <子模块简述> |

## 环境要求

- JDK：<java.version，取自根 pom 的 maven.compiler / java.version>
- 构建工具：Maven
- <其他：如数据库、中间件版本>

## 构建与运行

```bash
# Maven
mvn clean install
mvn spring-boot:run
```

## 快速开始

<可选：最小上手步骤，如初始化配置、启动顺序>

## 许可证

<可选：许可证名称>
```
