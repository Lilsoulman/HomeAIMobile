[CmdletBinding()]
param(
    [switch]$Publish,
    [string]$ReleaseVersion
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
    }
}

if (-not (Get-Command 'git' -ErrorAction SilentlyContinue)) {
    throw 'git was not found on PATH.'
}
$shorebirdCommand = (Get-Command 'shorebird' -ErrorAction SilentlyContinue).Source
if (-not $shorebirdCommand) {
    $shorebirdCommand = Join-Path $env:USERPROFILE '.shorebird/bin/shorebird.bat'
}
if (-not (Test-Path -LiteralPath $shorebirdCommand -PathType Leaf)) {
    throw 'Shorebird was not found on PATH or in the default user directory.'
}

$gitRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or (Resolve-Path $gitRoot).Path -ne $repoRoot) {
    throw 'Run this script from this project Git repository.'
}
$branch = (& git branch --show-current).Trim()
switch ($branch) {
    'test' {
        $flavor = 'staging'
        $configFile = 'config/test.json'
    }
    'release' {
        $flavor = 'production'
        $configFile = 'config/production.json'
    }
    default {
        throw "Branch '$branch' cannot publish. Use test or release."
    }
}

$statePath = Join-Path $repoRoot ".release-state/$flavor.json"
$state = $null
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
}
if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
    if ($null -eq $state -or [string]::IsNullOrWhiteSpace($state.releaseVersion)) {
        throw "No published $flavor base release state was found. Publish a base release first or pass -ReleaseVersion x.y.z+N."
    }
    $ReleaseVersion = [string]$state.releaseVersion
}

if ($ReleaseVersion -notmatch '^(?<name>\d+\.\d+\.\d+)\+(?<number>[1-9]\d*)$') {
    throw 'The patch target must be x.y.z+N, where N is a positive integer.'
}
$versionName = $Matches['name']
$buildNumber = $Matches['number']
if ($branch -eq 'test' -and $versionName -ne '0.0.0') {
    throw 'The test branch can only patch a 0.0.0+N base release.'
}
if ($branch -eq 'release' -and $versionName -eq '0.0.0') {
    throw 'The release branch cannot use the test 0.0.0 version.'
}
if (-not (Test-Path -LiteralPath $configFile -PathType Leaf)) {
    throw "Missing environment configuration: $configFile"
}

$status = & git status --porcelain
if ($Publish -and $status) {
    throw 'A clean Git worktree is required for publishing.'
}
if (-not $Publish -and $status) {
    Write-Warning 'The Git worktree is dirty. This dry-run cannot be used as release evidence.'
}

if ($null -ne $state -and $state.releaseVersion -eq $ReleaseVersion) {
    $baseCommit = [string]$state.baseCommit
    & git cat-file -e "$baseCommit^{commit}" 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "The saved base commit does not exist locally: $baseCommit"
    }
    $changedFiles = @(& git diff --name-only "$baseCommit..HEAD")
    $blockedFiles = @($changedFiles | Where-Object {
        $_ -match '^(android|ios|macos|windows|linux|web)/' -or
        $_ -eq 'pubspec.yaml' -or $_ -eq 'pubspec.lock' -or
        $_ -eq 'shorebird.yaml' -or $_ -match '^(assets|fonts)/'
    })
    if ($blockedFiles.Count -gt 0) {
        throw "Non-patchable native or asset changes were detected:`n$($blockedFiles -join "`n")`nPublish a new base release instead."
    }
}

$shorebirdArgs = @(
    'patch', 'android', "--flavor=$flavor", "--release-version=$ReleaseVersion"
)
if (-not $Publish) { $shorebirdArgs += '--dry-run' }
$shorebirdArgs += @(
    '--', "--build-name=$versionName", "--build-number=$buildNumber",
    "--dart-define-from-file=$configFile"
)

Write-Host "Branch: $branch"
Write-Host "Flavor: $flavor"
Write-Host "Patch target: $ReleaseVersion"
Write-Host "Mode: $(if ($Publish) { 'publish' } else { 'dry-run' })"
Invoke-Checked $shorebirdCommand $shorebirdArgs
