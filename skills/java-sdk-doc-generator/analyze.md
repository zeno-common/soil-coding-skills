# 分析阶段（步骤 1-3）

## 1. 确定范围

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **增量更新（默认）** | 用户未指定范围 | 检测 `git status` 变更的 `.java` 文件，仅更新对应文档 |
| **全量生成** | 用户要求全量 | 扫描 `jsf-common/` 下所有 `*.java` |
| **指定模块** | 用户指定模块名 | 仅扫描该模块 `src/main/java/` |

## 2. 检测 Git 变更

仅增量模式执行。

```bash
git status --porcelain -- "*.java"
git diff --name-only -- "*.java" && git diff --cached --name-only -- "*.java"
git log -1 --format="%h"
```

忽略：`target/` 目录、测试文件（`src/test/`）、`.gitignore` 排除的文件。

## 3. 解析 Java 源码

### 类级别
- 完整限定名、类型（class/interface/enum/abstract）、修饰符
- 注解（Spring 系列、`@Deprecated`、Lombok 等）
- 继承/实现关系、泛型参数
- 类级 Javadoc（描述、`@author`、`@since`、`@deprecated`）

### 方法级别（仅 public/protected）
- 完整签名（含泛型）、注解（`@GetMapping`、`@Transactional`、`@PreAuthorize` 等）
- Javadoc 全部标签：`@param`、`@return`、`@throws`、`@see`、`@since`、`@deprecated`

### 字段级别
- `public static final` 常量（含值）
- 带有 `@Value`、`@Autowired` 的关键字段

### 枚举值
- 每个枚举常量的名称和 Javadoc