#!/bin/bash

echo "🚀 Building optimized release APK..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build optimized release APK
echo "🔨 Building release APK with optimizations..."
flutter build apk --release --target-platform android-arm64

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo "📏 APK size: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
else
    echo "❌ Build failed!"
    exit 1
fi

echo "🎉 Release APK ready for distribution!" 