# DargoJiao v0.2.0 Windows Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the current workflow to DargoJiao and ship a native, CI-verified Windows PowerShell deployment path without adding a standalone AI runtime or notification dependency.

**Architecture:** Keep Codex Skill plus Scheduled tasks as the runtime. Add thin repository-local `dargo` launchers that only dispatch install, doctor, version, prompt, and help commands; retain Bash for macOS/Linux and add Windows PowerShell 5.1-compatible scripts. Treat Codex Scheduled results as the only run report and validate both platforms in GitHub Actions.

**Tech Stack:** Markdown, Bash, Windows PowerShell 5.1+, batch launcher, Python standard-library validation, GitHub Actions, Codex Skill, official `lark-cli`.

## Global Constraints

- Current product, repository, Skill, code, prompts, and documentation use `DargoJiao`, `dargojiao`, or `dargo` according to the naming table in the approved spec.
- Keep the existing v0.1.0 tag, release, and commit history; publish v0.2.0 without force-pushing.
- Native Windows 10/11 must work without WSL.
- Do not add npm, Cargo, PyPI, system-package, daemon, database, media downloader, FFmpeg, local speech model, or notification dependencies.
- Do not modify the user's system PATH.
- Use Codex Scheduled results as the only success and failure report; remove operating-system notifications and proactive Feishu group receipts.
- Never persist real Feishu identifiers, tenant URLs, local paths, proxy endpoints, cookies, tokens, or credentials in the repository or CI logs.
- A failed link, authorization, network, routing, write, or read-back check remains retryable and must not consume a note number or success marker.
- GitHub Actions Ubuntu and Windows jobs must pass before merging and publishing v0.2.0.

---

### Task 1: Rename the repository contract and Skill

**Files:**
- Modify: `tests/test_public_repo_hygiene.py`
- Modify: `tests/validate_repo.py`
- Move: `skills/dagojiao/` to `skills/dargojiao/`
- Modify: `skills/dargojiao/SKILL.md`
- Modify: `skills/dargojiao/agents/openai.yaml`
- Modify: `skills/dargojiao/templates/automation-prompt.md`
- Modify: `templates/automation-prompt.md`
- Modify: `templates/bootstrap-prompt.md`
- Modify: `scripts/install.sh`
- Modify: `scripts/doctor.sh`

**Interfaces:**
- Consumes: the v0.1.0 repository validator and Skill layout.
- Produces: Skill invocation `$dargojiao`, install root `${DARGOJIAO_SKILLS_DIR:-$HOME/.agents/skills}/dargojiao`, and a repository contract that rejects legacy current-tree naming and notification behavior.

- [ ] **Step 1: Write failing naming and notification tests**

Update the validator constants so the required Skill path is `skills/dargojiao`, markers include `name: dargojiao`, README heading is `# DargoJiao`, clone URL ends in `/DargoJiao.git`, and script markers use `DARGOJIAO_SKILLS_DIR`. Add current-tree forbidden literals for the legacy product heading, Skill frontmatter, invocation, and environment variable. Remove `macOS 通知中心` from required prompt markers and add forbidden notification terms:

```python
FORBIDDEN_CURRENT_TREE_TERMS = (
    "# DaGoJiao",
    "name: dagojiao",
    "$dagojiao",
    "DAGOJIAO_SKILLS_DIR",
    "macOS 通知中心",
    "Windows Toast",
    "发送简短群回执",
)

def test_current_tree_uses_dargojiao_naming() -> None:
    root = Path(__file__).parents[1]
    for path in _public_text_files(root):
        text = path.read_text(encoding="utf-8")
        for term in FORBIDDEN_CURRENT_TREE_TERMS:
            assert term not in text, f"{path.relative_to(root)} contains {term}"
```

