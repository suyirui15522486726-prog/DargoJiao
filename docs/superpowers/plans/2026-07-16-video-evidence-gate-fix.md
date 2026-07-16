# DargoJiao Video Evidence Gate Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent normal short-video shares from being rejected only because the public page lacks正文或字幕，同时保留身份、题目、技术事实和写入失败时的补处理语义。

**Architecture:** Keep DargoJiao as a prompt-driven Codex Skill. Split the workflow contract into three gates—work identity, topic recognition, and answer evidence—then enforce the contract with repository marker tests and synchronize the same wording to the real Codex automation.

**Tech Stack:** Markdown Skill files, Python `unittest`, repository validator, Codex automation, GitHub Actions on Ubuntu and Windows.

## Global Constraints

- Do not add media downloaders, FFmpeg, local speech models, databases, daemons, or third-party content parsing services.
- A missing public-page body or transcript alone must not produce `待重试`.
- Only a successful write followed by read-back verification may create success markers.
- Keep `automation-2` active on weekdays at 09:30 with OneCoupon `main` and a seven-day lookback.

---

### Task 1: Add the regression contract

**Files:**
- Modify: `tests/test_public_repo_hygiene.py`
- Test: `tests/test_public_repo_hygiene.py`

**Interfaces:**
- Consumes: `validate(root: Path) -> list[str]`
- Produces: required workflow markers checked in the public automation template and Skill

- [ ] **Step 1: Write the failing test markers**

Add required markers for `作品身份`, `公开页缺少正文或字幕本身不能成为待重试理由`, `反例归纳`, `技术事实`, and the four remaining retry conditions.

- [ ] **Step 2: Run the validator and verify RED**

Run: `python3 tests/validate_repo.py`

Expected: FAIL because the current Skill and prompt still say that missing page evidence is enough to retry.

- [ ] **Step 3: Commit the regression contract together with the minimal rule fix**

Stage only the test and rule files after Task 2 turns the test green.

### Task 2: Implement the three-gate workflow rule

**Files:**
- Modify: `skills/dargojiao/SKILL.md`
- Modify: `skills/dargojiao/references/note-format.md`
- Modify: `skills/dargojiao/references/troubleshooting.md`
- Modify: `templates/automation-prompt.md`
- Modify: `skills/dargojiao/templates/automation-prompt.md`

**Interfaces:**
- Consumes: platform video ID, share author/title/topic, optional正文/字幕/可信镜像, optional local Git evidence
- Produces: `success`, `skip`, or `retry` with explicit reasons and provenance-safe note wording

- [ ] **Step 1: Replace the coupled evidence gate**

State that a resolved platform work ID plus a clear interview title enters note generation. Treat正文/字幕 as enhancement, not identity proof.

- [ ] **Step 2: Preserve content honesty**

Require “错误答题（反例归纳）” and “基于分享题目与技术事实整理” whenever video wording cannot be verified.

- [ ] **Step 3: Define remaining retry conditions**

Retry only for missing work identity, unclear topic, metadata conflict, unverifiable technical facts, authorization/network/write/read-back failures.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `python3 tests/validate_repo.py && python3 -m unittest discover -s tests -p 'test_*.py' -v`

Expected: validator passes and all tests report `OK`.

### Task 3: Update public guidance and the live automation

**Files:**
- Modify: `README.md`
- Modify: `docs/codex-automation.md`
- Modify: `docs/security.md`
- Modify: `docs/troubleshooting.md`
- Update through Codex: `$CODEX_HOME/automations/automation-2/automation.toml`

**Interfaces:**
- Consumes: the three-gate workflow contract from Task 2
- Produces: consistent user documentation and an active scheduled prompt

- [ ] **Step 1: Update user-facing retry explanations**

Document that missing正文/字幕 alone is not a failure and list the actual retry reasons.

- [ ] **Step 2: Update `automation-2` through `automation_update`**

Preserve its name, active status, model, schedule, project, Git ref, timezone and lookback window. Replace only the workflow prompt.

- [ ] **Step 3: Verify the live automation**

Parse its TOML and assert the schedule, project, `$dargojiao`, new evidence rule, and absence of old proactive notification actions.

### Task 4: Publish and verify

**Files:**
- No additional source files

**Interfaces:**
- Consumes: tested branch
- Produces: merged GitHub change with green Ubuntu and Windows checks

- [ ] **Step 1: Run the full local suite**

Run repository validation, all Python tests, Bash syntax checks, template comparison and `git diff --check`.

- [ ] **Step 2: Commit and push the scoped branch**

Use branch `agent/fix-video-evidence-gate` and a terse fix commit.

- [ ] **Step 3: Open a GitHub pull request**

Describe root cause, behavior change, safety boundary and validation evidence.

- [ ] **Step 4: Wait for Ubuntu and Windows checks and merge**

Do not merge unless both jobs complete successfully.

- [ ] **Step 5: Verify merged `main` and reinstall the Skill**

Confirm the remote head, run `./dargo install` and `./dargo doctor`, and re-check `automation-2`.

- [ ] **Step 6: Publish patch release `v0.2.1`**

Tag the verified merge commit, publish release notes describing the evidence-gate fix, and confirm `v0.1.0` and `v0.2.0` remain available.
