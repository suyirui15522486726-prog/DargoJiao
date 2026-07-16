$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("dargojiao-test-" + [guid]::NewGuid().ToString("N"))
$skillsRoot = Join-Path $temporaryRoot "skills"
$shimRoot = Join-Path $temporaryRoot "bin"
$originalPath = $env:PATH
$originalSkillsDir = $env:DARGOJIAO_SKILLS_DIR
$originalHttpsProxy = $env:HTTPS_PROXY

function Assert-Equal($Expected, $Actual, [string]$Message) {
    if ($Expected -ne $Actual) {
        throw "$Message. Expected: $Expected; Actual: $Actual"
    }
}

function Invoke-Dargo([string]$CommandName) {
    & (Join-Path $repoRoot "dargo.cmd") $CommandName | Out-Host
    $exitCode = $LASTEXITCODE
    return [int]$exitCode
}

try {
    New-Item -ItemType Directory -Force -Path $shimRoot | Out-Null
    $env:DARGOJIAO_SKILLS_DIR = $skillsRoot

    Assert-Equal 0 (Invoke-Dargo "install") "First install failed"
    Assert-Equal 0 (Invoke-Dargo "install") "Second install failed"
    if (-not (Test-Path (Join-Path $skillsRoot "dargojiao\SKILL.md") -PathType Leaf)) {
        throw "Installed SKILL.md is missing"
    }

    $version = & (Join-Path $repoRoot "dargo.cmd") version
    Assert-Equal 0 $LASTEXITCODE "Version command failed"
    Assert-Equal "DargoJiao v0.2.0" ($version | Select-Object -Last 1) "Unexpected version"

    $prompt = & (Join-Path $repoRoot "dargo.cmd") prompt
    Assert-Equal 0 $LASTEXITCODE "Prompt command failed"
    if (($prompt -join "`n") -notmatch '\$dargojiao') {
        throw "Prompt command does not mention the Skill"
    }

    foreach ($commandName in @("git", "codex", "node", "npm", "lark-cli")) {
        "@echo off`r`nexit /b 0`r`n" | Set-Content -Encoding Ascii (Join-Path $shimRoot "$commandName.cmd")
    }
    $env:PATH = "$shimRoot;$originalPath"
    $env:HTTPS_PROXY = "https://proxy.invalid:443"

    Assert-Equal 0 (Invoke-Dargo "doctor") "Doctor command failed"

    Remove-Item (Join-Path $shimRoot "lark-cli.cmd") -Force
    $windowsPowerShell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0"
    $system32 = Join-Path $env:SystemRoot "System32"
    $env:PATH = "$shimRoot;$windowsPowerShell;$system32"
    Assert-Equal 1 (Invoke-Dargo "doctor") "Doctor accepted a missing lark-cli"

    & (Join-Path $repoRoot "dargo.cmd") unknown 2> $null
    Assert-Equal 2 $LASTEXITCODE "Unknown command did not fail with exit code 2"

    Write-Output "PASS: Windows DargoJiao scripts"
} finally {
    $env:PATH = $originalPath
    $env:DARGOJIAO_SKILLS_DIR = $originalSkillsDir
    $env:HTTPS_PROXY = $originalHttpsProxy
    if (Test-Path $temporaryRoot) {
        Remove-Item $temporaryRoot -Recurse -Force
    }
}
