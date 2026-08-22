[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

function Invoke-ShorebirdJson {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [bool]$RequireJson = $true,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $outputLines = @(& $Command @Arguments 2>&1 | ForEach-Object {
            if ($_ -is [Management.Automation.ErrorRecord]) {
                $_.Exception.Message
            } else {
                "$_"
            }
        })
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    foreach ($line in $outputLines) { Write-Host $line }
    if ($exitCode -ne 0) {
        throw "Shorebird failed with exit code ${exitCode}: $($Arguments -join ' ')"
    }

    $jsonLine = $outputLines |
        Where-Object { $_.TrimStart().StartsWith('{') } |
        Select-Object -Last 1
    if (-not $jsonLine) {
        if (-not $RequireJson) { return $null }
        throw 'Shorebird did not return its expected JSON result.'
    }
    $result = $jsonLine | ConvertFrom-Json
    if ($result.status -ne 'success') {
        throw "Shorebird returned a non-success result: $jsonLine"
    }
    return $result
}

function Save-Json {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $Value | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Get-MaximumPatchNumber {
    param($PatchListResult)
    $maximum = 0
    foreach ($patch in @($PatchListResult.data.patches)) {
        if ($null -ne $patch -and [int]$patch.number -gt $maximum) {
            $maximum = [int]$patch.number
        }
    }
    return $maximum
}

if (-not (Get-Command 'git' -ErrorAction SilentlyContinue)) {
    throw 'git was not found on PATH.'
}
$shorebirdCommand = $env:NEXUS_SHOREBIRD_EXECUTABLE
if ([string]::IsNullOrWhiteSpace($shorebirdCommand)) {
    $shorebirdCommand = (Get-Command 'shorebird' -ErrorAction SilentlyContinue).Source
}
if ([string]::IsNullOrWhiteSpace($shorebirdCommand)) {
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

$stateDirectory = Join-Path $repoRoot '.release-state'
$statePath = Join-Path $stateDirectory "$flavor.json"
$pendingPath = Join-Path $stateDirectory "$flavor.patch.pending.json"
$historyPath = Join-Path $stateDirectory "$flavor.patches.json"
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "No published $flavor base release state was found. Publish a base release on this machine first."
}
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
$releaseVersion = [string]$state.releaseVersion
if ($releaseVersion -notmatch '^(?<name>\d+\.\d+\.\d+)\+(?<number>[1-9]\d*)$') {
    throw "The saved release version is invalid: $releaseVersion"
}
$versionName = $Matches['name']
$buildNumber = [int64]$Matches['number']
if ($state.branch -ne $branch -or $state.flavor -ne $flavor) {
    throw 'The saved base release state does not match the current branch and flavor.'
}
if ($branch -eq 'test' -and $versionName -ne '0.0.0') {
    throw 'The test branch can only patch a 0.0.0+N base release.'
}
if ($branch -eq 'release' -and $versionName -eq '0.0.0') {
    throw 'The release branch cannot use the test 0.0.0 versionName.'
}
if (-not (Test-Path -LiteralPath $configFile -PathType Leaf)) {
    throw "Missing environment configuration: $configFile"
}

$status = & git status --porcelain
if (-not $DryRun -and $status) {
    throw 'A clean Git worktree is required for publishing.'
}
if ($DryRun -and $status) {
    Write-Warning 'The Git worktree is dirty. This dry-run cannot be used as release evidence.'
}

$baseCommit = [string]$state.baseCommit
& git cat-file -e "$baseCommit^{commit}" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "The saved base commit does not exist locally: $baseCommit"
}
$patchCommit = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Unable to read the current Git commit.' }
$changedFiles = if ($DryRun) {
    @(& git diff --name-only $baseCommit)
} else {
    @(& git diff --name-only "$baseCommit..HEAD")
}
$blockedFiles = @($changedFiles | Where-Object {
    $_ -match '^(android|ios|macos|windows|linux|web)/' -or
    $_ -match '^(assets|fonts|config|env)/' -or
    $_ -eq 'pubspec.yaml' -or $_ -eq 'pubspec.lock' -or
    $_ -eq 'shorebird.yaml'
})
if ($blockedFiles.Count -gt 0) {
    throw "Non-patchable native, dependency, configuration, or asset changes were detected:`n$($blockedFiles -join "`n")`nPublish a new base release instead."
}
if ($changedFiles.Count -eq 0) {
    throw 'No committed changes exist after the saved base release.'
}

$configHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $configFile).Hash.ToLowerInvariant()
if ($configHash -ne [string]$state.configSha256) {
    throw 'The environment configuration differs from the base release. Publish a new base release instead.'
}

