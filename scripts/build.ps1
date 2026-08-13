param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [string]$Runtime = 'win-x64',

    [string]$CertificateThumbprint
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_NOLOGO = '1'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$artifactsRoot = Join-Path $repositoryRoot 'artifacts'
$dotnetPath = Join-Path $repositoryRoot '.tools\dotnet\dotnet.exe'
$solutionPath = Join-Path $repositoryRoot 'KakaoQuickLogin.slnx'
$projectPath = Join-Path $repositoryRoot 'src\KakaoQuickLogin\KakaoQuickLogin.csproj'
$propsPath = Join-Path $repositoryRoot 'Directory.Build.props'

if (-not (Test-Path -LiteralPath $dotnetPath)) {
    throw 'Project-local .NET SDK was not found. Run scripts\bootstrap-dotnet.ps1 first.'
}

[xml]$props = Get-Content -Raw -Encoding utf8 -LiteralPath $propsPath
$version = [string]$props.Project.PropertyGroup.Version
if ([string]::IsNullOrWhiteSpace($version)) {
    throw 'Version was not found in Directory.Build.props.'
}

$publishDirectory = Join-Path $artifactsRoot "publish\$Runtime"
$packageName = "KakaoQuickLogin-$version-$Runtime"
$packageDirectory = Join-Path $artifactsRoot "package\$packageName"
$archivePath = Join-Path $artifactsRoot "$packageName.zip"
$archiveHashPath = "$archivePath.sha256"

function Remove-SafeArtifact {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $resolvedArtifactsRoot = [IO.Path]::GetFullPath($artifactsRoot).TrimEnd('\') + '\'
    $resolvedTarget = [IO.Path]::GetFullPath($Path)
    if (-not $resolvedTarget.StartsWith($resolvedArtifactsRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a path outside artifacts: $resolvedTarget"
    }

    Remove-Item -LiteralPath $resolvedTarget -Recurse -Force
}

Remove-SafeArtifact $publishDirectory
Remove-SafeArtifact $packageDirectory
Remove-SafeArtifact $archivePath
Remove-SafeArtifact $archiveHashPath

& $dotnetPath restore $solutionPath --locked-mode --ignore-failed-sources
if ($LASTEXITCODE -ne 0) {
    throw "dotnet restore failed with exit code $LASTEXITCODE."
}

& $dotnetPath publish $projectPath `
    -c $Configuration `
    -r $Runtime `
    --self-contained true `
    --no-restore `
    -p:PublishSingleFile=true `
    -p:Version=$version `
    -o $publishDirectory
if ($LASTEXITCODE -ne 0) {
    throw "dotnet publish failed with exit code $LASTEXITCODE."
}

$executablePath = Join-Path $publishDirectory 'KakaoQuickLogin.exe'
if (-not (Test-Path -LiteralPath $executablePath)) {
    throw 'Published executable was not created.'
}

$selfTest = Start-Process -FilePath $executablePath -ArgumentList '--self-test' -Wait -PassThru -WindowStyle Hidden
if ($selfTest.ExitCode -ne 0) {
    throw "Published executable self-test failed with exit code $($selfTest.ExitCode)."
}

if (-not [string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
    & (Join-Path $PSScriptRoot 'sign.ps1') `
        -FilePath $executablePath `
        -CertificateThumbprint $CertificateThumbprint
}

New-Item -ItemType Directory -Path $packageDirectory -Force | Out-Null
Copy-Item -LiteralPath $executablePath -Destination $packageDirectory
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'packaging\README.txt') -Destination $packageDirectory
Copy-Item -LiteralPath (Join-Path $repositoryRoot 'SECURITY.md') -Destination $packageDirectory
Copy-Item -LiteralPath (Join-Path $repositoryRoot '.tools\dotnet\LICENSE.txt') -Destination (Join-Path $packageDirectory 'dotnet-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $repositoryRoot '.tools\dotnet\ThirdPartyNotices.txt') -Destination (Join-Path $packageDirectory 'dotnet-ThirdPartyNotices.txt')

$executableHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $packageDirectory 'KakaoQuickLogin.exe')).Hash.ToLowerInvariant()
Set-Content -LiteralPath (Join-Path $packageDirectory 'SHA256SUMS.txt') -Encoding ASCII -Value "$executableHash  KakaoQuickLogin.exe"

Compress-Archive -LiteralPath $packageDirectory -DestinationPath $archivePath -CompressionLevel Optimal
$archiveHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash.ToLowerInvariant()
Set-Content -LiteralPath $archiveHashPath -Encoding ASCII -Value "$archiveHash  $packageName.zip"

Get-Item -LiteralPath $archivePath, $archiveHashPath | Select-Object FullName, Length, LastWriteTime