Change `tests/validate_repo.py` success output to `DargoJiao repository validation passed`.

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
python3 -m unittest tests.test_public_repo_hygiene -v
```

Expected: FAIL because `skills/dargojiao/SKILL.md` is missing and current files still contain legacy names and notification text.

- [ ] **Step 3: Rename the Skill and remove notification behavior**

Move the Skill directory with `git mv`. Update all current files to the new product and Skill names. In both automation prompt copies, make preflight failures report only to Scheduled:

```markdown
2. 预检失败时，在 Codex「已安排」任务结果中以“⚠️ 短视频面试笔记执行异常”开头，写明时间、阶段、简要原因和用户动作。失败不能推进处理状态，也不能写入成功标识。
```

In `skills/dargojiao/SKILL.md`, make the final processing step:

```markdown
9. 在 Codex「已安排」任务结果中输出成功数、跳过数、待重试数、分类、异常阶段和用户动作。
```

Update Bash script paths and messages:

```bash
skills_root="${DARGOJIAO_SKILLS_DIR:-$HOME/.agents/skills}"
source_dir="$repo_root/skills/dargojiao"
target="$skills_root/dargojiao"
```

- [ ] **Step 4: Verify GREEN**

Run:

```bash
python3 -m unittest tests.test_public_repo_hygiene -v
python3 tests/validate_repo.py
cmp skills/dargojiao/templates/automation-prompt.md templates/automation-prompt.md
git diff --check
```

Expected: all commands exit 0 and validation prints `DargoJiao repository validation passed`.

- [ ] **Step 5: Commit**

```bash
git add tests skills templates scripts
git commit -m "refactor: rename workflow to DargoJiao"
```

### Task 2: Add the POSIX `dargo` command

**Files:**
- Create: `dargo`
- Create: `tests/test_dargo_cli.py`
- Modify: `tests/test_public_repo_hygiene.py`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: `scripts/install.sh`, `scripts/doctor.sh`, and `templates/bootstrap-prompt.md`.
- Produces: executable `./dargo {install|doctor|version|prompt|help}` with exit code 2 for unknown commands.

- [ ] **Step 1: Write failing CLI tests**

Create standard-library subprocess tests:

```python
from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]
DARGO = ROOT / "dargo"


class DargoCliTests(unittest.TestCase):
    def run_dargo(self, *args: str, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(DARGO), *args],
            cwd=ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    def test_version(self) -> None:
        result = self.run_dargo("version")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout.strip(), "DargoJiao v0.2.0")

    def test_prompt_points_to_skill(self) -> None:
        result = self.run_dargo("prompt")
        self.assertEqual(result.returncode, 0)
        self.assertIn("$dargojiao", result.stdout)
        self.assertIn("templates/bootstrap-prompt.md", result.stdout)

    def test_unknown_command_fails(self) -> None:
        result = self.run_dargo("unknown")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)

    def test_install_is_idempotent_in_temporary_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            env = os.environ.copy()
            env["DARGOJIAO_SKILLS_DIR"] = temporary
            first = self.run_dargo("install", env=env)
            second = self.run_dargo("install", env=env)
            self.assertEqual(first.returncode, 0)
            self.assertEqual(second.returncode, 0)
            self.assertTrue((Path(temporary) / "dargojiao" / "SKILL.md").is_file())


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
python3 -m unittest tests.test_dargo_cli -v
```

Expected: ERROR or FAIL because the `dargo` executable does not exist.

- [ ] **Step 3: Implement the thin Bash dispatcher**

Create an executable Bash script with strict mode and no external runtime dependency:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command_name="${1:-help}"

usage() {
  printf 'Usage: ./dargo {install|doctor|version|prompt|help}\n'
}

case "$command_name" in
  install) exec "$repo_root/scripts/install.sh" ;;
  doctor) exec "$repo_root/scripts/doctor.sh" ;;
  version) printf 'DargoJiao v0.2.0\n' ;;
  prompt)
    printf 'Use $dargojiao in Codex. Bootstrap prompt: templates/bootstrap-prompt.md\n'
    ;;
  help|-h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
```

Make it executable and extend the repository validator to require that bit.

- [ ] **Step 4: Verify GREEN**

Run:

```bash
chmod +x dargo scripts/install.sh scripts/doctor.sh
python3 -m unittest tests.test_dargo_cli -v
bash -n dargo scripts/install.sh scripts/doctor.sh
```

Expected: all four CLI tests pass and Bash syntax exits 0.

- [ ] **Step 5: Commit**

```bash
git add dargo tests .gitignore scripts
git commit -m "feat: add dargo command for POSIX"
```

### Task 3: Add native Windows PowerShell deployment

