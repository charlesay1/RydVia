$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'with-tools.ps1')
$root = Split-Path $PSScriptRoot -Parent
Push-Location $root
try {
    $origin = & git remote get-url origin
    if ($LASTEXITCODE -ne 0 -or $origin -ne 'https://github.com/charlesay1/RydVia.git') { throw 'Unexpected Git origin.' }
    foreach ($path in @('.env','.env.production','apps/customer_app/.env','apps/admin_web/.env.local','signing.p8','signing.jks','.tools/cache')) {
        & git check-ignore --quiet -- $path
        if ($LASTEXITCODE -ne 0) { throw "Sensitive/local path is not ignored: $path" }
    }
    & git check-ignore --quiet -- .env.example
    if ($LASTEXITCODE -eq 0) { throw 'Environment example should be version controlled.' }
    & node (Join-Path $PSScriptRoot 'scan-secrets.mjs')
    if ($LASTEXITCODE -ne 0) { throw 'Secret scan failed; see redacted results above.' }
    Write-Output 'PASS: authoritative origin, environment/signing ignore rules, and shared secret scanner. No commit or push performed.'
} finally { Pop-Location }
