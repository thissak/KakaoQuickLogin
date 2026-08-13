param(
    [string]$SdkVersion = '10.0.400'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$toolsDirectory = Join-Path $repositoryRoot '.tools'
$installDirectory = Join-Path $toolsDirectory 'dotnet'
$installerPath = Join-Path $toolsDirectory 'dotnet-install.ps1'
$dotnetPath = Join-Path $installDirectory 'dotnet.exe'

if (Test-Path -LiteralPath $dotnetPath) {
    $installedVersion = & $dotnetPath --version
    if ($installedVersion -eq $SdkVersion) {
        Write-Output ".NET SDK $SdkVersion is already installed."
        exit 0
    }
}

New-Item -ItemType Directory -Path $toolsDirectory -Force | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri 'https://dot.net/v1/dotnet-install.ps1' -OutFile $installerPath
& $installerPath -Version $SdkVersion -InstallDir $installDirectory -NoPath

$actualVersion = & $dotnetPath --version
if ($actualVersion -ne $SdkVersion) {
    throw "Expected .NET SDK $SdkVersion, but installed $actualVersion."
}

Write-Output ".NET SDK $actualVersion installed in $installDirectory"
