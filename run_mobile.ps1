# ──────────────────────────────────────────────────────────────────────────────
# run_mobile.ps1  —  Run the Flutter app with the correct backend IP
#
# Usage (from repo root):
#   .\run_mobile.ps1              # debug mode
#   .\run_mobile.ps1 --release    # release mode
#   .\run_mobile.ps1 -d <device>  # pick a specific device
#
# How it works:
#   1. Finds your PC's current Wi-Fi IP automatically.
#   2. Passes it to Flutter as --dart-define=BACKEND_HOST=<ip>
#   3. The app connects to http://<ip>:5000 — works on ANY network.
# ──────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

# ── 1. Auto-detect local IP ────────────────────────────────────────────────────
$ip = $null

# Try Wi-Fi first
$wifi = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { ($_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Wireless*") -and $_.IPAddress -ne "127.0.0.1" } |
    Select-Object -First 1
if ($wifi) { $ip = $wifi.IPAddress }

# Fallback: any non-loopback, non-Hyper-V adapter
if (-not $ip) {
    $any = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.InterfaceAlias -notlike "*Loopback*" -and $_.InterfaceAlias -notlike "*vEthernet*" } |
        Select-Object -First 1
    if ($any) { $ip = $any.IPAddress }
}

if (-not $ip) {
    Write-Error "Could not detect a LAN IP address. Make sure Wi-Fi is connected."
    exit 1
}

Write-Host ""
Write-Host "  Detected PC IP : $ip" -ForegroundColor Cyan
Write-Host "  Backend URL    : http://${ip}:5000/api/v1" -ForegroundColor Cyan
Write-Host ""

# ── 2. Run Flutter from the mobile directory ───────────────────────────────────
Push-Location "$PSScriptRoot\mobile"
try {
    flutter run "--dart-define=BACKEND_HOST=$ip" @args
} finally {
    Pop-Location
}
