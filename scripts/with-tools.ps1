$tools = Join-Path (Split-Path $PSScriptRoot -Parent) '.tools'
$env:PATH = @((Join-Path $tools 'node'), (Join-Path $tools 'git64/cmd'), (Join-Path $tools 'flutter/bin'), $env:PATH) -join [IO.Path]::PathSeparator
$env:PUB_CACHE = Join-Path $tools 'pub-cache'
$env:npm_config_cache = Join-Path $tools 'npm-cache'
$env:CI = 'true'
$env:NEXT_TELEMETRY_DISABLED = '1'
