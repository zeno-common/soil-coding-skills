# Project Structure

> 基于 `cola-framework-archetype-light` 制定。**Light 原型 = 单 Maven 模块，分层以 Java 包（package）实现**，没有 `client` / `start` / `adapter` / `app` / `domain` 等独立模块；Spring Boot 启动类 `Application` 直接放在根包。本规范按需求将 API 契约（接口 + DTO）从 `application` 提升为**独立的 `client` 模块**，作为对外发布的**契约包**（可独立发布为 jar，供消费方依赖）。

```
project-name/                         # 聚合父模块（packaging=pom）
├── pom.xml                           # <modules>：client, app
├── project-name-client/              # 外部契约包（接口 + DTO，可独立发布 jar）
│   └── src/main/java/{base}/client/
│       ├── api/                      # 服务接口（含 @RequestMapping 等 HTTP 注解）
│       └── dto/                      # 请求 / 响应 / 事件 DTO
└── project-name-app/                 # 实现模块：Light 单模块 + 包级分层
    ├── Application.java              # 根包启动类（Light 无独立 start 模块）
    └── src/main/java/{base}/
        ├── adapter/                  # 适配层：REST 控制器 implements client.api.*Api
        ├── application/              # 应用层：用例编排（不含契约）
        ├── domain/                   # 领域层：实体 / 领域服务 / gateway 接口
        │   ├── <subdomain>/          # 按业务能力划分子包
        │   └── gateway/              # 领域网关接口（由 infrastructure 实现）
        └── infrastructure/           # 基础设施层：gateway 实现 / Mapper / DO / 外部Client
```

Base package: `com.{company}.{project}`；实现模块子包：`adapter` / `application` / `domain` / `infrastructure`；client 子包：`client.api` / `client.dto`。

## Dependencies

```
impl module (app):  adapter → application → domain ← infrastructure
adapter → client ; application → client ; infrastructure → client
consumer → client jar only
```

| Module | Depends On | Purpose |
|--------|-----------|---------|
| client | nothing（仅 spring-web 提供注解） | 对外契约包：服务间调用契约（接口 + DTO），可独立发布 |
| app (impl) | client | 业务实现：adapter/application/domain/infrastructure 四个包 |
| domain (package) | nothing | 核心业务逻辑，定义领域模型和网关接口 |
| infrastructure (package) | domain, client | 实现网关接口，对接外部系统 |
| adapter (package) | application, client | 对接外部调用方，实现 client.api 接口 |

说明：
- Light 用**单模块 + 包**替代多模块的编译期隔离；若需强制分层，可加架构守护测试（如 ArchUnit / `CleanArchTest`）在测试期校验包依赖。
- `Application` 启动类位于 `app` 模块根包，Light 不单独拆 `start` 模块。

## Light Archetype Note

- 官方 `cola-framework-archetype-light` 生成的是**单模块**工程：API 接口（如 `ChargeServiceI`）与 DTO 默认内置于 `application/` 包。
- 本规范将 `application/api` + `application/dto` 提升为独立 `client` 模块：契约可单独发布、被消费方以 jar 依赖，避免消费方耦合整个实现。
- 其余四层（adapter / application / domain / infrastructure）以**包**形式存在于 `app` 模块内，分层规则同各层参考文档。

## Rules

1. 聚合父模块含 2 子模块：`client`（契约包）与 `app`（实现模块）。`app` 内四层为 package，非独立模块。
2. domain（package）MUST NOT depend on application/adapter/infrastructure；adapter（package）MUST NOT depend on infrastructure。
3. `app` 模块仅含 `Application` 启动类 + 四个分层包；不拆 `start` 模块。
4. client MUST NOT depend on app/domain/infrastructure；MUST NOT 含业务逻辑或转换逻辑。
5. client 作为外部契约包应独立发布（deploy 到 Maven 仓库）；仅在完全无跨服务调用时可省略。
6. domain package 仅依赖工具类（commons-lang3/guava），不引入 Spring。
7. infrastructure package 引入三方中间件依赖，不得向上暴露实现细节。
8. 以 COLA Light Archetype 作为 `app` 模块骨架；`<dependencyManagement>` 统一版本。
