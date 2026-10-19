$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$tokens = Get-Content -LiteralPath (Join-Path $root 'design/tokens.json') -Raw | ConvertFrom-Json
$script:checks = 0
function Assert([bool]$condition, [string]$message) {
    if (!$condition) { throw $message }
    $script:checks++
}
function Luminance([string]$hex) {
    $channels = @(1, 3, 5) | ForEach-Object {
        $value = [Convert]::ToInt32($hex.Substring($_, 2), 16) / 255.0
        if ($value -le 0.04045) { $value / 12.92 } else { [Math]::Pow(($value + 0.055) / 1.055, 2.4) }
    }
    return 0.2126 * $channels[0] + 0.7152 * $channels[1] + 0.0722 * $channels[2]
}
function Contrast([string]$a, [string]$b) {
    $x = Luminance $a
    $y = Luminance $b
    return ([Math]::Max($x, $y) + 0.05) / ([Math]::Min($x, $y) + 0.05)
}
$locked = @{
    primaryIndigo = '#4C6BFF'; midnightNavy = '#0F1B3D'; violetBlue = '#6366F1'
    warmCoral = '#FF8A6B'; charcoal = '#1F2937'; warmOffWhite = '#FAF7F2'
}
foreach ($name in $locked.Keys) { Assert ($tokens.colors.$name -ceq $locked[$name]) "Brand color changed: $name" }
foreach ($color in $tokens.colors.PSObject.Properties) {
    Assert ($color.Value -cmatch '^#[0-9A-F]{6}$') "Invalid color: $($color.Name)"
}
Assert ((@($tokens.spacing.PSObject.Properties.Value) -join ',') -eq '4,8,12,16,20,24,32,40,48') 'Spacing scale changed.'
Assert ($tokens.radius.button -ge 12 -and $tokens.radius.button -le 14) 'Button radius out of range.'
Assert ($tokens.radius.input -ge 12 -and $tokens.radius.input -le 14) 'Input radius out of range.'
Assert ($tokens.radius.card -ge 14 -and $tokens.radius.card -le 18) 'Card radius out of range.'
Assert ($tokens.radius.sheet -ge 24 -and $tokens.radius.sheet -le 28) 'Sheet radius out of range.'
Assert ($tokens.motion.theme -ge 250 -and $tokens.motion.theme -le 350) 'Theme motion out of range.'
foreach ($theme in $tokens.themes.PSObject.Properties) {
    foreach ($reference in $theme.Value.PSObject.Properties) {
        Assert ($null -ne $tokens.colors.($reference.Value)) "Unknown color reference: $($reference.Value)"
    }
    foreach ($surfaceName in @('background', 'surface')) {
        $surface = $tokens.colors.($theme.Value.$surfaceName)
        foreach ($role in @('text', 'secondaryText', 'success', 'error', 'warning')) {
            $foreground = $tokens.colors.($theme.Value.$role)
            $ratio = Contrast $foreground $surface
            Assert ($ratio -ge 4.5) "$($theme.Name) $role on $surfaceName fails AA: $ratio"
        }
        $focusRatio = Contrast $tokens.colors.($theme.Value.focus) $surface
        Assert ($focusRatio -ge 3) "$($theme.Name) focus is not visible on $surfaceName."
    }
    $actionRatio = Contrast $tokens.colors.($theme.Value.onAction) $tokens.colors.($theme.Value.action)
    Assert ($actionRatio -ge 4.5) "$($theme.Name) action text fails AA: $actionRatio"
    $linkRatio = Contrast $tokens.colors.($theme.Value.action) $tokens.colors.($theme.Value.surface)
    Assert ($linkRatio -ge 4.5) "$($theme.Name) action labels on surfaces fail AA: $linkRatio"
}
Assert ((Contrast '#FFFFFF' '#405BE0') -ge 3) 'Light button focus border must contrast with the button fill.'
Assert ((Contrast '#0F1B3D' '#A8B8FF') -ge 3) 'Dark button focus border must contrast with the button fill.'
& (Join-Path $PSScriptRoot 'generate-tokens.ps1') -Check
Write-Output "PASS: $script:checks token, contrast, and consistency assertions."
