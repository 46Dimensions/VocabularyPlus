param()

function Show-Help {
    Write-Host ""
    Write-Host "Usage: vocabularyplus [command] [options]"
    Write-Host "Commands:"
    Write-Host "  create           Create a new vocabulary file"
    Write-Host "  uninstall        Uninstall Vocabulary Plus"
    Write-Host "  menu             Launch the Vocabulary Plus menu"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -v, --version    Show version information"
    Write-Host "  -a, --about      Show information about VocabularyPlus"
    Write-Host "  -h, --help       Show this help message"
}

$ScriptDir = $PSScriptRoot
$InstallDir = Get-Content -Path (Join-Path $ScriptDir "install_dir.txt")
$Python = Join-Path $InstallDir "venv\Scripts\python.exe"
$UninstallScript = Join-Path $ScriptDir "uninstall.ps1"
$RemainingArgs = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

if ($args.Count -gt 0) {
    switch ($args[0].ToLower()) {
        '--help' { Show-Help; exit 0 }
        '-h' { Show-Help; exit 0 }
        '--version' { Write-Host "1.4.0"; exit 0 }
        '-v' { Write-Host "1.4.0"; exit 0 }
        'uninstall' {
            & $UninstallScript @RemainingArgs
            exit $LASTEXITCODE
        }
        'create' {
            & $Python (Join-Path $InstallDir "create_vocab_file.py") @RemainingArgs
            exit $LASTEXITCODE
        }
        'menu' {
            & $PYTHON (Join-Path $InstallDir "menu.py") @RemainingArgs
            exit $LASTEXITCODE
        }
        '--about' {
            Get-Content -Path (Join-Path $InstallDir "about.txt")
            exit $LASTEXITCODE
        }
        '-a' {
            Get-Content -Path (Join-Path $InstallDir "about.txt")
            exit $LASTEXITCODE
        }
        Default {
            & $Python (Join-Path $InstallDir "main.py") @args
            exit $LASTEXITCODE
        }
    }
}
else {
    & $Python (Join-Path $InstallDir "main.py")
    exit $LASTEXITCODE
}