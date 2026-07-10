# ============================================================
#  Compile TechCyberDaily.apk sans Gradle (aapt + d8 + apksigner)
# ============================================================
$ErrorActionPreference = 'Continue'   # les outils Android ecrivent des avertissements sur stderr ; on se fie aux codes de sortie
$sdk      = "$env:LOCALAPPDATA\Android\Sdk"
$bt       = "$sdk\build-tools\34.0.0"
$platform = "$sdk\platforms\android-34\android.jar"
$jdk      = (Get-ChildItem "$env:ProgramFiles\Eclipse Adoptium" -Directory | Where-Object Name -like 'jdk-17*' | Select-Object -First 1).FullName
$proj     = "C:\Users\wk0t\Documents\TechCyberDaily\android"
$out      = "$proj\build"
$apkFinal = "C:\Users\wk0t\Documents\TechCyberDaily\TechCyberDaily.apk"

New-Item -ItemType Directory -Force "$out\obj"  | Out-Null
New-Item -ItemType Directory -Force "$out\dex"  | Out-Null
New-Item -ItemType Directory -Force "$out\gen"  | Out-Null

Write-Output "[0/6] Generation de R.java (ressources)..."
& "$bt\aapt.exe" package -f -m -J "$out\gen" -M "$proj\AndroidManifest.xml" -S "$proj\res" -I $platform 2>&1
if ($LASTEXITCODE -ne 0) { throw "aapt (R.java) a echoue" }

Write-Output "[1/6] Compilation Java..."
$srcFiles = @()
$srcFiles += (Get-ChildItem "$proj\src" -Recurse -Filter *.java).FullName
$srcFiles += (Get-ChildItem "$out\gen" -Recurse -Filter *.java).FullName
& "$jdk\bin\javac.exe" --release 8 -classpath $platform -d "$out\obj" $srcFiles 2>&1
if ($LASTEXITCODE -ne 0) { throw "javac a echoue" }

Write-Output "[2/6] Conversion en DEX (d8)..."
$classes = (Get-ChildItem "$out\obj" -Recurse -Filter *.class).FullName
& "$bt\d8.bat" --release --lib $platform --min-api 24 --output "$out\dex" $classes 2>&1
if ($LASTEXITCODE -ne 0) { throw "d8 a echoue" }

Write-Output "[3/6] Empaquetage APK (aapt)..."
if (Test-Path "$out\app.unsigned.apk") { del "$out\app.unsigned.apk" }
& "$bt\aapt.exe" package -f -M "$proj\AndroidManifest.xml" -S "$proj\res" -A "$proj\assets" -I $platform -F "$out\app.unsigned.apk" 2>&1
if ($LASTEXITCODE -ne 0) { throw "aapt package a echoue" }

Write-Output "[4/6] Ajout du classes.dex..."
Push-Location "$out\dex"
& "$bt\aapt.exe" add "$out\app.unsigned.apk" classes.dex 2>&1
Pop-Location
if ($LASTEXITCODE -ne 0) { throw "aapt add a echoue" }

Write-Output "[5/6] Alignement (zipalign)..."
if (Test-Path "$out\app.aligned.apk") { del "$out\app.aligned.apk" }
& "$bt\zipalign.exe" -f 4 "$out\app.unsigned.apk" "$out\app.aligned.apk" 2>&1

Write-Output "[6/6] Signature (apksigner)..."
$ks = "$proj\techcyber.jks"
if (-not (Test-Path $ks)) {
  & "$jdk\bin\keytool.exe" -genkeypair -keystore $ks -storepass techcyber123 -keypass techcyber123 -alias tcd -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Tech Cyber Daily" 2>&1
}
& "$bt\apksigner.bat" sign --ks $ks --ks-pass pass:techcyber123 --key-pass pass:techcyber123 --out $apkFinal "$out\app.aligned.apk" 2>&1
if ($LASTEXITCODE -ne 0) { throw "apksigner a echoue" }

Write-Output ""
Write-Output "=== Verification ==="
& "$bt\apksigner.bat" verify --print-certs $apkFinal 2>&1 | Select-Object -First 4
& "$bt\aapt.exe" dump badging $apkFinal 2>&1 | Select-Object -First 6
Write-Output ""
Write-Output ("APK genere : {0} ({1} Ko)" -f $apkFinal, [math]::Round((Get-Item $apkFinal).Length/1KB))
