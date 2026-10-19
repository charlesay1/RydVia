$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'with-tools.ps1')
Push-Location (Join-Path (Split-Path $PSScriptRoot -Parent) 'packages/rydvia_auth')
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Auth dependencies failed.' }
    & flutter analyze --fatal-infos
    if ($LASTEXITCODE -ne 0) { throw 'Auth analysis failed.' }
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Auth tests failed.' }
} finally { Pop-Location }