**Files:**
- Create: `scripts/install.ps1`
- Create: `scripts/doctor.ps1`
- Create: `scripts/dargo.ps1`
- Create: `dargo.cmd`
- Create: `tests/test_windows_scripts.ps1`
- Modify: `tests/test_public_repo_hygiene.py`

**Interfaces:**
- Consumes: `skills/dargojiao`, `templates/bootstrap-prompt.md`, and optional `DARGOJIAO_SKILLS_DIR`.
- Produces: `.\dargo.cmd {install|doctor|version|prompt|help}`, PowerShell install rollback, and diagnostic exit status 0 only when required checks pass.

- [ ] **Step 1: Write failing Windows file and marker tests**

Add required files and script contracts to the Python validator:

```python
WINDOWS_INSTALL_MARKERS = (
    "$ErrorActionPreference = \"Stop\"",
    "DARGOJIAO_SKILLS_DIR",
    ".agents",
    "dargojiao",
    "Move-Item",
)

WINDOWS_DOCTOR_MARKERS = (
    "Get-Command",
    "lark-cli auth status --json --verify",
    "DARGOJIAO_SKILLS_DIR",
    "PASS",
    "WARN",
    "FAIL",
)
```

Add `scripts/install.ps1`, `scripts/doctor.ps1`, `scripts/dargo.ps1`, `dargo.cmd`, and `tests/test_windows_scripts.ps1` to required files.

- [ ] **Step 2: Run validator and verify RED**

Run:

```bash
python3 tests/validate_repo.py
```

Expected: FAIL listing the missing Windows files.

- [ ] **Step 3: Implement PowerShell 5.1-compatible scripts**

`scripts/install.ps1` must:

```powershell
param([string]$SkillsDir = $env:DARGOJIAO_SKILLS_DIR)
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SkillsDir)) {
    $SkillsDir = Join-Path $HOME ".agents\skills"
}
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot "skills\dargojiao"
$target = Join-Path $SkillsDir "dargojiao"
$staging = Join-Path $SkillsDir (".dargojiao.install." + [guid]::NewGuid().ToString("N"))
$backup = Join-Path $SkillsDir (".dargojiao.backup." + [guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
New-Item -ItemType Directory -Path $staging | Out-Null
try {
    Get-ChildItem -Force $sourceDir | Copy-Item -Destination $staging -Recurse -Force
    if (Test-Path $target) { Move-Item $target $backup }
    Move-Item $staging $target
    if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
    Write-Output "PASS: installed DargoJiao Skill at $target"
} catch {
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    if (Test-Path $backup) { Move-Item $backup $target }
    throw
} finally {
    if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
}
```

`scripts/doctor.ps1` uses `Get-Command` for Git, Codex, Node/npm, and `lark-cli`; invokes `lark-cli auth status --json --verify` without printing JSON; checks the installed Skill and current directory; reports proxy presence as PASS or WARN; and exits 1 when required checks fail.

`scripts/dargo.ps1` dispatches the five commands and exits 2 for an unknown command. `dargo.cmd` contains:

```batch
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\dargo.ps1" %*
exit /b %ERRORLEVEL%
```

- [ ] **Step 4: Add the Windows smoke test**

Create a PowerShell test that installs twice into `$env:RUNNER_TEMP` or a generated temp directory, checks `SKILL.md`, verifies `version`, `prompt`, and unknown-command status, adds temporary `codex.cmd` and `lark-cli.cmd` command shims to PATH, and runs `doctor` without accessing real credentials.

- [ ] **Step 5: Verify locally available checks**

Run:

```bash
python3 tests/validate_repo.py
git diff --check
```

If `pwsh` is available, also run:

```bash
pwsh -NoProfile -File tests/test_windows_scripts.ps1
```

Expected: local validator passes. If PowerShell is unavailable on macOS, record that Windows execution remains gated by the Windows CI job rather than claiming local execution.

- [ ] **Step 6: Commit**

```bash
git add scripts dargo.cmd tests
git commit -m "feat: add native Windows deployment"
```

