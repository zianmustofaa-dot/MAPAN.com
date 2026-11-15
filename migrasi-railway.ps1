# ============================================================
# Migrasi database MAPAN -> MySQL Railway
# Cara pakai:
#   1. Buka Railway > service MySQL > tab Connect
#   2. Copy connection string lengkap, contohnya:
#      mysql://root:PASSWORDBERISIK@mainnet.proxy.rlwy.net:12345/railway
#   3. Jalankan:  powershell -ExecutionPolicy Bypass -File migrasi-railway.ps1
#   4. Paste connection string-nya saat diminta, tekan Enter. Selesai.
# ============================================================
param(
    [string]$Uri,
    [switch]$ProvisionAdmin   # tambahkan jika sekaligus mau buat admin pertama
)

if (-not $Uri) {
    Write-Host ""
    Write-Host "Paste connection string dari Railway (tab Connect), lalu tekan Enter:" -ForegroundColor Cyan
    Write-Host "(formatnya: mysql://root:PASSWORD@host:port/railway)" -ForegroundColor DarkGray
    $Uri = Read-Host ">> "
}

# --- Bersihkan & urai connection string ---
$clean = $Uri.Trim() -replace '^mysql2?://', ''
try {
    $parsed = [System.Uri]"http://$clean"
} catch {
    Write-Host "[GAGAL] Teks yang dipaste tidak bisa dibaca. Pastikan copy dari Railway tab Connect." -ForegroundColor Red
    Read-Host "Tekan Enter untuk keluar"
    exit 1
}

$idxColon = $parsed.UserInfo.IndexOf(':')
if ($idxColon -lt 1) {
    Write-Host "[GAGAL] Password tidak ditemukan di connection string. Pastikan copy lengkap." -ForegroundColor Red
    Read-Host "Tekan Enter untuk keluar"
    exit 1
}

$DB_USER = [uri]::UnescapeDataString($parsed.UserInfo.Substring(0, $idxColon))
$DB_PASSWORD = [uri]::UnescapeDataString($parsed.UserInfo.Substring($idxColon + 1))
$DB_HOST = $parsed.Host
$DB_PORT = $parsed.Port
$DB_NAME = [uri]::UnescapeDataString($parsed.AbsolutePath.Trim('/'))
if (-not $DB_NAME) { $DB_NAME = "railway" }

Write-Host ""
Write-Host "Terbaca dari connection string:" -ForegroundColor Green
Write-Host "  Host     : $DB_HOST"
Write-Host "  Port     : $DB_PORT"
Write-Host "  User     : $DB_USER"
Write-Host "  Password : $($DB_PASSWORD.Substring(0, [Math]::Min(2, $DB_PASSWORD.Length)))****** (disembunyikan)"
Write-Host "  Database : $DB_NAME"
Write-Host ""

# --- Set env & jalankan migrasi ---
$env:NODE_ENV = "production"
$env:DB_HOST = $DB_HOST
$env:DB_PORT = "$DB_PORT"
$env:DB_USER = $DB_USER
$env:DB_PASSWORD = $DB_PASSWORD
$env:DB_NAME = $DB_NAME

Push-Location "$PSScriptRoot\server"
try {
    if ($ProvisionAdmin) {
        npm run provision-admin
    } else {
        npm run migrate
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Kalau di atas muncul '9 migrasi diterapkan' berarti sukses." -ForegroundColor Green
Write-Host "Cek di Railway: tab Database -> Data, harusnya sudah ada 22 tabel." -ForegroundColor Green
Read-Host "Tekan Enter untuk keluar"
