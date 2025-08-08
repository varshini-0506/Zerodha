@echo off
echo 📊 Testing Performance Section with Live Data

echo 📦 Getting dependencies...
flutter pub get

echo 🔨 Building APK for testing...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
    echo 📊 Test the performance section:
    echo    - Performance section should be visible at bottom
    echo    - Change amount should update with live ticks
    echo    - Change percentage should update with live ticks
    echo    - Smooth animations for all value changes
    echo    - Live data from WebSocket should update the section
) else (
    echo ❌ Build failed!
)

pause 