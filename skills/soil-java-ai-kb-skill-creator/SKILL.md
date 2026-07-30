---
name: "soil-java-ai-kb-skill-creator"
description: "Java AI 知识库技能创建工具：分析整个 Java 工程的 *.java 文件，基于显式解析注解 @ai-doc-sdk / @ai-doc-rest（必带，无标记即跳过，不做自动识别兜底）与 Lombok 注解解析，生成面向外部调用（JAR SDK 与 Spring REST）的知识。提供两项可独立使用的能力：(A) 为整个 Java 工程生成一个 AI KB Skill（默认）；(B) 生成标准的 Java 工程 README.md。MANDATORY: 按顺序执行步骤。"
---

# Java AI 知识库技能创建工具

本 skill **为整个 Java 工程生成一个 AI KB Skill**（输出物是一个 AI 知识库技能；
整个 Java 工程是其知识来源）。工程根目录的每个子模块成为该技能内的一个**独立知识模块**。

只沉淀 **外部调用** 所需内容：消费外部 JAR SDK、调用外部 Spring REST。
不生成完整 API 参考，不沉淀内部业务逻辑，不引用本项目其他内部内容。

## 两项核心能力（可分开使用）

| 能力 | 产出 | 触发 | 默认 |
|------|------|------|------|
| **A. 生成 AI KB Skill** | 完整知识库技能：`SKILL.md` + `introduce.md` + 各子模块知识模块（模块使用配置 + 类调用知识） | 用户要求「生成 AI KB 技能 / 知识库」 | ✅ 默认执行 |
| **B. 生成 README.md** | 标准的 Java 工程 README.md（项目简介 / 模块说明 / 环境 / 构建运行） | 用户要求「生成 README」 | |

## 知识库条目模型（能力 A）

| 条目 | 级别 | 文件 | 内容 |
|------|------|------|------|
| **技能入口** | Skill 级 | `SKILL.md` | 告诉 AI Agent 如何使用本知识库 |
| **模块说明 + 依赖** | 子模块级（去重） | `introduce.md` | 各子模块简述 + 依赖坐标（每子模块一次） |
| **模块使用配置** | 子模块级 | `<submodule>/config.md` | 模块启用方式、yml 关键配置、逐类接线（SDK 客户端 Bean / REST 端点级非约定项）、前置依赖 |
| **SDK 类调用知识** | 类级 | `<submodule>/sdk/<pkg>/<Class>.md` | 类调用（配置前置在 config.md 完成，依赖见 introduce.md，由子模块目录名定位） |
| **REST 类调用知识** | 类级 | `<submodule>/rest/<pkg>/<Class>.md` | 类调用（配置前置在 config.md 完成，依赖见 introduce.md，由子模块目录名定位） |

> 能力 A **不包含 README.md**；README 由能力 B 单独生成。

## 执行流程（MUST 按顺序）

1. 读 `analyze.md`（根目录，两能力共用）→ 范围/变更、**子模块识别**、`@ai-doc-sdk`/`@ai-doc-rest` 解析注解（必带，无标记跳过，不兜底）、Lombok 注解解析、分类提取、过滤
2. 按用户意图选定能力，读取对应产出规范与模板：
   - **能力 A（默认）**：读 `kb/produce.md` → 输出模型/目录/规范；读 `kb/template.md` → 模板
   - **能力 B**：读 `readme/produce.md` → 规范；读 `readme/template.md` → 模板
3. 若能力 A（默认）：生成 `SKILL.md` + `introduce.md` + 各子模块目录（`config.md` + `sdk/` + `rest/` 类调用知识）
4. 若能力 B：生成标准 Java 工程 `README.md`
5. 输出完成汇总（按所选能力的汇总表）

调用时机：用户要求生成知识库 / AI KB 技能 / Java 工程 README / 外部调用文档，
或提及「生成 Java AI 知识库」「生成 依赖引入/配置/类调用 文档」。
