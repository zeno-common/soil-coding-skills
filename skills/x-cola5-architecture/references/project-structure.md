# Project Structure

COLA 5 标准多模块项目结构规约。

## 模块划分

```
project-name
├── project-name-client         # API 契约模块（接口 + DTO，供消费方依赖）
├── project-name-adapter        # 适配层
├── project-name-app            # 应用层
├── project-name-domain         # 领域层
├── project-name-infrastructure # 基础设施层
└── project-name-start          # 启动模块
```

## Maven 依赖关系

```
        
start → adapter → app → domain ← infrastructure
           ↑              ↑         |
           │              └─────────┘
           │           infrastructure 依赖 domain
           │           （实现 domain 定义的 Gateway 接口）
           └── adapter 依赖 client
               （实现 client 定义的 Api 接口）

consumer ──→ client（消费方仅依赖 client jar）
```

| 模块 | 依赖 | 职责 |
|------|------|------|
| client | 无 | 服务间调用契约（接口 + DTO），供消费方依赖 |
| start | adapter | Spring Boot 启动类、`application.yml`、环境配置 |
| adapter | app, client | 对接外部调用方，实现 client 定义的 Api 接口 |
| app | domain | 编排领域服务，协调用例流程 |
| domain | 无 | 核心业务逻辑，定义领域模型和网关接口 |
| infrastructure | domain | 实现网关接口，对接外部系统 |

## 基础包名

`com.{company}.{project}`，各模块：`adapter` / `app` / `domain` / `infrastructure`

## Mandatory 规则

1. 模块命名必须使用 `{project}-client / adapter / app / domain / infrastructure / start` 格式
2. domain 模块不得依赖 app、adapter、infrastructure 中的任何类
3. adapter 不得直接依赖 infrastructure 模块
4. start 模块仅包含启动类和配置，不含业务代码
5. client 模块禁止依赖 adapter、app、domain、infrastructure 模块
6. 每个模块必须有独立的 `pom.xml`，依赖关系必须遵循上述方向

## Recommended 规则

1. 使用 COLA Archetype 生成初始项目骨架
2. 各模块 `pom.xml` 中使用 `<dependencyManagement>` 统一版本
3. domain 模块仅依赖通用工具包（如 commons-lang3、guava），不依赖 Spring 等框架
4. infrastructure 模块负责引入所有第三方中间件依赖，不向上层暴露具体实现
5. client 模块仅依赖通用工具包，不依赖 Spring 等框架；当服务无服务间调用需求时，可省略 client 模块