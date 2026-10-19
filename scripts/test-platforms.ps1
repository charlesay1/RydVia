$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$checks = 0
foreach ($role in @('customer','driver','business')) {
    $app = Join-Path $root "apps/${role}_app"
    foreach ($file in @('lib/main.dart','android/app/src/main/AndroidManifest.xml','android/app/build.gradle.kts','ios/Runner/Info.plist','ios/Runner.xcodeproj/project.pbxproj','ios/Runner.xcworkspace/contents.xcworkspacedata','ios/Runner/Base.lproj/LaunchScreen.storyboard')) {
        if (!(Test-Path -LiteralPath (Join-Path $app $file))) { throw "Missing native file: $role/$file" }
        $checks++
    }
    foreach ($xmlFile in @('android/app/src/main/AndroidManifest.xml','ios/Runner/Info.plist','ios/Runner/Base.lproj/LaunchScreen.storyboard')) {
        $xml = [xml](Get-Content -LiteralPath (Join-Path $app $xmlFile) -Raw)
        if (!$xml.DocumentElement) { throw "Invalid XML for $role/$xmlFile" }
        $checks++
    }
    $gradle = Get-Content -LiteralPath (Join-Path $app 'android/app/build.gradle.kts') -Raw
    if (!$gradle.Contains("applicationId = `"com.rydvia.$role`"")) { throw "Wrong Android app ID: $role" }
    if ($gradle.Contains('signingConfigs.getByName("debug")')) { throw "Debug-signed release configuration: $role" }
    $checks += 2
    $pbx = Get-Content -LiteralPath (Join-Path $app 'ios/Runner.xcodeproj/project.pbxproj') -Raw
    if (!$pbx.Contains("com.rydvia.$role")) { throw "Wrong iOS app ID: $role" }
    $checks++
    $slots = Get-Content -LiteralPath (Join-Path $app 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json') -Raw | ConvertFrom-Json
    if (@($slots.images).Count -lt 10) { throw "iPhone/iPad AppIcon slots missing: $role" }
    $checks++
}
Write-Output "PASS: $checks native identity and structural checks. This is not native compilation or launcher artwork approval."
