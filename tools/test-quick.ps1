# Fast targeted test run. Pass a --plain-name filter, or a test file path, or nothing for the full suite.
# Usage:  powershell -File tools\test-quick.ps1 "displays recent activity"
#         powershell -File tools\test-quick.ps1 test/widgets/screens/home_screen_test.dart
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Filter)
Push-Location "$PSScriptRoot\..\app"
try {
    if (-not $Filter -or $Filter.Count -eq 0) {
        flutter test | Select-Object -Last 3
    }
    elseif ($Filter.Count -eq 1 -and (Test-Path (Join-Path (Get-Location) $Filter[0]))) {
        flutter test $Filter[0] | Select-Object -Last 3
    }
    else {
        flutter test --plain-name ($Filter -join ' ') | Select-Object -Last 3
    }
}
finally {
    Pop-Location
}
