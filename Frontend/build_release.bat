@echo off
echo 🚀 Building optimized release APK...

REM Clean previous builds
echo 🧹 Cleaning previous builds...
flutter clean

REM Get dependencies
echo 📦 Getting dependencies...
flutter pub get

REM Build optimized release APK
echo 🔨 Building release APK with optimizations...
flutter build apk --release --target-platform android-arm64

REM Check if build was successful
if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
    echo 🎉 Release APK ready for distribution!
) else (
    echo ❌ Build failed!
    pause
    exit /b 1
)

pause 