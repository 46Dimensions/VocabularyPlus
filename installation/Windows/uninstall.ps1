param(
    [switch]$Silent
)

function Write-Log {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

$InstallDir = $PSScriptRoot
$BinDir = Join-Path $env:USERPROFILE 'AppData\Local\Programs\VocabularyPlus'
$ShortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk'

Write-Log 'Removing virtual environment...' Yellow
Remove-Item -LiteralPath (Join-Path $InstallDir 'venv') -Recurse -Force -ErrorAction SilentlyContinue

Write-Log 'Removing launchers...' Yellow
Remove-Item -LiteralPath (Join-Path $BinDir 'vocabularyplus.ps1') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $BinDir 'vp.ps1') -Force -ErrorAction SilentlyContinue

Write-Log 'Removing Start Menu shortcut...' Yellow
if (Test-Path -LiteralPath $ShortcutPath) {
    Remove-Item -LiteralPath $ShortcutPath -Force -ErrorAction SilentlyContinue
}

Write-Log "Removing installation directory..." Yellow
Remove-Item -Recurse -Path $InstallDir

Write-Log 'Done.' Green