$history = $null
if (Test-Path -LiteralPath $historyPath -PathType Leaf) {
    $history = Get-Content -Raw -LiteralPath $historyPath | ConvertFrom-Json
    $existingEntry = @($history.patches) | Where-Object {
        $_.releaseVersion -eq $releaseVersion -and $_.patchCommit -eq $patchCommit
    } | Select-Object -First 1
    if ($existingEntry) {
        throw "Git commit $patchCommit was already published as Patch $($existingEntry.patchNumber) for $releaseVersion."
    }
}

$patchListBefore = Invoke-ShorebirdJson -Command $shorebirdCommand -Arguments @(
    '--json', 'patches', 'list', "--flavor=$flavor",
    "--release-version=$releaseVersion"
)
$maximumPatchBefore = Get-MaximumPatchNumber $patchListBefore

$pending = $null
$uploadAlreadyCompleted = $false
if (-not $DryRun -and (Test-Path -LiteralPath $pendingPath -PathType Leaf)) {
    $pending = Get-Content -Raw -LiteralPath $pendingPath | ConvertFrom-Json
    $pendingMatches =
        $pending.branch -eq $branch -and
        $pending.flavor -eq $flavor -and
        $pending.releaseVersion -eq $releaseVersion -and
        $pending.patchCommit -eq $patchCommit -and
        $pending.configSha256 -eq $configHash
    if (-not $pendingMatches) {
        throw "A pending patch exists at $pendingPath but does not match this build. Resolve or remove it before publishing another patch."
    }
    $previousMaximum = [int]$pending.previousMaximumPatchNumber
    if ($maximumPatchBefore -gt $previousMaximum) {
        $uploadAlreadyCompleted = $true
        Write-Warning "A newer Shorebird patch already exists. Finalizing the matching pending state without uploading it again."
    }
} elseif (-not $DryRun) {
    $pending = [ordered]@{
        releaseVersion = $releaseVersion
        flavor = $flavor
        branch = $branch
        baseCommit = $baseCommit
        patchCommit = $patchCommit
        configSha256 = $configHash
        previousMaximumPatchNumber = $maximumPatchBefore
        createdAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    Save-Json $pending $pendingPath
    Write-Host "Saved pending patch: $pendingPath"
}

Write-Host "Branch: $branch"
Write-Host "Flavor: $flavor"
Write-Host "Patch target: $releaseVersion"
Write-Host "Base Git commit: $baseCommit"
Write-Host "Patch Git commit: $patchCommit"
Write-Host "Mode: $(if ($DryRun) { 'dry-run' } else { 'publish' })"

if (-not $uploadAlreadyCompleted) {
    $shorebirdArgs = @(
        'patch', 'android', "--flavor=$flavor",
        "--release-version=$releaseVersion"
    )
    if ($DryRun) { $shorebirdArgs += '--dry-run' }
    $shorebirdArgs += @(
        '--', "--build-name=$versionName", "--build-number=$buildNumber",
        "--dart-define-from-file=$configFile"
    )
    Write-Host "Shorebird arguments: $($shorebirdArgs -join ' ')"
    $null = Invoke-ShorebirdJson -Command $shorebirdCommand -RequireJson $false -Arguments $shorebirdArgs
}

if (-not $DryRun) {
    $patchListAfter = Invoke-ShorebirdJson -Command $shorebirdCommand -Arguments @(
        '--json', 'patches', 'list', "--flavor=$flavor",
        "--release-version=$releaseVersion"
    )
    $patchNumber = Get-MaximumPatchNumber $patchListAfter
    $previousMaximum = [int]$pending.previousMaximumPatchNumber
    if ($patchNumber -le $previousMaximum) {
        throw 'The patch command completed, but no new Shorebird patchNumber could be confirmed.'
    }

    $entries = if ($null -ne $history) { @($history.patches) } else { @() }
    $entry = [ordered]@{
        releaseVersion = $releaseVersion
        patchNumber = $patchNumber
        track = 'stable'
        flavor = $flavor
        branch = $branch
        baseCommit = $baseCommit
        patchCommit = $patchCommit
        configSha256 = $configHash
        publishedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    $updatedHistory = [ordered]@{
        flavor = $flavor
        branch = $branch
        patches = @($entries + $entry)
    }
    Save-Json $updatedHistory $historyPath
    Remove-Item -LiteralPath $pendingPath -Force -ErrorAction SilentlyContinue
    Write-Host "Published Shorebird Patch $patchNumber for $releaseVersion."
    Write-Host "Saved patch history: $historyPath"
}
