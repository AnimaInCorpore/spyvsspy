param(
    [string]$SourcePath = (Join-Path $PSScriptRoot 'Spy vs Spy (Title Version).s'),
    [string]$SourceDir = (Join-Path $PSScriptRoot 'src'),
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'src\MANIFEST.txt')
)

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Missing root source: $SourcePath"
}

New-Item -ItemType Directory -Force -Path $SourceDir | Out-Null

$lines = Get-Content -LiteralPath $SourcePath
$segments = New-Object System.Collections.Generic.List[object]
$currentLines = New-Object System.Collections.Generic.List[string]
$currentAddr = $null
$started = $false

foreach ($line in $lines) {
    if ($line -match '^\s*\.ORG\s+\$([0-9A-Fa-f]{4})') {
        if (-not $started) {
            $started = $true
            $currentAddr = $Matches[1].ToUpperInvariant()
        } else {
            $segments.Add([pscustomobject]@{
                Addr  = $currentAddr
                Lines = @($currentLines)
            })
            $currentLines = New-Object System.Collections.Generic.List[string]
            $currentAddr = $Matches[1].ToUpperInvariant()
        }
    }

    $currentLines.Add($line)
}

if ($currentAddr -ne $null -and $currentLines.Count -gt 0) {
    $segments.Add([pscustomobject]@{
        Addr  = $currentAddr
        Lines = @($currentLines)
    })
}

$manifest = New-Object System.Collections.Generic.List[string]
foreach ($seg in $segments) {
    $fileName = $seg.Addr + '.s'
    $filePath = Join-Path $SourceDir $fileName
    [System.IO.File]::WriteAllText($filePath, (($seg.Lines -join "`r`n") + "`r`n"), [System.Text.Encoding]::ASCII)
    $manifest.Add($fileName)
}

[System.IO.File]::WriteAllLines($ManifestPath, $manifest, [System.Text.Encoding]::ASCII)
Write-Host "Wrote $($segments.Count) slices to $SourceDir and refreshed $ManifestPath."
