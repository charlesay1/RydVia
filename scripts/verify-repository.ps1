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
    $files = & git ls-files --cached --others --exclude-standard
    if ($LASTEXITCODE -ne 0) { throw 'Git inventory failed.' }
    $findings = @()
    foreach ($relative in $files) {
        if ([IO.Path]::GetExtension($relative) -notin @('.dart','.ts','.tsx','.mjs','.json','.yaml','.yml','.toml','.sql','.md','.example')) { continue }
        $file = Join-Path $root $relative
        if (!(Test-Path -LiteralPath $file -PathType Leaf)) { continue }
        $content = [IO.File]::ReadAllText($file)
        if ($content -match '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----' -or $content -match 'sb_secret_[A-Za-z0-9_-]{20,}') { $findings += $relative }
    }
    if ($findings.Count) { throw "Potential secret material detected in files: $($findings -join ', ')" }
    Write-Output 'PASS: authoritative origin, environment/signing ignore rules, and scoped secret-pattern checks. No commit or push performed.'
} finally { Pop-Location }
