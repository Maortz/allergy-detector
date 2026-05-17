# Full green-check: test + analyze + web + apk. Summary output only.
# Usage (from repo root):  pwsh tools/verify.ps1   (or)   powershell -File tools\verify.ps1
$ErrorActionPreference = 'Continue'
Push-Location "$PSScriptRoot\..\app"
try {
    Write-Output "== flutter test =="
    flutter test | Select-Object -Last 3

    Write-Output "== flutter analyze =="
    flutter analyze | Select-Object -Last 3

    Write-Output "== flutter build web =="
    flutter build web --no-tree-shake-icons | Select-Object -Last 3

    Write-Output "== flutter build apk --debug =="
    flutter build apk --debug | Select-Object -Last 3
}
finally {
    Pop-Location
}
