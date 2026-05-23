#!/usr/bin/env bash
# lint-go.sh — Pre-commit hook to run Go linting checks
# Runs golangci-lint (if available) or falls back to go vet on staged .go files.
# Part of the Meshery agent hooks collection.

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Colour

info()  { echo -e "${GREEN}[lint-go]${NC} $*"; }
warn()  { echo -e "${YELLOW}[lint-go]${NC} $*"; }
error() { echo -e "${RED}[lint-go]${NC} $*" >&2; }

# ── Collect staged Go files ───────────────────────────────────────────────────
STAGED_GO_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.go$' || true)

if [[ -z "$STAGED_GO_FILES" ]]; then
  info "No staged Go files — skipping lint."
  exit 0
fi

info "Staged Go files detected:"
echo "$STAGED_GO_FILES" | sed 's/^/  /'

# ── Derive unique packages from staged files ─────────────────────────────────
# go vet / golangci-lint operate on packages, not individual files.
PACKAGES=$(echo "$STAGED_GO_FILES" | xargs -I{} dirname {} | sort -u | sed 's|^|./|')

# ── Prefer golangci-lint when available ──────────────────────────────────────
if command -v golangci-lint &>/dev/null; then
  info "Running golangci-lint …"
  # Limit to only the packages touched by this commit for speed.
  # shellcheck disable=SC2086
  if ! golangci-lint run --new-from-rev=HEAD $PACKAGES; then
    error "golangci-lint reported issues. Please fix them before committing."
    exit 1
  fi
  info "golangci-lint passed."
  exit 0
fi

# ── Fallback: go vet ──────────────────────────────────────────────────────────
if command -v go &>/dev/null; then
  warn "golangci-lint not found — falling back to 'go vet'."
  warn "Install golangci-lint for richer checks: https://golangci-lint.run/usage/install/"

  FAILED=0
  while IFS= read -r pkg; do
    info "go vet $pkg"
    if ! go vet "$pkg" 2>&1; then
      FAILED=1
    fi
  done <<< "$PACKAGES"

  if [[ "$FAILED" -ne 0 ]]; then
    error "'go vet' reported issues. Please fix them before committing."
    exit 1
  fi

  info "go vet passed."
  exit 0
fi

# ── Neither tool available ────────────────────────────────────────────────────
warn "Neither golangci-lint nor go is available on PATH — skipping Go lint."
warn "Ensure your Go toolchain is installed and in PATH."
exit 0
