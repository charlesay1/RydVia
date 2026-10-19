param([switch]$SkipFlutter)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$root = Split-Path $PSScriptRoot -Parent
$tools = Join-Path $root '.tools'
[IO.Directory]::CreateDirectory($tools) | Out-Null
function Download([string]$url, [string]$path, [string]$expected) {
    if (!(Test-Path -LiteralPath $path)) {
        Write-Output "Downloading $([IO.Path]::GetFileName($path)) from official vendor."
        (New-Object Net.WebClient).DownloadFile($url, $path)
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected.ToLowerInvariant()) { throw "SHA256 mismatch for $path. Remove the incomplete archive before retrying." }
}
if (!(Test-Path -LiteralPath (Join-Path $tools 'node/node.exe'))) {
    $releases = Invoke-RestMethod 'https://nodejs.org/dist/index.json'
    $release = $releases | Where-Object { $_.lts -ne $false } | Select-Object -First 1
    $name = "node-$($release.version)-win-x64.zip"
    $sumText = (Invoke-WebRequest -UseBasicParsing "https://nodejs.org/dist/$($release.version)/SHASUMS256.txt").Content
    $sum = (($sumText -split "`n" | Where-Object { $_.Trim().EndsWith("  $name") }) -split '\s+')[0]
    if ($sum -notmatch '^[a-f0-9]{64}$') { throw 'No official Node checksum.' }
    $archive = Join-Path $tools $name
    Download "https://nodejs.org/dist/$($release.version)/$name" $archive $sum
    Expand-Archive -LiteralPath $archive -DestinationPath $tools -Force
    Rename-Item -LiteralPath (Join-Path $tools "node-$($release.version)-win-x64") -NewName 'node'
}
if (!(Test-Path -LiteralPath (Join-Path $tools 'git64/cmd/git.exe'))) {
    $release = Invoke-RestMethod -Headers @{ 'User-Agent' = 'RydVia-local-bootstrap' } 'https://api.github.com/repos/git-for-windows/git/releases/latest'
    $asset = $release.assets | Where-Object { $_.name -match '^PortableGit-[\d.]+-64-bit\.7z\.exe$' } | Select-Object -First 1
    if (!$asset -or $asset.digest -notmatch '^sha256:([a-f0-9]{64})$') { throw 'No official Portable Git asset with SHA256 digest.' }
    $sum = $Matches[1]
    $archive = Join-Path $tools $asset.name
    Download $asset.browser_download_url $archive $sum
    $process = Start-Process -FilePath $archive -ArgumentList @('-y', "-o`"$(Join-Path $tools 'git64')`"") -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw 'Portable Git extraction failed.' }
}
if (!$SkipFlutter -and !(Test-Path -LiteralPath (Join-Path $tools 'flutter/bin/flutter.bat'))) {
    $manifest = Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
    $release = $manifest.releases | Where-Object { $_.hash -eq $manifest.current_release.stable } | Select-Object -First 1
    if (!$release -or $release.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'No official Flutter release checksum.' }
    $archive = Join-Path $tools ([IO.Path]::GetFileName($release.archive))
    Download "$($manifest.base_url)/$($release.archive)" $archive $release.sha256
    Write-Output 'Extracting Flutter SDK.'
    & tar.exe -xf $archive -C $tools
    if ($LASTEXITCODE -ne 0) { throw 'Flutter extraction failed.' }
}
# Elevated downloads can otherwise leave Git's SDK checkout owned by Administrators.
# Preserve permissions; set only these newly installed checkout directory owners.
$currentOwner = [Security.Principal.NTAccount]::new([Security.Principal.WindowsIdentity]::GetCurrent().Name)
foreach ($relative in @('flutter','flutter/.git')) {
    $path = Join-Path $tools $relative
    if (Test-Path -LiteralPath $path) {
        $acl = Get-Acl -LiteralPath $path
        $acl.SetOwner($currentOwner)
        Set-Acl -LiteralPath $path -AclObject $acl
    }
}
Write-Output 'Workspace-local tools ready. Run scripts/with-tools.ps1 in your shell.'
