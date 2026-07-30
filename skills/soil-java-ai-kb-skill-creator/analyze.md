# 分析阶段（步骤 1）

## 1. 范围与变更检测

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **增量（默认）** | 用户未指定范围 | 仅处理 `git status` 变更的 `*.java` 对应条目 |
| **全量** | 用户要求全量 | 扫描指定根目录（如 `src/main/java/`）下所有 `*.java` |
| **指定子模块** | 用户指定子模块名 | 仅扫描该子模块 |

```bash
git status --porcelain -- "*.java"
git diff --name-only -- "*.java"
git diff --cached --name-only -- "*.java"
```

忽略：`target/`、测试（`src/test/`）、`.gitignore` 排除的文件。

## 2. 子模块识别（知识模块边界）

- 本 skill **为整个 Java 工程生成一个 AI KB Skill**；整个工程是知识来源
- **工程根目录的每个子模块 = 该技能内的一个独立知识模块**，存放于独立目录
- 子模块判定：工程根目录下含 `pom.xml`（Maven 多模块）或 `build.gradle` 的直接子目录
- 每个子模块对应生成的 KB 技能中 `skills/<submodule>/` 目录
- 子模块的依赖坐标取自该子模块自身的 `pom.xml` 的 `groupId:artifactId:version`

## 3. 标识体系（决定条目是否生成）

文档**只**为被 `@ai-doc-sdk` / `@ai-doc-rest` 解析注解显式标记的成员生成。未标记的类一律跳过，**不做任何无标记自动识别兜底**。

> 必须依赖显式解析注解判定，绝不允许仅凭 Spring 注解（如 `@RestController`/`@FeignClient`）或其他启发式规则推断并生成条目。

### 3.1 解析注解（唯一，必带）

| 解析注解 | 位置 | 作用 |
|----------|------|------|
| `@ai-doc-sdk` | 类 Javadoc | 标记该类为对外 **JAR SDK**，生成其类调用知识 |
| `@ai-doc-rest` | 类 Javadoc | 标记该类为对外暴露的 **Spring REST 服务端**，生成其类调用知识（仅服务端） |

```java
/**
 * 短信发送 SDK，供外部服务引入调用。
 * @ai-doc-sdk
 */
public class SmsClient { ... }

/**
 * 订单查询 REST 接口。
 * @ai-doc-rest
 */
@RestController
@RequestMapping("/api/v1/orders")
public class OrderApi { ... }
```

> 解析注解是唯一准入条件；其上方的 Spring 注解（如 `@RestController`、`@FeignClient`）仅用于**补全类型与端点信息**，不单独作为生成依据。

## 4. 条目分类与提取

### 4.1 模块说明 + 依赖条目（子模块级，仅一次）→ `introduce.md`

按子模块分组，每个子模块一段：
- 子模块简述（取模块 README / 模块名推断）
- 依赖坐标：子模块 `pom.xml` 的 `groupId:artifactId:version`
- 仅输出 Maven 片段（不提供 Gradle）

> 第三方依赖由 Maven/Gradle 传递解析，无需逐类声明；`introduce.md` 仅列出子模块自身坐标。

### 4.2 SDK 类调用知识（命中 `@ai-doc-sdk`）

- **依赖**：不内嵌、不逐类重复；统一见 `introduce.md#<submodule>`，`<submodule>` = 类文档所在目录名（如 `<submodule>/sdk/...` → `introduce.md#<submodule>`）
- **配置（前置，统一在 `config.md`）**：从 Javadoc / 构造器 / `init`·`setXxx` 提取，沉淀到 `<submodule>/config.md` 的「类调用前置配置」，不在类文档重复
  - `application.yml` / `properties` 键
  - `@Configuration` `@Bean` 初始化片段
  - 超时、连接、密钥等必要参数
- **类调用**：仅对外入口
  - public 构造器、被 `@ai-doc-sdk` 标记类的 public 方法（含 Lombok 生成的访问器，见 §4.5）
  - 每个入口：签名、参数（类型+含义）、返回值、可复制调用示例
  - 参数或返回若为 POJO，按其字段展开为请求参数/返回信息（见 §4.6）

### 4.3 REST 类调用知识 — 服务端（命中 `@ai-doc-rest`）

- **依赖**：通常无需；若缺 `spring-boot-starter-web` 在 introduce.md 提示一次
- **配置（前置，统一在 `config.md`）**：仅端点级非约定项（`@PreAuthorize` 特定角色、速率限制、自定义请求头）沉淀到 `config.md` 的「类调用前置配置」，不内嵌于类文档；类级 `@RequestMapping` 前缀、`Bearer` 鉴权头、CORS 等属**系统架构约定**，全文见系统 API 调用约定（如 `restful-convention` / 项目全局约定）
- **类调用**（HTTP 视角）：每个端点的方法+完整路径（含路径参数）、路径/查询参数、请求体/响应类型、必需请求头、一段 `curl` 示例
  - 请求体/响应若为 POJO，按其字段展开为请求参数/返回信息（见 §4.6）

