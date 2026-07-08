# 产出阶段（步骤 4-6）

## 4. 生成 Markdown 文档

格式严格遵循 [template.md](template.md) 中的模板。

核心要求：
- 使用结构化表格，字段标签明确，便于 AI 程序化解析
- 无 Javadoc 的成员标注 `*(No description provided)*`
- 同项目内的类型引用生成相对 Markdown 链接
- 所有文件 UTF-8 编码

### 省略规则

| 字段/段落 | 省略条件 |
|-----------|----------|
| `extends` / `implements` | 无继承或仅继承 `Object`，无实现接口 |
| 注解行 | 类/方法无注解 |
| `@Deprecated` | 未被 `@Deprecated` 标记 |
| `Constants` 段落 | 无 `public static final` 字段 |
| `Enum Values` 段落 | 非枚举类型 |
| `throws` | 方法无 `@throws` 声明 |
| 参数表 | 方法无参数 |

## 5. 输出文件

目录结构：

```
docs/agent-rules/
├── README.md
├── <module-name>/
│   └── <package-name>/
│       └── <ClassName>.md
```

**``<package-name>`` 命名规则**：将 Java 包名原样保留（含 ``.``）作为单级目录名，**不要**按 ``/`` 拆分为多级子目录。
- ✅ 正确：``<package-name>/`` （包名原样作为目录名）
- ❌ 错误：``<package-name>/config/`` （按路径分隔符拆分为多级目录）

增量更新策略：

| 文件变更 | 操作 |
|----------|------|
| 新增/修改 | 覆盖对应 `.md` |
| 删除 | 删除对应 `.md`（若存在） |

每次生成后在 `docs/agent-rules/README.md` 更新索引。README.md 是 AI Agent 的入口文件，必须包含以下三个核心段落，确保 AI Agent 能通过此文件完成「引入依赖 → 定位类 → 查阅详情」的完整流程：

### README.md 模板

```markdown
# Introduction
依赖引入参考： '[jsf-bom/README.md](jsf-bom/README.md)'

---

# SDK Documentation Index
## 模块概览

| Module | ArtifactId | Description |
|--------|-----------|-------------|
| <module-path> | `<artifactId>` | <一句话描述模块用途> |

---

## 类索引

> 按模块 → 包分组，每个类附一行功能描述和文档链接。

### <module-name> — <模块简述>

#### <package> — <包简述>

| Class | Package | Description | Doc |
|-------|---------|-------------|-----|
| `ClassName` | `com.example.package` | <从类 Javadoc 第一句提取> | [ClassName](com.example.package/ClassName.md) |

---

## 使用指南

AI Agent 在代码生成时遵循以下流程：

1. **需求匹配** — 根据功能需求从上方「类索引」中查找对应类
2. **查阅详情** — 点击 Doc 链接进入类的完整 API 文档，了解方法签名、参数和返回值
3. **引入依赖** — 从「Maven 依赖引入」复制对应 `artifactId` 的依赖坐标到 `pom.xml`
4. **编写代码** — 根据文档中的方法签名和参数说明生成正确的调用代码

---

```

### README.md 生成规则

| 段落 | 数据来源 | 规则 |
|------|----------|------|
| Maven 依赖引入 | 模块 `pom.xml` 的 `<groupId>`、`<artifactId>`、`<version>` | 跳过纯聚合模块（packaging=pom 且无 Java 源码） |
| 模块概览 | 模块目录名 + pom.xml | 从模块 README 或模块名推断描述 |
| 类索引 | Java 类 Javadoc 第一句 | 按模块 → 包路径分组，Doc 列为相对路径链接，包名作为单级目录（如 `<package-name>/ClassName.md`） |
| 使用指南 | 固定文本 | 直接使用模板中的固定内容 |

## 6. 关键规则

1. **仅公开 API** — 聚焦 `public` 类/方法/字段，跳过 `private`/package-private
2. **注解感知** — 捕获 Spring MVC、Security、Transaction、Validation、Lombok、Deprecated 注解
3. **废弃标记** — `@Deprecated` 需标注 `since`、`forRemoval`、替代方案
4. **无重复写入** — 先检查文件是否存在，增量模式仅覆盖变更文件
5. **空 Javadoc 保留结构** — 仍输出签名和注解，描述标为 `*(No description provided)*`

## 完成汇总

| 指标 | 数量 |
|------|------|
| 处理的模块 | N |
| 已文档化的类 | N |
| 已文档化的方法 | N |
| 新建文件 | N |
| 更新文件 | N |
| 删除文件 | N |

---

> **下一步**：产出完成后自动进入「提交发布」阶段，检测 submodule 变更并提交、打标签、推送。详见 [commit.md](commit.md)。
