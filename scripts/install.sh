#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_root="${DARGOJIAO_SKILLS_DIR:-$HOME/.agents/skills}"
source_dir="$repo_root/skills/dargojiao"
target="$skills_root/dargojiao"

if [[ ! -f "$source_dir/SKILL.md" ]]; then
  printf 'FAIL: Skill source not found: %s\n' "$source_dir/SKILL.md" >&2
  exit 1
fi

mkdir -p "$skills_root"
staging="$(mktemp -d "$skills_root/.dargojiao.install.XXXXXX")"
backup="$skills_root/.dargojiao.backup.$$"

cleanup() {
  rm -rf "$staging"
}
trap cleanup EXIT

cp -R "$source_dir/." "$staging/"

if [[ -e "$target" ]]; then
  mv "$target" "$backup"
fi

if mv "$staging" "$target"; then
  rm -rf "$backup"
else
  if [[ -e "$backup" ]]; then
    mv "$backup" "$target"
  fi
  printf 'FAIL: unable to install DargoJiao Skill\n' >&2
  exit 1
fi

trap - EXIT
printf 'PASS: installed DargoJiao Skill at %s\n' "$target"
printf 'Next: ./scripts/doctor.sh\n'
