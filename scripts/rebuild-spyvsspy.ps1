param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$SourceDir,
    [string]$ManifestPath,
    [string]$OutputPath
)

if (-not $SourceDir) { $SourceDir = Join-Path $RepoRoot 'src' }
if (-not $ManifestPath) { $ManifestPath = Join-Path $RepoRoot 'src\MANIFEST.txt' }
if (-not $OutputPath) { $OutputPath = Join-Path $RepoRoot 'Spy vs Spy (Title Version).s' }

$manifest = Get-Content -LiteralPath $ManifestPath
$builder = New-Object System.Text.StringBuilder

foreach ($entry in $manifest) {
    $name = $entry.Trim()
    if ([string]::IsNullOrWhiteSpace($name)) {
        continue
    }

    $path = Join-Path $SourceDir $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing source slice: $path"
    }

    $text = [System.IO.File]::ReadAllText($path)
    [void]$builder.Append($text)
    if (-not $text.EndsWith("`r`n") -and -not $text.EndsWith("`n")) {
        [void]$builder.Append("`r`n")
    }
}

[System.IO.File]::WriteAllText($OutputPath, $builder.ToString(), [System.Text.Encoding]::ASCII)
Write-Host "Wrote $OutputPath from $($manifest.Count) slices."
