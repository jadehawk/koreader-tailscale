param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
$BuildsDir = Join-Path $Root 'Builds'
$MetaPath = Join-Path $Root '_meta.lua'

$RuntimeFiles = @(
    '_meta.lua',
    'main.lua',
    'bin/auth.key',
    'bin/install-tailscale.sh',
    'bin/start_tailscale.sh',
    'bin/stop_tailscale.sh',
    'bin/uninstall-tailscale.sh'
)

Write-Host ''
Write-Host '========================================'
Write-Host ' KOReader Tailscale Plugin - Build'
Write-Host '========================================'
Write-Host ''

if (-not (Test-Path -LiteralPath $MetaPath -PathType Leaf)) {
    throw "Missing required file: $MetaPath"
}

$MetaText = Get-Content -LiteralPath $MetaPath -Raw
$VersionMatch = [regex]::Match($MetaText, 'version\s*=\s*["'']([^"'']+)["'']')
if (-not $VersionMatch.Success) {
    throw 'Could not read plugin version from _meta.lua.'
}
$Version = $VersionMatch.Groups[1].Value
$ZipName = "tailscale.koplugin-v$Version.zip"
$ZipPath = Join-Path $BuildsDir $ZipName

Write-Host "[*] Version: $Version"
Write-Host '[*] Validating runtime files...'

foreach ($RelativePath in $RuntimeFiles) {
    $SourcePath = Join-Path $Root ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Missing required runtime file: $RelativePath"
    }
}

$AuthKeyTemplate = Join-Path $Root 'bin\auth.key'
if ((Get-Content -LiteralPath $AuthKeyTemplate -Raw).Trim().Length -ne 0) {
    throw 'bin/auth.key must remain blank. Refusing to package a real auth key.'
}
Write-Host '[OK] Packaged auth.key is blank.'

Write-Host '[*] Checking shell-script line endings...'
foreach ($RelativePath in $RuntimeFiles | Where-Object { $_ -like '*.sh' }) {
    $SourcePath = Join-Path $Root ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $Bytes = [IO.File]::ReadAllBytes($SourcePath)
    if ($Bytes -contains 13) {
        throw "Shell script contains CR/CRLF line endings: $RelativePath. Convert it to LF before building."
    }
}
Write-Host '[OK] Shell scripts are LF-only.'

if (-not (Test-Path -LiteralPath $BuildsDir)) {
    New-Item -ItemType Directory -Path $BuildsDir | Out-Null
}

if (Test-Path -LiteralPath $ZipPath) {
    if (-not $Force) {
        $Answer = Read-Host "[!] $ZipName already exists. Overwrite? (Y/N)"
        if ($Answer -notmatch '^[Yy]$') {
            Write-Host '[*] Build cancelled.'
            exit 0
        }
    }
    Remove-Item -LiteralPath $ZipPath -Force
}

$StageRoot = Join-Path ([IO.Path]::GetTempPath()) ("koreader-tailscale-build-" + [guid]::NewGuid().ToString('N'))
$PluginStage = Join-Path $StageRoot 'tailscale.koplugin'

try {
    New-Item -ItemType Directory -Path $PluginStage | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $PluginStage 'bin') | Out-Null

    Write-Host '[*] Staging runtime files only...'
    foreach ($RelativePath in $RuntimeFiles) {
        $SourcePath = Join-Path $Root ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $DestinationPath = Join-Path $PluginStage ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
        Write-Host "    + tailscale.koplugin/$RelativePath"
    }

    Write-Host "[*] Creating Builds\$ZipName..."
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory(
        $StageRoot,
        $ZipPath,
        [IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    Write-Host '[*] Verifying ZIP manifest...'
    $ExpectedEntries = $RuntimeFiles | ForEach-Object { "tailscale.koplugin/$($_ -replace '\\','/')" } | Sort-Object
    $Archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        $ActualEntries = @(
            $Archive.Entries |
                Where-Object { -not $_.FullName.EndsWith('/') } |
                ForEach-Object { $_.FullName -replace '\\','/' } |
                Sort-Object
        )
    }
    finally {
        $Archive.Dispose()
    }

    $Difference = Compare-Object -ReferenceObject $ExpectedEntries -DifferenceObject $ActualEntries
    if ($Difference) {
        $Details = ($Difference | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }) -join [Environment]::NewLine
        throw "ZIP manifest verification failed:`n$Details"
    }

    $ZipInfo = Get-Item -LiteralPath $ZipPath
    Write-Host '[OK] ZIP contains only the required runtime files.'
    Write-Host ''
    Write-Host '========================================'
    Write-Host '[DONE] Plugin build created successfully'
    Write-Host '========================================'
    Write-Host "File: $ZipName"
    Write-Host "Location: $BuildsDir"
    Write-Host ("Size: {0:N1} KB" -f ($ZipInfo.Length / 1KB))
    Write-Host ''
}
finally {
    if (Test-Path -LiteralPath $StageRoot) {
        Remove-Item -LiteralPath $StageRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
