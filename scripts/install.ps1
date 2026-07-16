param(
    [string]$SkillsDir = $env:DARGOJIAO_SKILLS_DIR
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($SkillsDir)) {
    $SkillsDir = Join-Path $HOME ".agents\skills"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $repoRoot "skills\dargojiao"
$target = Join-Path $SkillsDir "dargojiao"
$staging = Join-Path $SkillsDir (".dargojiao.install." + [guid]::NewGuid().ToString("N"))
$backup = Join-Path $SkillsDir (".dargojiao.backup." + [guid]::NewGuid().ToString("N"))

if (-not (Test-Path (Join-Path $sourceDir "SKILL.md") -PathType Leaf)) {
    throw "FAIL: Skill source not found: $sourceDir\SKILL.md"
}

New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
New-Item -ItemType Directory -Path $staging | Out-Null

try {
    Get-ChildItem -Force $sourceDir | Copy-Item -Destination $staging -Recurse -Force

    if (Test-Path $target) {
        Move-Item $target $backup
    }

    Move-Item $staging $target

    if (Test-Path $backup) {
        Remove-Item $backup -Recurse -Force
    }

    Write-Output "PASS: installed DargoJiao Skill at $target"
    Write-Output "Next: .\dargo.cmd doctor"
} catch {
    if (Test-Path $target) {
        Remove-Item $target -Recurse -Force
    }
    if (Test-Path $backup) {
        Move-Item $backup $target
    }
    throw
} finally {
    if (Test-Path $staging) {
        Remove-Item $staging -Recurse -Force
    }
}