### 4.5 Lombok 注解解析

被 `@ai-doc-sdk` / `@ai-doc-rest` 标记的类可能使用 Lombok 注解。解析时**必须还原 Lombok 生成的成员**，否则类调用知识会缺失方法/字段。

| Lombok 注解 | 还原内容 |
|-------------|----------|
| `@Getter` / `@Setter` | 为标注字段生成 `getXxx()` / `setXxx(v)`；类级注解则对所有 non-static 字段生成 |
| `@Data` / `@Value` | 等效 `@Getter`+`@Setter`+`@RequiredArgsConstructor`（`@Value` 不可变、仅 getter） |
| `@Builder` | 生成 `builder()`、`XxxBuilder` 及 `build()`；配合 `@ai-doc-sdk` 的初始化示例应使用 builder |
| `@NoArgsConstructor` / `@AllArgsConstructor` / `@RequiredArgsConstructor` | 生成对应构造器（注意 `@RequiredArgsConstructor` 含 `final` 字段与 `@NonNull` 字段） |
| `@ToString` / `@EqualsAndHashCode` | 仅影响 `toString`/`equals`/`hashCode`，般不纳入类调用知识 |
| `@Slf4j` 等日志注解 | 生成日志字段，一般不纳入类调用知识 |

解析规则：

- 提取字段时，连同 Lombok 生成访问器一并视为公开入口（其可见性视生成方法为 `public`）
- 配置/调用示例需体现 Lombok 结果：例如带 `@Builder` 的 SDK 类，示例用 `ClassName.builder()...build()`；带 `@RequiredArgsConstructor` 的不可变 SDK 用构造器注入 `final` 字段
- **不要**把 Lombok 注解本身当作 `@ai-doc-sdk`/`@ai-doc-rest` 的替代判定；它只参与"已标记类的成员还原"

### 4.6 请求 / 返回 POJO 知识

SDK / REST 入口的**参数或返回若为 POJO**，该 POJO 的字段必须作为该入口的**请求参数 / 返回信息**一并沉淀为调用知识（而非仅写类名）。POJO 自身**不会**单独成为知识条目。

- **纳入条件**：仅当 POJO 被某个 `@ai-doc-sdk` / `@ai-doc-rest` 条目的入参或返回引用时才展开；未被任何对外入口引用的内部 DTO 仍跳过
- **字段展开**：列出字段名、类型、含义（取自字段 Javadoc / 类 Javadoc）；嵌套 POJO 递归展开至基本类型 / 集合 / 已知外部类型
- **POJO 上的 Lombok 仅用于字段解析**：
  - POJO 类的 `@Getter`/`@Data`/`@Value` 用于还原可读字段；`@Builder` 用于还原构建方式；`@NoArgsConstructor` 等用于还原构造器
  - **Lombok 注解在 POJO 上是"成员还原工具"，不是"文档识别标识"** —— 绝不能因为 POJO 带了 Lombok 就单独为它生成知识条目
  - 展开字段时把 Lombok 生成的访问器/构造器视为可见，但不把 Lombok 注解写进文档判定逻辑
- **示例体现**：调用示例中用 Lombok 方式构造/读取 POJO（如 `new Req().setXxx(v)`、`Resp.builder()...build()` 或 `resp.getXxx()`）

## 5. 外部调用判定与过滤

仅沉淀外部调用所需；以下一律跳过：

| 跳过内容 | 原因 |
|----------|------|
| 未带 `@ai-doc-sdk` / `@ai-doc-rest` 解析注解的类 | 非知识库对象（无标记即跳过，不做自动识别兜底） |
| `private` / package-private 成员（Lombok 生成的 public 访问器除外） | 外部不可调用 |
| 无 HTTP 映射、非 SDK 公开面的方法 | 非对外入口 |
| 未作为任何 `@ai-doc` 外部调用请求/响应的内部 DTO/实体 | 非外部调用所需（被引用 POJO 需展开字段，但 POJO 自身不单独成条目） |
| 仅带 Lombok 等注解而无 `@ai-doc` 标记的类 | Lombok 仅用于字段解析，不是文档识别标识，无标记即跳过 |
| 业务实现、SQL、内部 Service 调用链 | 与「外部调用」无关 |
| 逐类内嵌的依赖坐标 | 已在 introduce.md 集中，避免冗余 |
| 本项目其他模块内部引用 | 不参考本工程其他内容 |
