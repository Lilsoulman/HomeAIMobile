[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Base', 'Patch')]
    [string]$Mode,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Staging', 'Production')]
    [string]$TargetEnvironment,
    [string]$Choice,
    [string]$ReleaseVersion
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

$expectedBranch = switch ($TargetEnvironment) {
    'Staging' { 'main' }
    'Production' { 'release' }
}
$environmentName = if ($TargetEnvironment -eq 'Staging') { 'staging 测试环境' } else { 'production 正式环境' }

$logDirectory = $env:NEXUS_RELEASE_LOG_DIRECTORY
if ([string]::IsNullOrWhiteSpace($logDirectory)) {
    $logDirectory = Join-Path $repoRoot '.release-logs'
}
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$timestamp = [DateTime]::Now.ToString('yyyyMMdd-HHmmss')
$modeName = $Mode.ToLowerInvariant()
$targetName = $TargetEnvironment.ToLowerInvariant()
$logPath = Join-Path $logDirectory "$timestamp-$targetName-$modeName-$PID.log"
$transcriptStarted = $false
$exitCode = 1

try {
    Start-Transcript -LiteralPath $logPath -Force | Out-Null
    $transcriptStarted = $true

    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
        throw '无法读取当前 Git 分支。'
    }
    if ($branch -ne $expectedBranch) {
        throw "$TargetEnvironment 启动器必须在 $expectedBranch 分支运行，当前分支是 '$branch'。"
    }

    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ' NexusMind Android Shorebird 发布工具' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host "仓库：$repoRoot"
    Write-Host "分支：$branch"
    Write-Host "环境：$environmentName"
    Write-Host "日志：$logPath"
    Write-Host ''

    if ($Mode -eq 'Base') {
        Write-Host '请选择底包任务：'
        Write-Host '  1. APK DryRun（只验证，不上传，推荐先执行）'
        Write-Host '  2. APK 正式构建并上传 Shorebird'
        Write-Host '  3. AAB DryRun（只验证，不上传）'
        Write-Host '  4. AAB 正式构建并上传 Shorebird'
        if ([string]::IsNullOrWhiteSpace($Choice)) {
            $Choice = Read-Host '请输入 1、2、3 或 4'
        }
        $Choice = $Choice.Trim()

        $artifact = switch ($Choice) {
            '1' { 'apk' }
            '2' { 'apk' }
            '3' { 'aab' }
            '4' { 'aab' }
            default { throw "无效选择 '$Choice'，只能输入 1、2、3 或 4。" }
        }
        $dryRun = $Choice -in @('1', '3')

        if ($TargetEnvironment -eq 'Production') {
            if ([string]::IsNullOrWhiteSpace($ReleaseVersion)) {
                $ReleaseVersion = Read-Host '请输入正式 versionName（例如 1.2.0）'
            }
            $ReleaseVersion = $ReleaseVersion.Trim()
            if ($ReleaseVersion -notmatch '^\d+\.\d+\.\d+$') {
                throw '正式 versionName 必须使用 x.y.z 格式，例如 1.2.0。'
            }
        } elseif (-not [string]::IsNullOrWhiteSpace($ReleaseVersion)) {
            throw 'main/staging 不接受 ReleaseVersion，versionName 固定为 0.0.0。'
        }

        Write-Host ''
        Write-Host "任务：$(if ($dryRun) { 'DryRun，不上传' } else { '正式上传 Shorebird' })" -ForegroundColor Yellow
        Write-Host "产物：$($artifact.ToUpperInvariant())" -ForegroundColor Yellow
        if ($TargetEnvironment -eq 'Production') {
            Write-Host "versionName：$ReleaseVersion" -ForegroundColor Yellow
        }
        Write-Host ''

        $parameters = @{ Artifact = $artifact }
        if ($dryRun) { $parameters.DryRun = $true }
        if ($TargetEnvironment -eq 'Production') { $parameters.ReleaseVersion = $ReleaseVersion }
        & (Join-Path $PSScriptRoot 'build_android_base.ps1') @parameters
    } else {
        Write-Host '请选择 Patch 任务：'
        Write-Host '  1. Patch DryRun（只验证，不上传，推荐先执行）'
        Write-Host '  2. 正式构建并上传 Patch 到 Shorebird'
        if ([string]::IsNullOrWhiteSpace($Choice)) {
            $Choice = Read-Host '请输入 1 或 2'
        }
        $Choice = $Choice.Trim()
        if ($Choice -notin @('1', '2')) {
            throw "无效选择 '$Choice'，只能输入 1 或 2。"
        }
        $dryRun = $Choice -eq '1'

        Write-Host ''
        Write-Host "任务：$(if ($dryRun) { 'DryRun，不上传' } else { '正式上传 Shorebird' })" -ForegroundColor Yellow
        Write-Host ''

        $parameters = @{}
        if ($dryRun) { $parameters.DryRun = $true }
        & (Join-Path $PSScriptRoot 'build_android_patch.ps1') @parameters
    }

    Write-Host ''
    Write-Host '[成功] 任务执行完成。' -ForegroundColor Green
    Write-Host 'RESULT: SUCCESS'
    $exitCode = 0
} catch {
    Write-Host ''
    Write-Host "[失败] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'RESULT: FAILURE'
    Write-Host ''
    Write-Host '详细错误：' -ForegroundColor DarkYellow
    Write-Host ($_ | Out-String)
    $exitCode = 1
} finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }
    Write-Host ''
    Write-Host "完整日志：$logPath" -ForegroundColor Cyan
}

exit $exitCode
