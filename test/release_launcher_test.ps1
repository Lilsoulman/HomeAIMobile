$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fakeShorebird = Join-Path $repoRoot 'test/fixtures/fake_shorebird.bat'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("nexus-release-launcher-$([Guid]::NewGuid().ToString('N'))")
$logDirectory = Join-Path $testRoot 'logs'
$captureFile = Join-Path $testRoot 'shorebird-calls.txt'
$branch = (& git -C $repoRoot branch --show-current).Trim()
$targetEnvironment = switch ($branch) {
    'main' { 'Staging' }
    'release' { 'Production' }
    default { throw "Release launcher tests only support main or release, not '$branch'." }
}
$targetName = $targetEnvironment.ToLowerInvariant()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

try {
    New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
    $env:NEXUS_SHOREBIRD_EXECUTABLE = $fakeShorebird
    $env:NEXUS_SHOREBIRD_CAPTURE_FILE = $captureFile
    $env:NEXUS_RELEASE_LOG_DIRECTORY = $logDirectory

    $successArguments = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', (Join-Path $repoRoot 'scripts/run_android_release.ps1'),
        '-Mode', 'Base', '-TargetEnvironment', $targetEnvironment, '-Choice', '1'
    )
    if ($targetEnvironment -eq 'Production') {
        $successArguments += @('-ReleaseVersion', '1.2.0')
    }
    & powershell @successArguments
    Assert-True ($LASTEXITCODE -eq 0) 'The base launcher should succeed during DryRun.'
    $successLog = Get-ChildItem -LiteralPath $logDirectory -Filter "*-$targetName-base-*.log" | Select-Object -First 1
    Assert-True ($null -ne $successLog) 'The base launcher did not create a log file.'
    Assert-True ((Get-Content -Raw -LiteralPath $successLog.FullName) -match 'RESULT: SUCCESS') 'The success log did not record the final result.'

    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts/run_android_release.ps1') -Mode Base -TargetEnvironment $targetEnvironment -Choice 9
    Assert-True ($LASTEXITCODE -eq 1) 'The launcher should reject an invalid menu choice.'
    $failureLog = Get-ChildItem -LiteralPath $logDirectory -Filter "*-$targetName-base-*.log" |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    Assert-True ((Get-Content -Raw -LiteralPath $failureLog.FullName) -match 'RESULT: FAILURE') 'The failure log did not record the final result.'

    Write-Output 'Release launcher tests passed.'
} finally {
    Remove-Item Env:NEXUS_SHOREBIRD_EXECUTABLE -ErrorAction SilentlyContinue
    Remove-Item Env:NEXUS_SHOREBIRD_CAPTURE_FILE -ErrorAction SilentlyContinue
    Remove-Item Env:NEXUS_RELEASE_LOG_DIRECTORY -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot -PathType Container) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
