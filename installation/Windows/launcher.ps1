param()

# -------------------
# Version information
# -------------------
$VERSION = "v2.0.0-beta6"
$VERSION_DISPLAY = "2.0.0 Beta 6"
$DEVELOPMENT_BRANCH = "2.0.0"

# Don't do anything with version or development branch
$null = @($VERSION, $DEVELOPMENT_BRANCH)

function Write-Colour($text, $color) {
    Write-Host $text -ForegroundColor $color
}

function Show-Help {
    Write-Host ""
    Write-Host "Usage: vocabularyplus [command] [options]"
    Write-Host "Commands:"
    Write-Host "  uninstall        Uninstall Vocabulary Plus"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -v, --version    Show version information"
    Write-Host "  -a, --about      Show information about VocabularyPlus"
    Write-Host "  -h, --help       Show this help message"
}

$InstallDir = $PSScriptRoot
$Python = Join-Path $InstallDir ".venv" "Scripts" "python.exe"
$UninstallScript = Join-Path $InstallDir "uninstall.ps1"
$RemainingArgs = if ($args.Count -gt 1) { $args[1..($args.Count - 1)] } else { @() }

if ($args.Count -gt 0) {
    switch ($args[0].ToLower()) {
        '--help' { Show-Help; exit 0 }
        '-h' { Show-Help; exit 0 }
        '--version' { Write-Host "$VERSION_DISPLAY"; exit 0 }
        '-v' { Write-Host "$VERSION_DISPLAY"; exit 0 }
        'uninstall' {
            & $UninstallScript @RemainingArgs
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