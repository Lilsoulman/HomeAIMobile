$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fakeShorebird = Join-Path $repoRoot 'test/fixtures/fake_shorebird.bat'
$captureFile = Join-Path ([IO.Path]::GetTempPath()) ("nexus-shorebird-$([Guid]::NewGuid().ToString('N')).txt")
$stateDirectory = Join-Path $repoRoot '.release-state'
$statePath = Join-Path $stateDirectory 'staging.json'
$stateBackup = $null
$generatedArtifactDirectory = $null
$fakeBuildArtifact = Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-staging-release.apk'
$fakeBuildArtifactBackup = $null
$patchableFixtureOriginalBytes = $null

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

try {
    $env:NEXUS_SHOREBIRD_EXECUTABLE = $fakeShorebird
    $env:NEXUS_SHOREBIRD_CAPTURE_FILE = $captureFile
    $env:NEXUS_FAKE_ARTIFACT_PATH = $fakeBuildArtifact
    New-Item -ItemType Directory -Force -Path (Split-Path $fakeBuildArtifact -Parent) | Out-Null
    if (Test-Path -LiteralPath $fakeBuildArtifact -PathType Leaf) {
        $fakeBuildArtifactBackup = Join-Path ([IO.Path]::GetTempPath()) ("nexus-existing-artifact-$([Guid]::NewGuid().ToString('N')).apk")
        Copy-Item -LiteralPath $fakeBuildArtifact -Destination $fakeBuildArtifactBackup
    }

    & (Join-Path $repoRoot 'scripts/build_android_base.ps1') -Artifact apk -DryRun
    $baseCalls = @(Get-Content -LiteralPath $captureFile)
    Assert-True ($baseCalls.Count -eq 2) 'Base script should make one list call and one release call.'
    Assert-True ($baseCalls[0] -match '^--json releases list --flavor=staging --platform=android$') 'Base script release-list arguments are invalid.'
    Assert-True ($baseCalls[1] -match '^release android --flavor=staging --artifact=apk --flutter-version=3\.47\.1 --dry-run -- --build-name=0\.0\.0 --build-number=(\d+) --dart-define-from-file=config/test\.json$') 'Base script did not forward the expected dry-run and version arguments.'
    $generatedBuildNumber = [int64]$Matches[1]
    Assert-True ($generatedBuildNumber -ge 1 -and $generatedBuildNumber -le 2100000000) 'Generated buildNumber is outside the Android range.'
    $generatedArtifactDirectory = Join-Path $repoRoot "artifacts/staging/0.0.0+$generatedBuildNumber"

    Remove-Item Env:NEXUS_FAKE_ARTIFACT_PATH
    Remove-Item -LiteralPath $fakeBuildArtifact -Force
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $failureOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts/build_android_base.ps1') -Artifact apk -DryRun 2>&1)
        $failureExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    Assert-True ($failureExitCode -ne 0) 'Base script must fail when Shorebird produces no APK.'
    Assert-True (($failureOutput -join "`n") -match 'did not produce the expected apk artifact') 'Missing APK failure should explain why the task failed.'

    Remove-Item -LiteralPath $captureFile -Force
    New-Item -ItemType Directory -Force -Path $stateDirectory | Out-Null
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $stateBackup = Get-Content -Raw -LiteralPath $statePath
    }
    $baseCommit = (& git -C $repoRoot rev-parse HEAD).Trim()
    $configFile = 'config/test.json'
    $configHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $repoRoot $configFile)).Hash.ToLowerInvariant()
    [ordered]@{
        releaseVersion = '0.0.0+123456'
        versionName = '0.0.0'
        buildNumber = 123456
        flavor = 'staging'
        branch = 'main'
        baseCommit = $baseCommit
        configFile = $configFile
        configSha256 = $configHash
    } | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8

    $patchableFixtureOriginalBytes = [IO.File]::ReadAllBytes($fakeShorebird)
    [IO.File]::AppendAllText($fakeShorebird, "`r`nrem patchable test change")
    & (Join-Path $repoRoot 'scripts/build_android_patch.ps1') -DryRun
    [IO.File]::WriteAllBytes($fakeShorebird, $patchableFixtureOriginalBytes)
    $patchableFixtureOriginalBytes = $null
    $patchCalls = @(Get-Content -LiteralPath $captureFile)
    Assert-True ($patchCalls.Count -eq 2) 'Patch script should make one list call and one patch call during dry-run.'
    Assert-True ($patchCalls[0] -match '^--json patches list --flavor=staging --release-version=0\.0\.0\+123456$') 'Patch script patch-list arguments are invalid.'
    Assert-True ($patchCalls[1] -eq 'patch android --flavor=staging --release-version=0.0.0+123456 --dry-run -- --build-name=0.0.0 --build-number=123456 --dart-define-from-file=config/test.json') 'Patch script did not reuse the base release version.'

    Write-Output 'Release script tests passed.'
} finally {
    Remove-Item Env:NEXUS_SHOREBIRD_EXECUTABLE -ErrorAction SilentlyContinue
    Remove-Item Env:NEXUS_SHOREBIRD_CAPTURE_FILE -ErrorAction SilentlyContinue
    Remove-Item Env:NEXUS_FAKE_ARTIFACT_PATH -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $captureFile -Force -ErrorAction SilentlyContinue
    if ($null -ne $patchableFixtureOriginalBytes) {
        [IO.File]::WriteAllBytes($fakeShorebird, $patchableFixtureOriginalBytes)
    }
    if ($fakeBuildArtifactBackup -and (Test-Path -LiteralPath $fakeBuildArtifactBackup -PathType Leaf)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $fakeBuildArtifact -Parent) | Out-Null
        Copy-Item -LiteralPath $fakeBuildArtifactBackup -Destination $fakeBuildArtifact -Force
        Remove-Item -LiteralPath $fakeBuildArtifactBackup -Force
    } else {
        Remove-Item -LiteralPath $fakeBuildArtifact -Force -ErrorAction SilentlyContinue
    }
    if ($generatedArtifactDirectory -and (Test-Path -LiteralPath $generatedArtifactDirectory -PathType Container)) {
        $artifactRoot = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'artifacts')).Path
        $resolvedArtifactDirectory = (Resolve-Path -LiteralPath $generatedArtifactDirectory).Path
        if ($resolvedArtifactDirectory.StartsWith($artifactRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            Remove-Item -LiteralPath $resolvedArtifactDirectory -Recurse -Force
        }
    }
    if ($null -ne $stateBackup) {
        $stateBackup | Set-Content -LiteralPath $statePath -Encoding utf8
    } else {
        Remove-Item -LiteralPath $statePath -Force -ErrorAction SilentlyContinue
    }
}
