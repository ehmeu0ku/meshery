#!/bin/bash
# validate-commit-msg.sh
# Git commit-msg hook to enforce conventional commit message format
# for the Meshery project.
#
# Install by symlinking or copying to .git/hooks/commit-msg
# Usage: chmod +x .agents/hooks/validate-commit-msg.sh

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Conventional commit pattern
# Format: <type>(<optional scope>): <description>
# Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
CONVENTIONAL_COMMIT_REGEX='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_/-]+\))?(!)?: .{1,100}$'

# Allow merge commits
if echo "$COMMIT_MSG" | grep -qE '^Merge '; then
  exit 0
fi

# Allow revert commits
if echo "$COMMIT_MSG" | grep -qE '^Revert '; then
  exit 0
fi

# Get the first line of the commit message
FIRST_LINE=$(echo "$COMMIT_MSG" | head -n 1)

# Validate against conventional commit format
if ! echo "$FIRST_LINE" | grep -qE "$CONVENTIONAL_COMMIT_REGEX"; then
  echo -e "${RED}ERROR: Invalid commit message format.${NC}"
  echo -e "${YELLOW}Your commit message:${NC} $FIRST_LINE"
  echo ""
  echo -e "${YELLOW}Expected format:${NC} <type>(<scope>): <description>"
  echo ""
  echo -e "${YELLOW}Allowed types:${NC}"
  echo "  feat     - A new feature"
  echo "  fix      - A bug fix"
  echo "  docs     - Documentation changes"
  echo "  style    - Code style changes (formatting, missing semicolons, etc.)"
  echo "  refactor - Code refactoring without feature/fix"
  echo "  perf     - Performance improvements"
  echo "  test     - Adding or updating tests"
  echo "  build    - Build system or dependency changes"
  echo "  ci       - CI/CD configuration changes"
  echo "  chore    - Maintenance tasks"
  echo "  revert   - Reverting a previous commit"
  echo ""
  echo -e "${YELLOW}Examples:${NC}"
  echo "  feat(meshmodel): add support for Kubernetes v1.29 components"
  echo "  fix(server): resolve nil pointer dereference in pattern engine"
  echo "  docs(contributing): update development setup instructions"
  echo "  chore(deps): upgrade go modules to latest versions"
  echo ""
  echo -e "${RED}Commit aborted.${NC} Please amend your commit message."
  exit 1
fi

# Warn if description starts with uppercase (style preference)
DESCRIPTION=$(echo "$FIRST_LINE" | sed 's/^[^:]*: //')
FIRST_CHAR=$(echo "$DESCRIPTION" | cut -c1)
if echo "$FIRST_CHAR" | grep -qE '[A-Z]'; then
  echo -e "${YELLOW}WARNING: Commit description should start with a lowercase letter.${NC}"
  echo -e "  Got: '$DESCRIPTION'"
fi

# Warn if description ends with a period
if echo "$DESCRIPTION" | grep -qE '\.$'; then
  echo -e "${YELLOW}WARNING: Commit description should not end with a period.${NC}"
fi

echo -e "${GREEN}Commit message format is valid.${NC}"
exit 0
