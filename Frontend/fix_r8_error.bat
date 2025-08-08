@echo off
echo 🔧 Fixing R8 missing classes error...

echo 🧹 Cleaning everything...
flutter clean
cd android
gradlew clean
cd ..

echo 📦 Getting dependencies...
flutter pub get

echo 🔄 Syncing Gradle...
cd android
gradlew --refresh-dependencies
cd ..

echo 🔨 Building release APK with R8 fixes...
flutter build apk --release --target-platform android-arm64

if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful!
    echo 📱 APK location: build\app\outputs\flutter-apk\app-release.apk
    echo 📏 APK size: 
    dir build\app\outputs\flutter-apk\app-release.apk
) else (
    echo ❌ Build failed!
    echo 💡 Check the missing_rules.txt file for additional rules
)

pause 