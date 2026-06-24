# Project Structure

COLA 5 标准多模块项目结构规约。

## 模块划分

```
project-name
├── project-name-adapter        # 适配层
├── project-name-app            # 应用层
├── project-name-domain         # 领域层
├── project-name-infrastructure # 基础设施层
└── project-name-start          # 启动模块
```

## Maven 依赖关系

```
start → adapter → app → domain
                    ↑
        infrastructure ──┘
```

### start 模块

- 依赖: adapter
- 职责: Spring Boot 启动类、`application.yml`、环境配置
- 仅包含 `Application.java` 和配置文件

### adapter 模块

- 依赖: app
- 职责: 对接外部调用方，是系统的输入端

### app 模块

- 依赖: domain
- 职责: 编排领域服务，协调用例流程

### domain 模块

- 依赖: 无（不依赖任何其他业务模块）
- 职责: 核心业务逻辑，定义领域模型和网关接口

### infrastructure 模块

- 依赖: domain
- 职责: 实现领域层定义的网关接口，对接外部系统

## 基础包名

```
com.{company}.{project}
```

各模块基础包:

| 模块 | 基础包 |
|------|--------|
| adapter | `com.{company}.{project}.adapter` |
| app | `com.{company}.{project}.app` |
| domain | `com.{company}.{project}.domain` |
| infrastructure | `com.{company}.{project}.infrastructure` |

## Mandatory 规则

1. **模块命名必须**使用 `{project}-adapter / app / domain / infrastructure / start` 格式
2. **domain 模块不得**依赖 app、adapter、infrastructure 中的任何类
3. **adapter 不得**直接依赖 infrastructure 模块
4. **start 模块仅**包含启动类和配置，不含业务代码
5. 每个模块必须有独立的 `pom.xml`，依赖关系必须遵循上述方向

## Recommended 规则

1. 使用 COLA Archetype 生成初始项目骨架
2. 各模块 `pom.xml` 中使用 `<dependencyManagement>` 统一版本
3. domain 模块仅依赖通用工具包（如 commons-lang3、guava），不依赖 Spring 等框架
4. infrastructure 模块负责引入所有第三方中间件依赖，不向上层暴露具体实现