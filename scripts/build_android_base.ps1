[CmdletBinding()]
param(
    [ValidateSet('apk', 'aab')]
    [string]$Artifact = 'apk',
    [switch]$DryRun,
    [string]$ReleaseVersion
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
if ($LASTEXITCODE -ne 0) { throw 'Unable to read the current Git branch.' }

switch ($branch) {
    'test' {
        $flavor = 'staging'
        $configFile = 'config/test.json'
        if (-not [string]::IsNullOrWhiteSpace($ReleaseVersion)) {
            throw 'Do not pass -ReleaseVersion on test. Its versionName is always 0.0.0.'
        }
        $versionName = '0.0.0'
    }
    'release' {
        $flavor = 'production'
        $configFile = 'config/production.json'
        if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
            $ReleaseVersion = Read-Host 'Enter the release versionName (for example, 1.0.0)'
        }
        if ($ReleaseVersion -notmatch '^\d+\.\d+\.\d+$') {
            throw 'The release versionName must be x.y.z. The buildNumber is generated automatically.'
        }
        $versionName = $ReleaseVersion
    }
    default {
        throw "Branch '$branch' cannot publish. Use test or release."
    }
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
if ($branch -eq 'release' -and $Artifact -eq 'aab' -and
    -not (Test-Path -LiteralPath 'android/key.properties' -PathType Leaf)) {
    throw 'A production AAB requires android/key.properties and a release keystore. A local production APK may use debug signing.'
}

$baseCommit = (& git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Unable to read the current Git commit.' }
$configHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $configFile).Hash.ToLowerInvariant()
$stateDirectory = Join-Path $repoRoot '.release-state'
New-Item -ItemType Directory -Force -Path $stateDirectory | Out-Null
$pendingPath = Join-Path $stateDirectory "$flavor.pending.json"
$statePath = Join-Path $stateDirectory "$flavor.json"

$releaseList = Invoke-ShorebirdJson -Command $shorebirdCommand -Arguments @(
    '--json', 'releases', 'list', "--flavor=$flavor", '--platform=android'
)
$remoteVersions = @(
    $releaseList.data.releases |
        ForEach-Object { [string]$_.version }
)
$maximumRemoteBuildNumber = [int64]0
foreach ($remoteVersion in $remoteVersions) {
    if ($remoteVersion -match '\+(?<number>\d+)$') {
        $remoteBuildNumber = [int64]$Matches['number']
        if ($remoteBuildNumber -gt $maximumRemoteBuildNumber) {
            $maximumRemoteBuildNumber = $remoteBuildNumber
        }
    }
}

$pending = $null
if (-not $DryRun -and (Test-Path -LiteralPath $pendingPath -PathType Leaf)) {
    $pending = Get-Content -Raw -LiteralPath $pendingPath | ConvertFrom-Json
    $pendingMatches =
        $pending.branch -eq $branch -and
        $pending.flavor -eq $flavor -and
        $pending.versionName -eq $versionName -and
        $pending.baseCommit -eq $baseCommit -and
        $pending.configSha256 -eq $configHash -and
        $pending.artifact -eq $Artifact
    if (-not $pendingMatches) {
        throw "A pending release exists at $pendingPath but does not match this build. Resolve or remove it before creating another base release."
    }
    $buildNumber = [int64]$pending.buildNumber
    Write-Host "Reusing pending buildNumber: $buildNumber"
} else {
    $epoch = [DateTimeOffset]::ParseExact(
        '2020-01-01T00:00:00Z',
        'yyyy-MM-ddTHH:mm:ssZ',
        [Globalization.CultureInfo]::InvariantCulture
    )
    $timestampBuildNumber = [int64][Math]::Floor(
        ([DateTimeOffset]::UtcNow - $epoch).TotalSeconds
    )
    $buildNumber = [Math]::Max($timestampBuildNumber, $maximumRemoteBuildNumber + 1)
}

if ($buildNumber -lt 1 -or $buildNumber -gt 2100000000) {
    throw "Generated buildNumber is outside the Android range: $buildNumber"
}
$fullVersion = "$versionName+$buildNumber"

if (-not $DryRun -and $null -eq $pending) {
    $pending = [ordered]@{
        releaseVersion = $fullVersion
        versionName = $versionName
        buildNumber = [int64]$buildNumber
        flavor = $flavor
        branch = $branch
        baseCommit = $baseCommit
        configFile = $configFile
        configSha256 = $configHash
        artifact = $Artifact
        createdAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    Save-Json $pending $pendingPath
    Write-Host "Saved pending release: $pendingPath"
}

$alreadyPublished = $remoteVersions -contains $fullVersion
if ($alreadyPublished -and $DryRun) {
    throw "Release $fullVersion already exists on Shorebird."
}

Write-Host "Branch: $branch"
Write-Host "Flavor: $flavor"
Write-Host "VersionName: $versionName"
Write-Host "BuildNumber: $buildNumber"
Write-Host "Release version: $fullVersion"
Write-Host "Git commit: $baseCommit"
Write-Host "Mode: $(if ($DryRun) { 'dry-run' } else { 'publish' })"

$artifactNotBeforeUtc = [DateTime]::UtcNow.AddSeconds(-5)
if (-not $alreadyPublished) {
    $shorebirdArgs = @(
        'release', 'android', "--flavor=$flavor",
        "--artifact=$Artifact", '--flutter-version=3.47.1'
    )
    if ($DryRun) { $shorebirdArgs += '--dry-run' }
    $shorebirdArgs += @(
        '--', "--build-name=$versionName", "--build-number=$buildNumber",
        "--dart-define-from-file=$configFile"
    )
    Write-Host "Shorebird arguments: $($shorebirdArgs -join ' ')"
    $null = Invoke-ShorebirdJson -Command $shorebirdCommand -RequireJson $false -Arguments $shorebirdArgs
} else {
    if ($null -ne $pending -and $pending.createdAtUtc) {
        $artifactNotBeforeUtc = [DateTime]::Parse([string]$pending.createdAtUtc).ToUniversalTime().AddSeconds(-5)
    }
    Write-Warning "Release $fullVersion already exists. Finalizing the matching pending state without uploading it again."
}

if (-not $DryRun -and -not $alreadyPublished) {
    $releaseListAfter = Invoke-ShorebirdJson -Command $shorebirdCommand -Arguments @(
        '--json', 'releases', 'list', "--flavor=$flavor", '--platform=android'
    )
    $publishedVersions = @(
        $releaseListAfter.data.releases |
            ForEach-Object { [string]$_.version }
    )
    if ($publishedVersions -notcontains $fullVersion) {
        throw "Shorebird returned success, but release $fullVersion was not found afterward. The pending state was retained."
    }
}

$builtArtifact = $null
$artifactCandidates = if ($Artifact -eq 'apk') {
    @("build/app/outputs/flutter-apk/app-$flavor-release.apk")
} else {
    @(
        "build/app/outputs/bundle/${flavor}Release/app-$flavor-release.aab",
        'build/app/outputs/bundle/release/app-release.aab'
    )
}
foreach ($candidate in $artifactCandidates) {
    if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and
        (Get-Item -LiteralPath $candidate).LastWriteTimeUtc -ge $artifactNotBeforeUtc) {
        $builtArtifact = $candidate
        break
    }
}

$artifactTarget = $null
if ($builtArtifact) {
    $shortCommit = (& git rev-parse --short HEAD).Trim()
    $artifactDirectory = Join-Path $repoRoot ("artifacts/$flavor/$fullVersion")
    New-Item -ItemType Directory -Force -Path $artifactDirectory | Out-Null
    $artifactName = "NexusMind-$flavor-$fullVersion-$shortCommit.$Artifact"
    $artifactTarget = Join-Path $artifactDirectory $artifactName
    Copy-Item -LiteralPath $builtArtifact -Destination $artifactTarget -Force
    Write-Host "Artifact: $artifactTarget"
} else {
    Write-Warning "No $Artifact artifact was found in an expected output path."
}

if (-not $DryRun) {
    $state = [ordered]@{
        releaseVersion = $fullVersion
        versionName = $versionName
        buildNumber = [int64]$buildNumber
        flavor = $flavor
        branch = $branch
        baseCommit = $baseCommit
        configFile = $configFile
        configSha256 = $configHash
        artifact = $Artifact
        artifactPath = $artifactTarget
        publishedAtUtc = [DateTime]::UtcNow.ToString('o')
    }
    Save-Json $state $statePath
    Remove-Item -LiteralPath $pendingPath -Force -ErrorAction SilentlyContinue
    Write-Host "Saved release state: $statePath"
}
