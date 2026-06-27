# 提交发布阶段（步骤 7）

> 在「产出」阶段完成后自动执行。检测 agent-rules submodule 的文件变更，若有增删改则提交、打标签并推送。

## 执行脚本

执行 [commit-agent-rules.sh](commit-agent-rules.sh)：

```bash
./commit-agent-rules.sh
```

> Windows 环境下通过 Git Bash 执行：`bash commit-agent-rules.sh`

## 执行流程

| 步骤 | 动作 | 说明 |
|------|------|------|
| 1 | 提取版本号 | 从根 `pom.xml` 的 `<version>` 提取项目版本号 |
| 2 | 检测变更 | `git status --porcelain` 检查 submodule 是否有增删改文件 |
| 3 | 提交变更 | `git add -A` + `git commit`，提交信息含版本号和时间戳 |
| 4 | 创建标签 | `git tag -a`，标签格式 `v<版本号>-<时间戳>` |
| 5 | 推送远程 | `git push` 推送分支和标签 |

## 标签命名规则

```
v${VERSION}-${TIMESTAMP}
```

| 变量 | 来源 | 示例 |
|------|------|------|
| `VERSION` | 根 `pom.xml` 的 `<version>` | `0.0.1` |
| `TIMESTAMP` | 当前时间 `YYMMDD-HHMMSS` | `260617-153000` |

示例标签：`v0.0.1-260617-153000`

## 跳过条件

| 条件 | 行为 |
|------|------|
| submodule 无变更（`git status --porcelain` 为空） | 跳过提交、标签、推送，直接结束 |
| submodule 未初始化 | 报错退出，提示先执行 sync-agent-rules.sh |
| submodule 处于 detached HEAD | 自动检测远程默认分支，使用 `HEAD:<remote-branch>` 推送 |
| 无法获取远程默认分支 | 报错退出，提示手动指定分支 |

## 提交信息格式

```
docs: 更新 SDK 文档 (v${VERSION}-${TIMESTAMP})
```

## 父仓库引用更新

submodule 推送后，在父仓库记录新引用：

```bash
cd <PROJECT_ROOT>
git add docs/agent-rules
git commit -m "chore: 更新 agent-rules submodule 引用"
```