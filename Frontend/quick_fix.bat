@echo off
echo 🚀 Quick Fix - Building without code shrinking

echo 📦 Getting dependencies...
flutter pub get

echo 🔨 Building release APK (no code shrinking)...
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
    echo 📏 APK size: 
    dir build\app\outputs\flutter-apk\app-release.apk
    echo 🎉 APK ready for testing!
) else (
    echo ❌ Build failed!
    echo 💡 Check the error messages above
)

pause 