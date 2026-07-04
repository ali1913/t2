#!/bin/bash
# Exit instantly if any command fails
set -e

echo "📦 Setting up pristine Flutter project architecture..."
flutter create --org com.example .

echo "📥 Getting package dependencies..."
flutter pub get

echo "🏗️ Starting compilation process..."
flutter build apk --release

echo "✅ Build complete! Copying APK to your host computer folder..."
