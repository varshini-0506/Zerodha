@echo off
echo 🎬 Testing Smooth Price Animations

echo 📦 Getting dependencies...
flutter pub get

echo 🔨 Building APK for testing...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
    echo 🎬 Install and test the smooth price animations!
    echo 💡 Look for:
    echo    - Smooth price transitions (no jarring effects)
    echo    - Color changes (green for up, red for down)
    echo    - Animated change percentages
    echo    - Subtle background highlights
) else (
    echo ❌ Build failed!
)

pause 