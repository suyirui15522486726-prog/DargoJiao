from __future__ import annotations

import re
import stat
from pathlib import Path


REQUIRED_FILES = (
    "README.md",
    "LICENSE",
    ".gitignore",
    "skills/dagojiao/SKILL.md",
    "skills/dagojiao/agents/openai.yaml",
    "skills/dagojiao/references/note-format.md",
    "skills/dagojiao/references/deduplication.md",
    "skills/dagojiao/references/troubleshooting.md",
    "skills/dagojiao/templates/automation-prompt.md",
    "templates/automation-prompt.md",
    "templates/bootstrap-prompt.md",
    "templates/setup-checklist.md",
    "docs/feishu-setup.md",
    "docs/codex-automation.md",
    "docs/permissions.md",
    "docs/security.md",
    "docs/troubleshooting.md",
    "scripts/install.sh",
    "scripts/doctor.sh",
)

IGNORED_SCAN_PARTS = {".git", "tests", "__pycache__"}

FORBIDDEN_PATTERNS = (
    ("personal absolute path", re.compile(r"/Users/[A-Za-z0-9._-]+/")),
    ("Feishu chat or user id", re.compile(r"\b(?:oc|ou)_[A-Za-z0-9]{16,}\b")),
    ("Feishu document token", re.compile(r"\b(?:wikcn|docxcn)[A-Za-z0-9]{12,}\b")),
    ("localhost proxy port", re.compile(r"127\.0\.0\.1:\d{4,5}")),
    ("GitHub or OAuth token", re.compile(r"\b(?:gh[opusr]_|Bearer\s+)[A-Za-z0-9_-]{20,}")),
    ("private key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----")),
    (
        "tenant-specific Feishu URL",
        re.compile(r"https://[A-Za-z0-9.-]+\.feishu\.cn/(?:wiki|docx)/", re.IGNORECASE),
    ),
)

SKILL_MARKERS = (
    "name: dagojiao",
    "description: Use when",
    "references/note-format.md",
    "references/deduplication.md",
    "references/troubleshooting.md",
    "templates/automation-prompt.md",
    "lark-im",
    "lark-wiki",
    "lark-doc",
    "lark-shared",
    "automation_update",
)

PROMPT_MARKERS = (
    "{{FEISHU_CHAT_NAME}}",
    "{{FEISHU_WIKI_URL}}",
    "{{LOCAL_PROJECT_PATH}}",
    "{{GIT_REF}}",
    "{{TIMEZONE}}",
    "{{LOOKBACK_DAYS}}",
    "svnote-msg:<message_id>",
    "证据不足",
    "待重试",
    "结合项目谈一谈",
    "Codex 已安排",
    "macOS 通知中心",
    "工作日",
    "回读验证",
)

FORBIDDEN_DEFAULT_RUNTIME_TERMS = (
    "yt-dlp",
    "ffmpeg",
    "whisper",
    "cookies-from-browser",
    "第三方解析 API",
)

README_MARKERS = (
    "# DaGoJiao",
    "## 前置条件",
    "## 五分钟开始",
    "## 飞书授权",
    "## 创建自动化",
    "## 首次验收",
    "## 去重机制",
    "## 异常通知",
    "## 安全",
    "## 故障排查",
    "## 卸载",
    "## 升级",
    "git clone https://github.com/suyirui15522486726-prog/DaGoJiao.git",
    "./scripts/install.sh",
    "./scripts/doctor.sh",
    "$dagojiao",
)

INSTALL_MARKERS = (
    "set -euo pipefail",
    "DAGOJIAO_SKILLS_DIR",
    "$HOME/.agents/skills",
    "./scripts/doctor.sh",
)

DOCTOR_MARKERS = (
    "set -euo pipefail",
    "command -v git",
    "command -v codex",
    "command -v lark-cli",
    "lark-cli auth status --json --verify",
    "$HOME/.agents/skills",
    "PASS",
    "WARN",
    "FAIL",
)


def _public_text_files(root: Path) -> list[Path]:
    return [
        path
        for path in root.rglob("*")
        if path.is_file()
        and not any(part in IGNORED_SCAN_PARTS for part in path.relative_to(root).parts)
    ]


def validate(root: Path) -> list[str]:
    errors: list[str] = []

    for relative in REQUIRED_FILES:
        if not (root / relative).is_file():
            errors.append(f"missing required file: {relative}")

    for path in _public_text_files(root):
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        relative = path.relative_to(root)
        for label, pattern in FORBIDDEN_PATTERNS:
            if pattern.search(content):
                errors.append(f"{relative}: contains {label}")

    skill_path = root / "skills/dagojiao/SKILL.md"
    if skill_path.is_file():
        skill_text = skill_path.read_text(encoding="utf-8")
        for marker in SKILL_MARKERS:
            if marker not in skill_text:
                errors.append(f"skills/dagojiao/SKILL.md: missing marker {marker}")

    prompt_path = root / "templates/automation-prompt.md"
    if prompt_path.is_file():
        prompt_text = prompt_path.read_text(encoding="utf-8")
        for marker in PROMPT_MARKERS:
            if marker not in prompt_text:
                errors.append(f"templates/automation-prompt.md: missing marker {marker}")
        lowered = prompt_text.lower()
        for term in FORBIDDEN_DEFAULT_RUNTIME_TERMS:
            if term.lower() in lowered:
                errors.append(f"templates/automation-prompt.md: forbidden runtime term {term}")

    bundled_prompt = root / "skills/dagojiao/templates/automation-prompt.md"
    if prompt_path.is_file() and bundled_prompt.is_file():
        if prompt_path.read_bytes() != bundled_prompt.read_bytes():
            errors.append("automation prompt copies differ")

    readme_path = root / "README.md"
    if readme_path.is_file():
        readme_text = readme_path.read_text(encoding="utf-8")
        for marker in README_MARKERS:
            if marker not in readme_text:
                errors.append(f"README.md: missing marker {marker}")

    script_contracts = {
        "scripts/install.sh": INSTALL_MARKERS,
        "scripts/doctor.sh": DOCTOR_MARKERS,
    }
    for relative, markers in script_contracts.items():
        script_path = root / relative
        if not script_path.is_file():
            continue
        script_text = script_path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in script_text:
                errors.append(f"{relative}: missing marker {marker}")
        if not script_path.stat().st_mode & stat.S_IXUSR:
            errors.append(f"{relative}: is not executable")

    return errors


def test_public_repository_contract() -> None:
    assert validate(Path(__file__).parents[1]) == []
