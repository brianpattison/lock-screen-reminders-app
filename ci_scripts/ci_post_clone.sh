#!/bin/sh

# ci_post_clone.sh
# Runs after Xcode Cloud clones the repository.
# Installs XcodeGen and regenerates the .xcodeproj from project.yml.

set -e

echo "Installing XcodeGen..."
brew install xcodegen

echo "Generating Xcode project..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "Xcode project generated successfully."
