@echo off
echo ⚪ Testing Smooth White Price Animations

echo 📦 Getting dependencies...
flutter pub get

echo 🔨 Building APK for testing...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
    echo ⚪ Test the smooth white animations:
    echo    - Price transitions are smooth (no jarring)
    echo    - All text stays white
    echo    - No color changes on price updates
    echo    - Smooth number counting animations
) else (
    echo ❌ Build failed!
)

pause 