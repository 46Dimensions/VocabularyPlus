param(
    [switch]$Silent
)

function Write-Log {
    param([string]$Message, [string]$Color = 'White')
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

$InstallDir = Get-Content $PSScriptRoot\install_dir.txt
$BinDir = Join-Path $env:USERPROFILE 'AppData\Local\Programs\VocabularyPlus'
$ShortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Vocabulary Plus.lnk'
$ScriptPath = $MyInvocation.MyCommand.Path

Write-Log '==========================================' Cyan
Write-Log 'Vocabulary Plus: Uninstaller (1.4.0)' Cyan
Write-Log '==========================================' Cyan
Write-Log ''

Write-Log 'Removing virtual environment...' Yellow
Remove-Item -LiteralPath (Join-Path $InstallDir 'venv') -Recurse -Force -ErrorAction SilentlyContinue

Write-Log 'Removing application files...' Yellow
Remove-Item -LiteralPath (Join-Path $InstallDir 'main.py') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $InstallDir 'create_vocab_file.py') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $InstallDir 'app_icon.png') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $InstallDir 'requirements.txt') -Force -ErrorAction SilentlyContinue

Write-Log 'Removing VM files...' Yellow
Remove-Item -LiteralPath (Join-Path $InstallDir 'vm') -Recurse -Force -ErrorAction SilentlyContinue

Write-Log 'Removing launchers...' Yellow
Remove-Item -LiteralPath (Join-Path $BinDir 'vocabularyplus.cmd') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $BinDir 'vp.cmd') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $BinDir 'vocabularyplus.ps1') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $BinDir 'vp.ps1') -Force -ErrorAction SilentlyContinue

Write-Log 'Removing Start Menu shortcut...' Yellow
if (Test-Path -LiteralPath $ShortcutPath) {
    Remove-Item -LiteralPath $ShortcutPath -Force -ErrorAction SilentlyContinue
}

Write-Log 'Removing remaining installation files...' Yellow
Get-ChildItem -LiteralPath $InstallDir -Force | Where-Object { $_.FullName -ne $ScriptPath } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Write-Log 'Done.' Green