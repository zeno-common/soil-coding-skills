# 产出阶段 — 能力 A：生成 AI KB Skill

> 本文件仅覆盖**能力 A（生成 AI KB Skill，默认）**。
> - 能力 B（生成 README.md）见 `../readme/produce.md`
> - 分析阶段（两能力共用）见根目录 `../analyze.md`
> - 本能力模板见 `./template.md`

## 1. 能力模式与输出模型

| 模式 | 触发 | 默认 | 输出范围 |
|------|------|------|----------|
| **A. 生成 AI KB Skill** | 用户要求知识库 / AI KB 技能 | ✅ 默认 | `SKILL.md` + `introduce.md` + 各子模块知识模块（`config.md` + `sdk/` + `rest/`） |

> 能力 A **不包含 README.md**；README 由能力 B 单独生成。

## 2. 目录结构

### 模式 A（生成 AI KB Skill）—— 输出为一个技能目录

```
skills/<project-name>/
├── SKILL.md                      # 技能入口：告诉 AI Agent 如何使用本知识库
├── introduce.md                  # 统一说明：各子模块简述 + 依赖坐标（去重）
├── <submodule-A>/                # 独立知识模块目录
│   ├── config.md                 # 模块使用配置
│   ├── sdk/<package-name>/<Class>.md    # SDK 类调用知识
│   └── rest/<package-name>/<Class>.md   # REST 类调用知识（仅 Server）
├── <submodule-B>/
│   └── ...
```

`<submodule>` = 子模块目录名；`<package-name>` 原样保留（含 `.`）作单级目录名，不按 `/` 拆多级。
- 模块 `config.md` 引用依赖：`[introduce.md](../../introduce.md#<submodule>)`（上溯一级）

## 3. introduce.md 规范（模式 A）

统一说明文件，每个子模块一段，依赖去重。**依赖仅给 Maven 坐标**（不提供 Gradle，不渲染 XML 片段）。

- 结构：每个子模块一段（`## <submodule>` + 一句话说明 + `### 依赖坐标` 坐标行）
- 锚点规则：以子模块名 `<submodule>` 作 `##` 标题锚点，供 config.md 与类文档 `#` 引用
- 完整 Markdown 模板见 [template.md 模板 2](template.md)

## 4. SKILL.md 规范（模式 A，生成的技能入口）

告诉加载本技能的 AI Agent 如何使用其中的知识：

- 必须含 `name` / `description`（由工程名推断，便于检索）与三段式使用流程：① 从 `introduce.md` 取 Maven 坐标生成 pom 依赖 → ② 读子模块 `config.md` 了解模块使用配置 → ③ 进入 `sdk/` 或 `rest/` 类文档按「类调用」生成调用（配置前置已在 `config.md` 完成）
- 完整 Markdown 模板（含「路径目录名 → introduce.md 锚点」规则）见 [template.md 模板 1](template.md)

## 5. config.md 规范（子模块使用配置，模式 A）

配置集中于此，类文档不重复配置（仅「类调用」）。结构：

- `## 启用与配置`：启用方式、`application.yml` 关键配置（enabled/endpoint 等）、自动配置类/所需 Bean；SDK 客户端 `@Bean` 初始化、REST 端点级非约定项（如 `@PreAuthorize`、速率限制）在此补充；base path 前缀、`Bearer` 鉴权、CORS 见系统 API 调用约定，不在此列
- `## 前置依赖`：模块级前置条件（数据库、消息中间件、外部服务地址）
- 完整 Markdown 模板见 [template.md 模板 3](template.md)

## 6. 类调用知识 .md 生成规则

| 项 | 规则 |
|----|------|
| 内容 | 仅「类调用」一段，不内嵌坐标、不逐类重复依赖与配置（配置前置统一在 config.md 完成） |
| 增量 | 先查文件是否存在，仅覆盖变更文件 |
| 删除 | 源类删除时删除对应 `.md` |

SDK / REST 两类文档结构见 [template.md](template.md) **模板 4 / 模板 5**。

## 7. 关键规则（能力 A）

1. **为工程生成技能，非工程即技能** —— 输出物是一个 AI KB Skill；整个 Java 工程是其知识来源
2. **AI KB Skill 不含 README.md** —— 仅 `SKILL.md`+`introduce.md`+子模块(`config.md`+类调用知识)
3. **子模块即知识模块** —— 每个子模块独立目录，含模块使用配置与类调用知识
4. **依赖只生成一次** —— 收敛到 `introduce.md` 按子模块去重，绝不逐类重复；依赖仅给 Maven 坐标
5. **类调用知识极简** —— 只「类调用」一段；配置是类调用前置，统一在 `config.md` 完成，不在类文档重复（依赖统一见 introduce.md）
6. **显式解析注解 @ai-doc-sdk / @ai-doc-rest 准入** —— 仅被该解析注解标记的类才生成知识；不做任何无标记自动识别兜底；Lombok 注解参与已标记类的成员还原
7. **依赖可追溯** —— 依赖坐标取自子模块 `pom.xml`；第三方依赖由 Maven 传递解析
8. **示例可复制** —— 「类调用」代码必须能直接用于生成外部调用
9. **不引用内部内容** —— 不得链接/提及本项目其他内部模块
10. **不生成调用外部服务的客户端知识** —— `@ai-doc-rest` 仅覆盖对外暴露的服务端接口

## 完成汇总

| 指标 | 数量 |
|------|------|
| 能力模式 | A |
| 处理子模块 | N |
| 生成 SKILL.md | 0/1 |
| 生成 introduce.md 子模块段 | N |
| 生成 config.md | N |
| SDK 类调用知识 | N |
| REST 类调用知识（仅 Server） | N |
| 新建文件 | N |
| 更新文件 | N |
| 删除文件 | N |
