param(
    [string]$platform,
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'

$repo = $null

function Reset-FlutterSdk {
    git -C $env:FLUTTER_ROOT checkout -- .
    if ($LASTEXITCODE -ne 0) { throw 'git checkout failed' }
}

function Reset-RepoPatches {
    $ErrorActionPreference = 'Continue'
    foreach ($p in 'bottom_sheet_ios_piliplus.patch', 'geetest_ios.patch') {
        git -C $repo apply -R "lib/scripts/$p" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$p reverted"
        }
    }
    $ErrorActionPreference = 'Stop'
}

function Reset-PubCache {
    $pubCache = if ($env:PUB_CACHE) { $env:PUB_CACHE }
                elseif ($env:LOCALAPPDATA) { "$env:LOCALAPPDATA/Pub/Cache" }
                else { "~/.pub-cache" }
    foreach ($name in 'material_ui-*', 'cupertino_ui-*') {
        Get-ChildItem "$pubCache/hosted/pub.dev" -Directory -Filter $name -ErrorAction SilentlyContinue |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
    }
    Set-Location -LiteralPath $repo
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
}

try {
    $repo = (Resolve-Path "$PSScriptRoot\..\..").Path
    Set-Location -LiteralPath $repo

    $envFile = Join-Path $repo '.env'
    if (-not (Test-Path -LiteralPath $envFile)) {
        throw "$envFile not found"
    }

    foreach ($line in Get-Content -LiteralPath $envFile -Encoding UTF8) {
        $line = $line.Trim()
        if ($line.Length -eq 0 -or $line.StartsWith('#')) { continue }
        $i = $line.IndexOf('=')
        if ($i -lt 1) { continue }
        $key = $line.Substring(0, $i).Trim()
        $value = $line.Substring($i + 1).Trim()
        if ($value.Length -ge 2 -and (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        Set-Item -Path ('Env:' + $key) -Value $value
    }

    if (-not $env:FLUTTER_ROOT) {
        throw 'FLUTTER_ROOT not set in .env'
    }

    if ($Restore) {
        Write-Host 'Restoring Flutter SDK'
        Reset-FlutterSdk
        Write-Host 'Restoring repo patches'
        Reset-RepoPatches
        Write-Host 'Restoring pub cache'
        Reset-PubCache
        Write-Host 'Done'
        return
    }

    $validPlatforms = 'windows', 'android', 'ios', 'linux', 'macos'
    if ($validPlatforms -notcontains $platform) {
        throw "Unknown platform: $platform"
    }

    $env:GITHUB_WORKSPACE = $repo

    Write-Host 'Resetting previous patches'
    Reset-FlutterSdk
    Reset-RepoPatches

    Write-Host "Patching platform: $platform"
    & (Join-Path $repo 'lib\scripts\patch.ps1') $platform
    if ($LASTEXITCODE -ne 0) { throw "Patch failed with exit code: $LASTEXITCODE" }

    Write-Host 'Done'
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    if ($repo) {
        Set-Location -LiteralPath $repo
    }
}
