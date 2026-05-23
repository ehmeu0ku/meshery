#!/bin/bash
# lint-frontend.sh — Run ESLint and type checks on staged frontend files
# Part of the Meshery pre-commit hook pipeline

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Running frontend linting checks..."

# Determine the UI directory
UI_DIR="ui"
PROVIDER_UI_DIR="provider-ui"

# Check if we're in the repo root
if [ ! -d "$UI_DIR" ] && [ ! -d "$PROVIDER_UI_DIR" ]; then
  echo -e "${YELLOW}Warning: No UI directories found, skipping frontend lint.${NC}"
  exit 0
fi

# Get list of staged JS/TS/JSX/TSX files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|jsx|ts|tsx)$' || true)

if [ -z "$STAGED_FILES" ]; then
  echo -e "${GREEN}No staged JS/TS files found, skipping frontend lint.${NC}"
  exit 0
fi

echo "Staged frontend files to lint:"
echo "$STAGED_FILES"

# Lint files in the UI directory
UI_STAGED=$(echo "$STAGED_FILES" | grep "^ui/" || true)
if [ -n "$UI_STAGED" ] && [ -d "$UI_DIR" ]; then
  if [ ! -f "$UI_DIR/node_modules/.bin/eslint" ]; then
    echo -e "${YELLOW}ESLint not found in $UI_DIR/node_modules. Run 'make ui-setup' first.${NC}"
    exit 1
  fi

  echo "Linting UI files..."
  # Strip the 'ui/' prefix for eslint since we cd into the directory
  UI_FILES=$(echo "$UI_STAGED" | sed 's|^ui/||')
  cd "$UI_DIR"
  if ! echo "$UI_FILES" | xargs ./node_modules/.bin/eslint --max-warnings=0; then
    echo -e "${RED}ESLint found errors in UI files. Please fix them before committing.${NC}"
    cd ..
    exit 1
  fi
  cd ..
fi

# Lint files in the provider-ui directory
PROVIDER_STAGED=$(echo "$STAGED_FILES" | grep "^provider-ui/" || true)
if [ -n "$PROVIDER_STAGED" ] && [ -d "$PROVIDER_UI_DIR" ]; then
  if [ ! -f "$PROVIDER_UI_DIR/node_modules/.bin/eslint" ]; then
    echo -e "${YELLOW}ESLint not found in $PROVIDER_UI_DIR/node_modules. Run 'make provider-ui-setup' first.${NC}"
    exit 1
  fi

  echo "Linting provider-ui files..."
  PROVIDER_FILES=$(echo "$PROVIDER_STAGED" | sed 's|^provider-ui/||')
  cd "$PROVIDER_UI_DIR"
  if ! echo "$PROVIDER_FILES" | xargs ./node_modules/.bin/eslint --max-warnings=0; then
    echo -e "${RED}ESLint found errors in provider-ui files. Please fix them before committing.${NC}"
    cd ..
    exit 1
  fi
  cd ..
fi

echo -e "${GREEN}Frontend linting passed.${NC}"
exit 0
