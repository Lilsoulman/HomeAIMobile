[CmdletBinding()]
param(
    [ValidateSet('apk', 'aab')]
    [string]$Artifact = 'apk',
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
if ($LASTEXITCODE -ne 0) { throw 'Unable to read the current Git branch.' }

switch ($branch) {
    'test' {
        $flavor = 'staging'
        $configFile = 'config/test.json'
        $shallow = (& git rev-parse --is-shallow-repository).Trim()
        if ($shallow -ne 'false') {
            throw 'The test buildNumber requires complete Git history. Unshallow the repository first.'
        }
        $buildNumber = (& git rev-list --count HEAD).Trim()
        if ($LASTEXITCODE -ne 0 -or $buildNumber -notmatch '^\d+$' -or [int64]$buildNumber -lt 1) {
            throw 'Unable to derive the test buildNumber from the Git commit count.'
        }
        $versionName = '0.0.0'
        $fullVersion = "$versionName+$buildNumber"
    }
    'release' {
        $flavor = 'production'
        $configFile = 'config/production.json'
        if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
            $ReleaseVersion = Read-Host 'Enter the full release version (for example, 1.0.0+1)'
        }
        if ($ReleaseVersion -notmatch '^(?<name>\d+\.\d+\.\d+)\+(?<number>[1-9]\d*)$') {
            throw 'The release version must be x.y.z+N, where N is a positive integer.'
        }
        $versionName = $Matches['name']
        $buildNumber = $Matches['number']
        $fullVersion = $ReleaseVersion
    }
    default {
        throw "Branch '$branch' cannot publish. Use test or release."
    }
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
if ($branch -eq 'release' -and $Artifact -eq 'aab' -and
    -not (Test-Path -LiteralPath 'android/key.properties' -PathType Leaf)) {
    throw 'A production AAB requires android/key.properties and a release keystore. A local production APK may use debug signing.'
}

$shorebirdArgs = @(
    'release', 'android', "--flavor=$flavor", "--artifact=$Artifact",
    '--flutter-version=3.47.1'
)
if (-not $Publish) { $shorebirdArgs += '--dry-run' }
$shorebirdArgs += @(
    '--', "--build-name=$versionName", "--build-number=$buildNumber",
    "--dart-define-from-file=$configFile"
)

Write-Host "Branch: $branch"
Write-Host "Flavor: $flavor"
Write-Host "Version: $fullVersion"
Write-Host "Mode: $(if ($Publish) { 'publish' } else { 'dry-run' })"
Invoke-Checked $shorebirdCommand $shorebirdArgs

if ($Artifact -eq 'apk') {
    $builtArtifact = 'build/app/outputs/flutter-apk/app-' + $flavor + '-release.apk'
} else {
    $builtArtifact = 'build/app/outputs/bundle/' + $flavor + 'Release/app-' + $flavor + '-release.aab'
}
if (Test-Path -LiteralPath $builtArtifact -PathType Leaf) {
    $shortCommit = (& git rev-parse --short HEAD).Trim()
    $artifactDirectory = Join-Path $repoRoot ("artifacts/$flavor/$fullVersion")
    New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
    $artifactName = "NexusMind-$flavor-$fullVersion-$shortCommit.$Artifact"
    $artifactTarget = Join-Path $artifactDirectory $artifactName
    Copy-Item -LiteralPath $builtArtifact -Destination $artifactTarget -Force
    Write-Host "Artifact: $artifactTarget"
} else {
    Write-Warning "Expected artifact was not found: $builtArtifact"
}

if ($Publish) {
    $stateDirectory = Join-Path $repoRoot '.release-state'
    New-Item -ItemType Directory -Force -Path $stateDirectory | Out-Null
    $configHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $configFile).Hash.ToLowerInvariant()
    $state = [ordered]@{
        releaseVersion = $fullVersion
        versionName = $versionName
        buildNumber = [int64]$buildNumber
        flavor = $flavor
        branch = $branch
        baseCommit = (& git rev-parse HEAD).Trim()
        configFile = $configFile
        configSha256 = $configHash
        publishedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    $statePath = Join-Path $stateDirectory "$flavor.json"
    $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
    Write-Host "Saved release state: $statePath"
}
