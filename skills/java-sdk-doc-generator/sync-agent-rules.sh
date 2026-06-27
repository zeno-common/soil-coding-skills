#!/usr/bin/env bash
#
# Submodule 同步脚本 (bash 版)
# 在代码生成前检测 docs/agent-rules submodule 是否为最新，
# 若落后于远程则自动拉取更新。
#
# 用法:
#   ./sync-agent-rules.sh
#
set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 定位工程根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SUBMODULE_DIR="$PROJECT_ROOT/docs/agent-rules"
SUBMODULE_PATH="docs/agent-rules"

echo -e "${YELLOW}[1/3] 检查 submodule 初始化状态...${NC}"

# 检查父仓库是否为 git 仓库
if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo -e "${RED}错误: 当前工程不是 git 仓库: $PROJECT_ROOT${NC}"
  exit 1
fi

# 检查 submodule 是否已在 .gitmodules 中注册
if [ ! -f "$PROJECT_ROOT/.gitmodules" ] || \
   ! grep -q "$SUBMODULE_PATH" "$PROJECT_ROOT/.gitmodules" 2>/dev/null; then
  echo -e "${RED}错误: 未找到 submodule 配置: $SUBMODULE_PATH${NC}"
  echo -e "${YELLOW}请先执行: git submodule add <url> $SUBMODULE_PATH${NC}"
  exit 1
fi

# 检查 submodule 工作目录是否已初始化（.git 可能是目录或文件）
if [ ! -e "$SUBMODULE_DIR/.git" ]; then
  echo -e "${YELLOW}    submodule 未初始化，正在初始化并拉取...${NC}"
  cd "$PROJECT_ROOT"
  git submodule update --init --recursive "$SUBMODULE_PATH"
  echo -e "${GREEN}    submodule 初始化完成${NC}"
else
  echo -e "${GREEN}    submodule 已初始化: $SUBMODULE_DIR${NC}"
fi

echo -e "${YELLOW}[2/3] 检测远程更新...${NC}"
cd "$SUBMODULE_DIR"

# 获取当前分支（submodule 常处于 detached HEAD 状态）
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo -e "${YELLOW}    当前处于 detached HEAD 状态，检测远程默认分支...${NC}"
  # 优先用 symbolic-ref（本地缓存，快），但需验证分支确实存在
  BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [ -z "$BRANCH" ] || ! git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    # 缓存失效或为空，回退到查询远程
    BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | sed 's/.*: //')
  fi
  if [ -z "$BRANCH" ] || ! git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    echo -e "${RED}错误: 无法获取远程默认分支${NC}"
    exit 1
  fi
  echo -e "${GREEN}    远程默认分支: $BRANCH (detached HEAD)${NC}"
else
  echo -e "${GREEN}    当前分支: $BRANCH${NC}"
fi

# 拉取远程引用
git fetch origin "$BRANCH" --quiet

# 比较本地与远程 HEAD
LOCAL_HEAD=$(git rev-parse HEAD)
REMOTE_HEAD=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL_HEAD" = "$REMOTE_HEAD" ]; then
  echo -e "${GREEN}    已是最新 (commit: ${LOCAL_HEAD:0:8})${NC}"
  echo -e "${YELLOW}[3/3] 无需更新，跳过${NC}"
  exit 0
fi

# 检查本地是否有未提交变更
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${RED}警告: submodule 有未提交的本地变更，请先提交或暂存后再拉取${NC}"
  echo -e "${YELLOW}    可执行: git -C \"$SUBMODULE_DIR\" stash 或 git -C \"$SUBMODULE_DIR\" commit${NC}"
  exit 1
fi

echo -e "${YELLOW}[3/3] 检测到远程有更新，正在拉取...${NC}"
echo -e "    本地: ${LOCAL_HEAD:0:8}"
echo -e "    远程: ${REMOTE_HEAD:0:8}"

# detached HEAD 时用 merge --ff-only，否则用 pull
if [ -z "$(git branch --show-current 2>/dev/null || echo '')" ]; then
  git merge --ff-only "origin/$BRANCH"
else
  git pull origin "$BRANCH" --ff-only
fi
echo -e "${GREEN}    已更新到最新 (commit: $(git rev-parse HEAD | cut -c1-8))${NC}"

echo ""
echo -e "${GREEN}===== 同步完成 =====${NC}"
echo -e "${YELLOW}提示: submodule 已更新，如需在父仓库记录新引用，请执行:${NC}"
echo -e "  cd \"$PROJECT_ROOT\" && git add $SUBMODULE_PATH && git commit -m \"chore: 更新 agent-rules submodule 引用\""