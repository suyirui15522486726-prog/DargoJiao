#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_root="${DAGOJIAO_SKILLS_DIR:-$HOME/.agents/skills}"
source_dir="$repo_root/skills/dagojiao"
target="$skills_root/dagojiao"

if [[ ! -f "$source_dir/SKILL.md" ]]; then
  printf 'FAIL: Skill source not found: %s\n' "$source_dir/SKILL.md" >&2
  exit 1
fi

mkdir -p "$skills_root"
staging="$(mktemp -d "$skills_root/.dagojiao.install.XXXXXX")"
backup="$skills_root/.dagojiao.backup.$$"

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
  printf 'FAIL: unable to install DaGoJiao Skill\n' >&2
  exit 1
fi

trap - EXIT
printf 'PASS: installed DaGoJiao Skill at %s\n' "$target"
printf 'Next: ./scripts/doctor.sh\n'
