# Mening Mahallam — yuklab olish saytidagi APK'larni yangilash skripti.
#
# Bu hech qanday yangi veb-sahifa yoki /admin yo'lini OCHMAYDI — shunchaki
# terminal orqali ishga tushiriladigan lokal buyruq. Ilovani release
# rejimida (universal + arm64 + arm32 bo'lib) build qiladi va natijani
# to'g'ridan-to'g'ri R2 bucket'ga (mahallam-downloads) yuklaydi — xuddi
# saytdagi yuklab olish tugmalari ishlatadigan fayl nomlari bilan
# (landing-worker/index.js dagi ALLOWED ro'yxatiga qarang).
#
# Ishlatish:
#   powershell -File scripts\release_apk.ps1
#
# Talab qilinadigan narsalar: Flutter SDK, va Cloudflare hisobiga
# ulangan `wrangler` (bu loyihada allaqachon sozlangan — `npx wrangler
# whoami` orqali tekshirish mumkin).

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$bucket = "mahallam-downloads"

function Invoke-Checked {
    param([string]$Description, [scriptblock]$Action)
    Write-Host "==> $Description" -ForegroundColor Cyan
    & $Action
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "$Description muvaffaqiyatsiz tugadi (exit code $LASTEXITCODE)"
    }
}

# 1) Universal APK — barcha protsessorlar uchun, saytdagi asosiy
#    "Yuklab olish" tugmasi va zaxira havola shu faylga ishora qiladi.
Invoke-Checked "Universal APK build qilinmoqda" {
    flutter build apk --release
}
$universalPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $universalPath)) {
    throw "Universal APK topilmadi: $universalPath"
}

# 2) Protsessorga mos, ikki barobar yengil variantlar — sayt telefonni
#    aniqlab shulardan birini taklif qiladi.
Invoke-Checked "arm64/arm32 uchun alohida APK'lar build qilinmoqda" {
    flutter build apk --release --split-per-abi
}
$arm64Path = "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
$arm32Path = "build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk"
foreach ($p in @($arm64Path, $arm32Path)) {
    if (-not (Test-Path $p)) { throw "Kutilgan fayl topilmadi: $p" }
}

# 3) R2'ga yuklash — saytdagi havolalar darhol yangi faylni bera boshlaydi
#    (Worker to'g'ridan-to'g'ri bucket'dan o'qiydi, alohida deploy shart
#    emas).
$contentType = "application/vnd.android.package-archive"

Invoke-Checked "Universal APK R2'ga yuklanmoqda (mening-mahallam.apk)" {
    npx wrangler r2 object put "$bucket/mening-mahallam.apk" --file $universalPath --content-type $contentType --remote
}
Invoke-Checked "arm64 APK R2'ga yuklanmoqda (mening-mahallam-arm64.apk)" {
    npx wrangler r2 object put "$bucket/mening-mahallam-arm64.apk" --file $arm64Path --content-type $contentType --remote
}
Invoke-Checked "arm32 APK R2'ga yuklanmoqda (mening-mahallam-arm32.apk)" {
    npx wrangler r2 object put "$bucket/mening-mahallam-arm32.apk" --file $arm32Path --content-type $contentType --remote
}

Write-Host ""
Write-Host "Tayyor! Sayt endi yangi APK'ni beradi (qo'shimcha deploy shart emas)." -ForegroundColor Green
Write-Host "Eslatma: 'landing/yangiliklar/index.html' dagi versiya tarixiga yangi yozuv qo'shishni unutmang, agar kerak bo'lsa." -ForegroundColor Yellow