### Task 4: Write complete cross-platform, proxy, and Feishu link documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/feishu-setup.md`
- Modify: `docs/codex-automation.md`
- Modify: `docs/permissions.md`
- Modify: `docs/security.md`
- Modify: `docs/troubleshooting.md`
- Modify: `templates/setup-checklist.md`
- Modify: `skills/dargojiao/references/troubleshooting.md`
- Modify: `tests/test_public_repo_hygiene.py`

**Interfaces:**
- Consumes: the new `dargo` and `dargo.cmd` commands.
- Produces: copyable macOS/Linux and native Windows setup paths, proxy diagnostics, Wiki/Docx link rules, permission checks, and first-run acceptance instructions.

- [ ] **Step 1: Write failing documentation markers**

Require these current README sections and commands:

```python
README_MARKERS = (
    "# DargoJiao",
    "## Windows 原生部署",
    "## macOS 与 Linux 部署",
    "## 代理与网络",
    "## 飞书群与知识库链接",
    ".\\dargo.cmd install",
    ".\\dargo.cmd doctor",
    "./dargo install",
    "./dargo doctor",
    "Get-ChildItem Env:HTTP_PROXY,Env:HTTPS_PROXY",
    "netsh winhttp show proxy",
    "Test-NetConnection open.feishu.cn -Port 443",
    "lark-cli auth status --json --verify",
    "$dargojiao",
    "Wiki",
    "Docx",
    "Codex「已安排」",
)
```

- [ ] **Step 2: Run validator and verify RED**

Run `python3 tests/validate_repo.py`.

Expected: FAIL with missing Windows, proxy, and Feishu-link README markers.

- [ ] **Step 3: Rewrite README setup flow**

Make Windows native the first complete platform-specific path. Use official installation commands:

```powershell
winget install --id 9PLM9XGG6VKS -s msstore
winget install --id Git.Git
winget install --id OpenJS.NodeJS.LTS
npx @larksuite/cli@latest install
lark-cli config init --new
lark-cli auth login --recommend
lark-cli auth status --json --verify
git clone https://github.com/suyirui15522486726-prog/DargoJiao.git
cd DargoJiao
.\dargo.cmd install
.\dargo.cmd doctor
```

Document that the machine must remain awake and Codex Desktop must remain running for local scheduled tasks.

- [ ] **Step 4: Document proxy and link diagnostics**

Explain separately the Codex/OpenAI, GitHub/npm, Feishu OAuth/API, and short-video redirect paths. Include only placeholder proxy values and these read-only commands:

```powershell
Get-ChildItem Env:HTTP_PROXY,Env:HTTPS_PROXY -ErrorAction SilentlyContinue
netsh winhttp show proxy
Test-NetConnection github.com -Port 443
Test-NetConnection open.feishu.cn -Port 443
lark-cli auth status --json --verify
```

Explain how to copy a full Wiki or Docx URL, how to distinguish API scopes from knowledge-space membership, why screenshots/titles are insufficient, and why failures remain retryable.

- [ ] **Step 5: Update all supporting docs and verify GREEN**

Remove system-notification guidance everywhere and align setup checklist and troubleshooting with Scheduled results. Run:

```bash
python3 tests/validate_repo.py
python3 -m unittest discover -s tests -p 'test_*.py' -v
rg -n 'macOS 通知|Windows Toast|发送简短群回执' README.md docs skills templates scripts dargo dargo.cmd
git diff --check
```

Expected: tests pass and `rg` returns no matches.

- [ ] **Step 6: Commit**

```bash
git add README.md docs templates skills tests
git commit -m "docs: add Windows deployment and network guide"
```

### Task 5: Add lightweight Ubuntu and Windows CI

**Files:**
- Create: `.github/workflows/ci.yml`
- Modify: `tests/test_public_repo_hygiene.py`

**Interfaces:**
- Consumes: Python validator, Bash scripts, PowerShell scripts, and platform smoke tests.
- Produces: required `ubuntu` and `windows` jobs on pushes and pull requests.

- [ ] **Step 1: Write a failing workflow contract**

Require `.github/workflows/ci.yml` and assert it contains `ubuntu-latest`, `windows-latest`, `tests/validate_repo.py`, `test_windows_scripts.ps1`, and `test_dargo_cli`.

- [ ] **Step 2: Run validator and verify RED**

Run `python3 tests/validate_repo.py`.

