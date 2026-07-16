#!/usr/bin/env bash
set -euo pipefail

skills_root="${DARGOJIAO_SKILLS_DIR:-$HOME/.agents/skills}"
failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

warn() {
  printf 'WARN: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

if command -v git >/dev/null 2>&1; then
  pass "Git is available"
else
  fail "Git is missing"
fi

if command -v codex >/dev/null 2>&1; then
  pass "Codex CLI is available"
else
  fail "Codex CLI is missing; install or update Codex Desktop"
fi

if command -v lark-cli >/dev/null 2>&1; then
  pass "lark-cli is available"
  if lark-cli auth status --json --verify >/dev/null 2>&1; then
    pass "Feishu user authorization is valid"
  else
    fail "Feishu authorization is missing or expired; run lark-cli auth login --recommend"
  fi
else
  fail "lark-cli is missing"
fi

if [[ -f "$skills_root/dargojiao/SKILL.md" ]]; then
  pass "DargoJiao Skill is installed"
else
  fail "DargoJiao Skill is not installed; run ./scripts/install.sh"
fi

if [[ -r . ]]; then
  pass "Current project directory is readable"
else
  fail "Current project directory is not readable"
fi

if [[ -n "${HTTPS_PROXY:-${https_proxy:-}}" ]]; then
  pass "A shell HTTPS proxy is configured"
else
  warn "No shell HTTPS proxy detected; system proxy may still be active"
fi

warn "Short-video pages can still be temporarily unavailable; DargoJiao will keep them retryable"

if ((failures > 0)); then
  printf 'FAIL: %d required check(s) failed\n' "$failures" >&2
  exit 1
fi

pass "DargoJiao environment is ready"
