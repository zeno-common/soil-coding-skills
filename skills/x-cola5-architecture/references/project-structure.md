# Project Structure

COLA 5 标准多模块项目结构规约。

## 模块划分与依赖关系

```
project-name
├── project-name-client         # API 契约（接口 + DTO，供消费方依赖）
├── project-name-adapter        # 适配层
├── project-name-app            # 应用层
├── project-name-domain         # 领域层
├── project-name-infrastructure # 基础设施层
└── project-name-start          # 启动模块（仅启动类 + 配置）
```

依赖方向：`start → adapter → app → domain ← infrastructure`
- adapter 额外依赖 client（实现 Api 接口）
- consumer 仅依赖 client jar

| 模块 | 依赖 | 职责 |
|------|------|------|
| client | 无 | 服务间调用契约（接口 + DTO） |
| start | adapter | 启动类、application.yml |
| adapter | app, client | 对接外部调用方，实现 client 的 Api 接口 |
| app | domain | 编排领域服务，协调用例流程 |
| domain | 无 | 核心业务逻辑，定义领域模型和网关接口 |
| infrastructure | domain | 实现网关接口，对接外部系统 |

基础包名：`com.{company}.{project}`，各模块：`adapter` / `app` / `domain` / `infrastructure`

## Mandatory 规则

1. 模块命名：`{project}-client / adapter / app / domain / infrastructure / start`
2. domain 禁止依赖 app/adapter/infrastructure；adapter 禁止直接依赖 infrastructure
3. start 仅含启动类和配置；client 禁止依赖其他业务模块
4. 各模块独立 pom.xml，依赖方向必须遵循上述规则

## Recommended 规则

1. 用 COLA Archetype 生成初始骨架；pom.xml 用 `<dependencyManagement>` 统一版本
2. domain 仅依赖通用工具包（commons-lang3/guava），不依赖 Spring
3. infrastructure 引入第三方中间件依赖，不向上暴露具体实现
4. 无服务间调用需求时可省略 client 模块