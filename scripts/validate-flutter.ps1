param([switch]$SkipResolve)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'with-tools.ps1')
$projects = @('packages/rydvia_core','packages/rydvia_models','packages/rydvia_logging','packages/rydvia_analytics','packages/rydvia_location','packages/rydvia_ui','packages/rydvia_design_system','packages/rydvia_api','packages/rydvia_auth','apps/customer_app','apps/driver_app','apps/business_app')
foreach ($project in $projects) {
    Push-Location (Join-Path $root $project)
    try {
        $flutterProject = (Get-Content -LiteralPath pubspec.yaml -Raw).Contains('sdk: flutter')
        if (!$SkipResolve) {
            if ($flutterProject) { & flutter pub get } else { & dart pub get }
            if ($LASTEXITCODE -ne 0) { throw "Dependency resolution failed: $project" }
        }
        if ($flutterProject) { & flutter analyze --fatal-infos } else { & dart analyze --fatal-infos }
        if ($LASTEXITCODE -ne 0) { throw "Analysis failed: $project" }
        if (Test-Path -LiteralPath test) {
            if ($flutterProject) { & flutter test } else { & dart test }
            if ($LASTEXITCODE -ne 0) { throw "Tests failed: $project" }
        }
        Write-Output "PASS $project"
    } finally { Pop-Location }
}
