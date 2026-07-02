# Project Structure

```
project-name
├── project-name-client         # API 契约（接口 + DTO）
├── project-name-adapter        # 适配层
├── project-name-app            # 应用层
├── project-name-domain         # 领域层
├── project-name-infrastructure # 基础设施层
└── project-name-start          # 启动模块
```

## Dependencies

```
start → adapter → app → domain ← infrastructure
adapter → client
consumer → client jar only
```

| Module | Depends On | Purpose |
|--------|-----------|---------|
| client | nothing | 服务间调用契约（接口 + DTO） |
| start | adapter | 启动类、application.yml |
| adapter | app, client | 对接外部调用方，实现 client Api 接口 |
| app | domain | 编排领域服务，协调用例流程 |
| domain | nothing | 核心业务逻辑，定义领域模型和网关接口 |
| infrastructure | domain | 实现网关接口，对接外部系统 |

Base package: `com.{company}.{project}`，sub: `adapter` / `app` / `domain` / `infrastructure`

## Rules

1. Module naming: `{project}-client / adapter / app / domain / infrastructure / start`
2. domain MUST NOT depend on app/adapter/infrastructure; adapter MUST NOT depend on infrastructure
3. start = startup class + config only; client MUST NOT depend on other business modules
4. Each module has independent pom.xml, dependency direction MUST follow above
5. Use COLA Archetype for initial skeleton; `<dependencyManagement>` for version unification
6. domain only depends on utils (commons-lang3/guava), no Spring
7. infrastructure introduces third-party middleware deps, never exposes implementation upward
8. Omit client module if no inter-service calls needed