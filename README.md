# Soil Coding Skills

AI Coding 规范 Skill 工程。支持通过 `npx skills` CLI 安装，也可通过 git submodule 引入到项目的 `.trae/skills/` 目录，为 AI 编程助手提供开发规范上下文。

## 安装方式

### 方式一：npx skills CLI（推荐）

```bash
# 查看可用技能
npx skills add zeno-common/soil-coding-skills --list

# 安装指定技能
npx skills add zeno-common/soil-coding-skills --skill cola5-architecture -y
npx skills add zeno-common/soil-coding-skills --skill java-coding-guidelines -y
npx skills add zeno-common/soil-coding-skills --skill java-sdk-doc-generator -y
npx skills add zeno-common/soil-coding-skills --skill java-sdk-doc-skill-creator -y
npx skills add zeno-common/soil-coding-skills --skill mysql-conventions -y
npx skills add zeno-common/soil-coding-skills --skill restful-convention -y

# 安装全部
npx skills add zeno-common/soil-coding-skills --all
```

### 方式二：git submodule

```bash
git submodule add https://github.com/zeno-common/soil-coding-skills.git .trae/skills/soil-coding-skills
git submodule update --init --recursive
```

## Skill 清单

| Skill | 说明 | 触发场景 |
|-------|------|---------|
| `cola5-architecture` | COLA 5 整洁架构目录与分层规范 | 创建 Java 项目结构、添加类、确定类所属层、审查架构合规 |
| `java-coding-guidelines` | 阿里巴巴 Java 开发手册规约 | 编写/审查 Java 代码、PR Review、代码风格修复 |
| `java-sdk-doc-generator` | SDK 文档生成器 | 生成/更新 Java SDK Markdown 文档 |
| `java-sdk-doc-skill-creator` | SDK 文档 Skill 生成器 | 从 Java 源码生成可加载的 SDK 文档 skill |
| `mysql-conventions` | MySQL 数据库设计、SQL 编写、ORM 规范 | 设计表结构、编写 SQL、使用 MyBatis/JPA |
| `restful-convention` | RESTful API 设计规范 | 设计 REST API、编写 Controller、定义端点 |

## 目录结构

```
soil-coding-skills/
├── skills/
│   ├── cola5-architecture/              # COLA 5 架构规范
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── project-structure.md
│   │       ├── adapter-layer.md
│   │       ├── app-layer.md
│   │       ├── domain-layer.md
│   │       ├── infrastructure-layer.md
│   │       └── object-isolation.md
│   ├── java-coding-guidelines/          # 阿里 Java 编码规范
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── naming-conventions.md
│   │       ├── oop-conventions.md
│   │       ├── collection-concurrency.md
│   │       ├── exception-logging-control.md
│   │       ├── format-comments-structure.md
│   │       └── unit-test-security.md
│   ├── java-sdk-doc-generator/          # SDK 文档生成器
│   │   ├── SKILL.md
│   │   ├── analyze.md
│   │   ├── produce.md
│   │   ├── template.md
│   │   └── commit.md
│   ├── java-sdk-doc-skill-creator/      # SDK 文档 Skill 生成器
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── output-template.md
│   ├── mysql-conventions/               # MySQL 数据库规范
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── table-design.md
│   │       ├── index-rules.md
│   │       ├── sql-rules.md
│   │       └── orm-rules.md
│   └── restful-convention/              # RESTful API 规范
│       ├── SKILL.md
│       └── references/
│           ├── uri-design.md
│           ├── http-methods.md
│           ├── response-status.md
│           └── versioning-filtering.md
├── install-skills.sh                    # 一键安装脚本
└── skills-lock.json                     # 外部 skill 锁定文件
```

## Skill 设计原则

- **导航枢纽**：SKILL.md 只做路由和流程指引，不重复展开规则细节
- **单一信息源**：规则详细内容只在 `references/` 中维护，修改一处即可
- **按需加载**：模型根据导航表的 "When to Read" 列，按场景读取对应 reference 文件

## 新增 Skill

参考已有 skill 的结构：

```
skills/<skill-name>/
├── SKILL.md          # frontmatter (name + description) + 导航表 + 使用流程
└── references/       # 详细规则文档
    └── *.md
```

SKILL.md 的 frontmatter 格式：

```yaml
---
name: "<skill-name>"
description: "<功能说明>. Invoke when <触发条件>."
---
```

新增后推送到 GitHub，即可通过 `npx skills add zeno-common/soil-coding-skills --list` 发现。