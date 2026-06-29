# App Layer

应用层目录规约。App 层负责用例编排，协调领域服务完成业务流程，不包含业务规则。

## 目录结构

```
app
└── src/main/java/com/{company}/{project}/app
    ├── service             # 应用服务（用例入口）
    ├── executor
    │   ├── command         # 写操作执行器
    │   └── query           # 读操作执行器
    ├── processor           # 流程编排器（可选）
    ├── command             # 写操作入参（Cmd）
    ├── query               # 读操作入参（Qry）
    └── vo                  # 视图对象（VO）
```

## 对象类型命名规约

App 模块定义 Cmd / Qry / VO 三种对象类型，供 adapter 层使用。详见 `references/object-isolation.md`。

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Command | `{Resource}{Action}Cmd` | `OrderCreateCmd` |
| Query | `{Resource}{Action}Qry` | `OrderListQry` |
| View Object | `{Resource}VO` | `OrderVO` |

## service 包

### 命名规约

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Application Service | `{Domain}ApplicationService` | `OrderApplicationService` |

### 职责边界

- 对外暴露用例方法（Adapter 层的调用入口）、编排领域服务/Executor/Processor
- 事务边界控制（`@Transactional`）、持久化成功后发布领域事件
- **禁止**包含业务规则判断 / 直接操作数据库

> **事件发布时机**：必须在聚合根持久化成功（`save`）之后才发布事件，确保消费者查询时数据已落库。发布后调用 `clearEvents()` 避免重复发布。

## executor/command 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Command Executor | `{Action}{Resource}Cmd` | `OrderCreateCmd` |

- 接收 Cmd → 转换为领域对象 → 调用领域服务或 Gateway → 转换为 VO 返回
- 一个 Cmd 对应一个写操作用例

## executor/query 包

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Query Executor | `{Action}{Resource}Qry` | `OrderListQry` |

- 接收 Qry → 可绕过领域层直接调用 infrastructure 的查询 Gateway → 组装分页响应
- 一个 Qry 对应一个读操作用例

## processor 包（可选）

| 类别 | 命名格式 | 示例 |
|------|---------|------|
| Processor | `{ProcessDescription}Processor` | `OrderCreateProcessor` |

当用例流程复杂（多步骤编排）时，从 Service 中抽取。编排多个领域服务调用，**禁止**包含业务规则。

## Mandatory 规则

1. Application Service 命名必须以 `ApplicationService` 结尾
2. Command Executor 命名必须以 `Cmd` 结尾，Query Executor 命名必须以 `Qry` 结尾
3. App 层**禁止**包含业务规则，业务规则必须在 domain 层
4. 事务注解 `@Transactional` 只能出现在 Application Service 上
5. Cmd / Qry 不得互相调用
6. App 层**禁止**直接依赖 infrastructure 模块的具体实现类

## Recommended 规则

1. 一个 Application Service 对应一个领域聚合
2. 一个 Cmd / Qry 只做一件事（单一职责）
3. 简单用例直接在 Service 中编排，不需要额外 Processor
4. Query Executor 中可直接调用 Gateway 的查询方法，不必经过领域服务
5. Cmd / Qry / VO 定义在 app 模块，供 adapter 层使用，不要在 adapter 层重新定义