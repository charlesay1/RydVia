$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'with-tools.ps1')
foreach ($role in @('customer','driver','business')) {
    $app = Join-Path $root "apps/${role}_app"
    $createdNativeProject = $false
    if (!(Test-Path -LiteralPath (Join-Path $app 'android'))) {
        & flutter create --empty --platforms=android,ios --no-pub --org com.rydvia $app
        if ($LASTEXITCODE -ne 0) { throw "Platform generation failed for $role" }
        $createdNativeProject = $true
        # Remove only newly generated template icons, never approved brand assets.
        $icons = @(Get-ChildItem -LiteralPath (Join-Path $app 'android/app/src/main/res') -Recurse -File -Filter 'ic_launcher.png')
        $iconSet = Join-Path $app 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
        $icons += @(Get-ChildItem -LiteralPath $iconSet -File -Filter '*.png')
        foreach ($icon in $icons) {
            $absolute = [IO.Path]::GetFullPath($icon.FullName)
            if (!$absolute.StartsWith([IO.Path]::GetFullPath($app) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Icon target escaped app directory.' }
            Remove-Item -LiteralPath $absolute
        }
        $contentsPath = Join-Path $iconSet 'Contents.json'
        $contents = Get-Content -LiteralPath $contentsPath -Raw | ConvertFrom-Json
        foreach ($slot in $contents.images) { $slot.PSObject.Properties.Remove('filename') }
        [IO.File]::WriteAllText($contentsPath, ($contents | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
    }
    $gradle = Join-Path $app 'android/app/build.gradle.kts'
    $gradleText = [IO.File]::ReadAllText($gradle)
    $gradleText = $gradleText.Replace("com.rydvia.rydvia_$role", "com.rydvia.$role")
    [IO.File]::WriteAllText($gradle, $gradleText, [Text.UTF8Encoding]::new($false))
    foreach ($kotlin in Get-ChildItem -LiteralPath (Join-Path $app 'android/app/src/main/kotlin') -Recurse -File -Filter '*.kt') {
        $text = [IO.File]::ReadAllText($kotlin.FullName).Replace("com.rydvia.rydvia_$role", "com.rydvia.$role")
        [IO.File]::WriteAllText($kotlin.FullName, $text, [Text.UTF8Encoding]::new($false))
    }
    $title = 'RydVia ' + $role.Substring(0,1).ToUpperInvariant() + $role.Substring(1)
    $manifestPath = Join-Path $app 'android/app/src/main/AndroidManifest.xml'
    $manifest = [IO.File]::ReadAllText($manifestPath)
    $manifest = [regex]::Replace($manifest, 'android:label="[^"]*"', "android:label=`"$title`"")
    # Only a newly created Flutter template has an unapproved template icon.
    # Preserve any existing icon reference; approved exports must survive reruns.
    if ($createdNativeProject) { $manifest = [regex]::Replace($manifest, '\s+android:icon="[^"]*"', '') }
    if (!$manifest.Contains('android.permission.INTERNET')) {
        $manifest = $manifest.Replace('<application', '<uses-permission android:name="android.permission.INTERNET" />' + "`n    <application")
    }
    [IO.File]::WriteAllText($manifestPath, $manifest, [Text.UTF8Encoding]::new($false))
    $plist = Join-Path $app 'ios/Runner/Info.plist'
    $text = [IO.File]::ReadAllText($plist)
    $text = [regex]::Replace($text, '(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', "`${1}$title`${2}")
    [IO.File]::WriteAllText($plist, $text, [Text.UTF8Encoding]::new($false))
    $pbx = Join-Path $app 'ios/Runner.xcodeproj/project.pbxproj'
    $text = [regex]::Replace([IO.File]::ReadAllText($pbx), "com\.rydvia\.rydvia_?$role", "com.rydvia.$role", [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    [IO.File]::WriteAllText($pbx, $text, [Text.UTF8Encoding]::new($false))
    Write-Output "$title native identity configured; approved icons still required."
}
