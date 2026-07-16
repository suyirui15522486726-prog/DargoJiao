param(
    [Parameter(Position = 0)]
    [string]$CommandName = "help"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

function Write-Usage {
    Write-Output "Usage: .\dargo.cmd {install|doctor|version|prompt|help}"
}

switch ($CommandName.ToLowerInvariant()) {
    "install" {
        & (Join-Path $PSScriptRoot "install.ps1")
        exit 0
    }
    "doctor" {
        & (Join-Path $PSScriptRoot "doctor.ps1")
        exit $LASTEXITCODE
    }
    "version" {
        Write-Output "DargoJiao v0.2.0"
        exit 0
    }
    "prompt" {
        Write-Output 'Use $dargojiao in Codex. Bootstrap prompt: templates/bootstrap-prompt.md'
        exit 0
    }
    { $_ -in @("help", "-h", "--help") } {
        Write-Usage
        exit 0
    }
    default {
        [Console]::Error.WriteLine("Unknown command: $CommandName")
        [Console]::Error.WriteLine("Usage: .\dargo.cmd {install|doctor|version|prompt|help}")
        exit 2
    }
}
