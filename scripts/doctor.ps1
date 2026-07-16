param(
    [string]$SkillsDir = $env:DARGOJIAO_SKILLS_DIR
)

$ErrorActionPreference = "Stop"
$failures = 0

if ([string]::IsNullOrWhiteSpace($SkillsDir)) {
    $SkillsDir = Join-Path $HOME ".agents\skills"
}

function Write-Pass([string]$Message) {
    Write-Output "PASS: $Message"
}

function Write-Warn([string]$Message) {
    Write-Output "WARN: $Message"
}

function Write-Fail([string]$Message) {
    Write-Error "FAIL: $Message" -ErrorAction Continue
    $script:failures += 1
}

function Assert-RequiredCommand([string]$Name, [string]$Label) {
    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        Write-Pass "$Label is available"
        return
    }

    Write-Fail "$Label is missing"
}

Assert-RequiredCommand "git" "Git"
Assert-RequiredCommand "codex" "Codex CLI"
Assert-RequiredCommand "node" "Node.js"
Assert-RequiredCommand "npm" "npm"

if (Get-Command "lark-cli" -ErrorAction SilentlyContinue) {
    Write-Pass "lark-cli is available"
    # Keep this command explicit for diagnostics and documentation: auth status --json --verify
    & lark-cli auth status --json --verify *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "Feishu user authorization is valid"
    } else {
        Write-Fail "Feishu authorization is missing or expired; run lark-cli auth login --recommend"
    }
} else {
    Write-Fail "lark-cli is missing"
}

$skillFile = Join-Path $SkillsDir "dargojiao\SKILL.md"
if (Test-Path $skillFile -PathType Leaf) {
    Write-Pass "DargoJiao Skill is installed"
} else {
    Write-Fail "DargoJiao Skill is not installed; run .\dargo.cmd install"
}

if (Test-Path (Get-Location)) {
    Write-Pass "Current project directory is readable"
} else {
    Write-Fail "Current project directory is not readable"
}

if ($env:HTTPS_PROXY -or $env:https_proxy -or $env:HTTP_PROXY -or $env:http_proxy) {
    Write-Pass "A shell HTTP(S) proxy is configured"
} else {
    Write-Warn "No shell proxy detected; the Windows system proxy may still be active"
}

Write-Warn "Short-video pages can still be temporarily unavailable; DargoJiao keeps them retryable"

if ($failures -gt 0) {
    Write-Error "FAIL: $failures required check(s) failed" -ErrorAction Continue
    exit 1
}

Write-Pass "DargoJiao environment is ready"
exit 0