Expected: FAIL because `.github/workflows/ci.yml` is missing.

- [ ] **Step 3: Create the workflow**

```yaml
name: CI

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  ubuntu:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: python tests/validate_repo.py
      - run: python -m unittest discover -s tests -p 'test_*.py' -v
      - run: bash -n dargo scripts/install.sh scripts/doctor.sh

  windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: python tests/validate_repo.py
      - shell: powershell
        run: .\tests\test_windows_scripts.ps1
```

- [ ] **Step 4: Verify GREEN locally**

Run:

```bash
python3 tests/validate_repo.py
python3 -m unittest discover -s tests -p 'test_*.py' -v
bash -n dargo scripts/install.sh scripts/doctor.sh
git diff --check
```

Expected: all local checks pass.

- [ ] **Step 5: Commit**

```bash
git add .github tests
git commit -m "ci: verify DargoJiao on Ubuntu and Windows"
```

### Task 6: Validate, publish through PR, rename the repository, and release v0.2.0

**Files:**
- Verify: all tracked files
- External: GitHub repository metadata, pull request, Actions runs, tag, and Release
- Local move: `outputs/DaGoJiao` to `outputs/DargoJiao` after all Git operations are clean

**Interfaces:**
- Consumes: completed feature branch and passing local tests.
- Produces: public `suyirui15522486726-prog/DargoJiao`, merged `main`, retained v0.1.0, and published v0.2.0.

- [ ] **Step 1: Run the complete local release gate**

```bash
python3 tests/validate_repo.py
python3 -m unittest discover -s tests -p 'test_*.py' -v
bash -n dargo scripts/install.sh scripts/doctor.sh
cmp skills/dargojiao/templates/automation-prompt.md templates/automation-prompt.md
git diff --check
git status --short
```

Expected: all checks exit 0 and Git status is clean.

- [ ] **Step 2: Push the feature branch and open a PR**

```bash
git push -u origin feat/windows-support
gh pr create --repo suyirui15522486726-prog/DaGoJiao --base main --head feat/windows-support --title "feat: add native Windows support" --body "Adds the DargoJiao rename, native PowerShell deployment, lightweight dargo commands, proxy and Feishu-link guidance, and Ubuntu/Windows CI."
```

- [ ] **Step 3: Wait for Ubuntu and Windows checks**

```bash
gh pr checks --watch --repo suyirui15522486726-prog/DaGoJiao
```

Expected: both jobs complete successfully. If Windows fails, inspect logs, reproduce with the smallest change, add or adjust a failing test, push, and wait again.

- [ ] **Step 4: Merge the passing PR**

```bash
gh pr merge --squash --delete-branch --repo suyirui15522486726-prog/DaGoJiao
git switch main
git pull --ff-only origin main
```

- [ ] **Step 5: Rename the GitHub repository and update the remote**

```bash
gh api --method PATCH repos/suyirui15522486726-prog/DaGoJiao -f name=DargoJiao
git remote set-url origin https://github.com/suyirui15522486726-prog/DargoJiao.git
gh repo view suyirui15522486726-prog/DargoJiao --json name,visibility,url,defaultBranchRef
```

Expected: public repository name is `DargoJiao` and default branch is `main`.

- [ ] **Step 6: Verify v0.1.0 remains and publish v0.2.0**

```bash
gh release view v0.1.0 --repo suyirui15522486726-prog/DargoJiao
git tag -a v0.2.0 -m "DargoJiao v0.2.0"
git push origin v0.2.0
gh release create v0.2.0 --repo suyirui15522486726-prog/DargoJiao --title "DargoJiao v0.2.0" --notes "Adds native Windows PowerShell deployment, the lightweight dargo command, cross-platform CI, and complete proxy and Feishu-link guidance."
```

- [ ] **Step 7: Audit the published artifact**

Clone the renamed repository into a temporary directory, rerun the Python validator, verify only `main` is published, verify both releases exist, and search the current tree for forbidden legacy names, private identifiers, notification terms, and real proxy endpoints.

- [ ] **Step 8: Rename the local checkout directory**

From the parent directory after confirming a clean checkout:

```bash
mv DaGoJiao DargoJiao
```

Verify the moved checkout still has `origin` pointing to the renamed public repository.

