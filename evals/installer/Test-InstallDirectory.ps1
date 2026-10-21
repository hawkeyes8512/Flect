[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot = Join-Path $repoRoot ('build\installer-directory-tests\' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$scriptPath = Join-Path $PSScriptRoot 'Test-Installer.ps1'

function Assert-Preflight([string]$Path, [bool]$ShouldReject) {
    $errorMessage = & {
        function New-Item { throw '__SIDE_EFFECT__' }
        function New-ItemProperty { throw '__SIDE_EFFECT__' }
        function Start-Process { throw '__SIDE_EFFECT__' }
        try {
            & $scriptPath -Installer 'not-executed.exe' -InstallDirectory $Path
            throw 'The installer test unexpectedly completed.'
        }
        catch { $_.Exception.Message }
    }
    $expected = if ($ShouldReject) { 'Refusing installer test directory:*' } else { '__SIDE_EFFECT__' }
    if ($errorMessage -notlike $expected) { throw "Unexpected preflight result for '$Path': $errorMessage" }
    Write-Host "PASS directory preflight (reject=$ShouldReject): $Path"
}

try {
    $empty = Join-Path $testRoot 'empty'
    New-Item -ItemType Directory -Path $empty | Out-Null
    Assert-Preflight $empty $false
    Assert-Preflight (Join-Path $testRoot 'new\app') $false

    $occupied = Join-Path $testRoot 'occupied'
    New-Item -ItemType Directory -Path $occupied | Out-Null
    $original = Join-Path $occupied 'original.txt'
    Set-Content -LiteralPath $original -Value 'Keep this original file.'
    $hash = (Get-FileHash -LiteralPath $original).Hash
    Assert-Preflight $occupied $true
    Assert-Preflight $original $true

    $hidden = Join-Path $testRoot 'hidden'
    New-Item -ItemType Directory -Path $hidden | Out-Null
    $hiddenFile = Join-Path $hidden 'hidden.txt'
    Set-Content -LiteralPath $hiddenFile -Value 'Keep this hidden file.'
    (Get-Item -LiteralPath $hiddenFile).Attributes = [IO.FileAttributes]::Hidden
    Assert-Preflight $hidden $true

    $junction = Join-Path $testRoot 'junction'
    New-Item -ItemType Junction -Path $junction -Target $empty | Out-Null
    Assert-Preflight $junction $true
    Assert-Preflight (Join-Path $junction 'new') $true
    if ((Get-FileHash -LiteralPath $original).Hash -ne $hash) { throw 'An original file was changed.' }
    Write-Host 'All directory preflight checks passed; no installer or registry mutation was executed.'
}
finally {
    $allowedRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot 'build\installer-directory-tests')).TrimEnd('\') + '\'
    if (-not ([IO.Path]::GetFullPath($testRoot)).StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to clean a test directory outside the expected root.'
    }
    if ($junction -and (Test-Path -LiteralPath $junction)) { Remove-Item -LiteralPath $junction -Force }
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
