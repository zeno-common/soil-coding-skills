#!/usr/bin/env bash
#
# Submodule 提交/标签/推送脚本 (bash 版)
# 在文档生成（产出阶段）完成后，检测 docs/agent-rules submodule 是否有变更，
# 若有增删改文件则自动提交、打标签并推送到远程。
#
# 用法:
#   ./commit-agent-rules.sh
#
set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 定位工程根目录（脚本位于 .trae/skills/java-sdk-doc-generator/ 下）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SUBMODULE_DIR="$PROJECT_ROOT/docs/agent-rules"
SUBMODULE_PATH="docs/agent-rules"
ROOT_POM="$PROJECT_ROOT/pom.xml"

# 从根 pom.xml 提取项目版本号
extract_version() {
  if [ ! -f "$ROOT_POM" ]; then
    echo -e "${RED}错误: 未找到根 pom.xml: $ROOT_POM${NC}"
    exit 1
  fi
  # 取根 pom 中第一个 <version> 标签的值（项目自身版本，非 parent 版本）
  sed -n 's/.*<version>\([^<]*\)<\/version>.*/\1/p' "$ROOT_POM" | head -1
}

echo -e "${YELLOW}[1/5] 提取项目版本号...${NC}"
VERSION=$(extract_version)
if [ -z "$VERSION" ]; then
  echo -e "${RED}错误: 无法从 pom.xml 提取版本号${NC}"
  exit 1
fi
echo -e "${GREEN}    项目版本: ${VERSION}${NC}"

TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
TAG="v${VERSION}-${TIMESTAMP}"

echo -e "${YELLOW}[2/5] 检查 submodule 变更状态...${NC}"

# 检查 submodule 是否已初始化（.git 可能是目录或文件）
if [ ! -e "$SUBMODULE_DIR/.git" ]; then
  echo -e "${RED}错误: submodule 未初始化: $SUBMODULE_DIR${NC}"
  echo -e "${YELLOW}请先执行 sync-agent-rules.sh 完成初始化${NC}"
  exit 1
fi

cd "$SUBMODULE_DIR"

# 检测是否有变更（增删改）
CHANGES=$(git status --porcelain)
if [ -z "$CHANGES" ]; then
  echo -e "${GREEN}    submodule 无变更，跳过提交${NC}"
  echo -e "${YELLOW}[5/5] 无需操作${NC}"
  exit 0
fi

echo -e "${YELLOW}    检测到以下变更:${NC}"
echo "$CHANGES" | sed 's/^/      /'
echo ""

echo -e "${YELLOW}[3/5] 提交变更...${NC}"

# 暂存所有变更（含新增、删除、修改）
git add -A

COMMIT_MSG="docs: 更新 SDK 文档 (${TAG})"
git commit -m "$COMMIT_MSG" --quiet
COMMIT_HASH=$(git rev-parse HEAD | cut -c1-8)
echo -e "${GREEN}    已提交: ${COMMIT_HASH}${NC}"

echo -e "${YELLOW}[4/5] 创建标签...${NC}"
git tag -a "$TAG" -m "SDK 文档自动生成 - 版本 ${VERSION} (${TIMESTAMP})"
echo -e "${GREEN}    已打标签: ${TAG}${NC}"

echo -e "${YELLOW}[5/5] 推送到远程...${NC}"

BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$BRANCH" ]; then
  echo -e "${YELLOW}    当前处于 detached HEAD 状态，检测远程默认分支...${NC}"
  # 优先用 symbolic-ref（本地缓存，快），但需验证分支确实存在
  REMOTE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [ -z "$REMOTE_BRANCH" ] || ! git rev-parse --verify "origin/$REMOTE_BRANCH" >/dev/null 2>&1; then
    # 缓存失效或为空，回退到查询远程
    REMOTE_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | sed 's/.*: //')
  fi
  if [ -z "$REMOTE_BRANCH" ] || ! git rev-parse --verify "origin/$REMOTE_BRANCH" >/dev/null 2>&1; then
    echo -e "${RED}错误: 无法获取远程默认分支，请手动指定后重试${NC}"
    exit 1
  fi
  echo -e "${GREEN}    远程默认分支: ${REMOTE_BRANCH}${NC}"
  PUSH_REF="HEAD:${REMOTE_BRANCH}"
else
  echo -e "${GREEN}    当前分支: ${BRANCH}${NC}"
  PUSH_REF="$BRANCH"
fi

# 推送提交和标签
git push origin "$PUSH_REF"
git push origin "$TAG"
echo -e "${GREEN}    已推送提交和标签 ${TAG}${NC}"

echo ""
echo -e "${GREEN}===== 提交发布完成 =====${NC}"