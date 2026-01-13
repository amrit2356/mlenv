#!/bin/bash
# Build Debian package for MLEnv

set -e

VERSION="2.0.0"
PACKAGE_NAME="mlenv_${VERSION}_amd64"
BUILD_DIR="$(pwd)/packaging/deb-build"
PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"

echo "Building MLEnv Debian package v$VERSION..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Create directory structure
mkdir -p "$PACKAGE_DIR/usr/local/bin"
mkdir -p "$PACKAGE_DIR/usr/local/lib/mlenv"
mkdir -p "$PACKAGE_DIR/etc/mlenv"
mkdir -p "$PACKAGE_DIR/usr/local/share/mlenv"
mkdir -p "$PACKAGE_DIR/var/mlenv/registry"
mkdir -p "$PACKAGE_DIR/DEBIAN"

# Copy files
echo "Copying files..."

# Binary
cp bin/mlenv "$PACKAGE_DIR/usr/local/bin/"

# Libraries
cp -r lib/mlenv/* "$PACKAGE_DIR/usr/local/lib/mlenv/"

# Configuration
cp etc/mlenv/mlenv.conf "$PACKAGE_DIR/etc/mlenv/"

# Shared files
cp -r share/mlenv/* "$PACKAGE_DIR/usr/local/share/mlenv/"

# Control files
cp packaging/deb/DEBIAN/* "$PACKAGE_DIR/DEBIAN/"

# Set permissions
chmod 755 "$PACKAGE_DIR/DEBIAN/postinst"
chmod 755 "$PACKAGE_DIR/DEBIAN/prerm"
chmod 755 "$PACKAGE_DIR/DEBIAN/postrm"
chmod 755 "$PACKAGE_DIR/usr/local/bin/mlenv"

# Build package
echo "Building package..."
dpkg-deb --build "$PACKAGE_DIR"

# Move to packaging directory
mv "$BUILD_DIR/${PACKAGE_NAME}.deb" "packaging/"

echo ""
echo "✓ Package built: packaging/${PACKAGE_NAME}.deb"
echo ""
echo "Install with:"
echo "  sudo dpkg -i packaging/${PACKAGE_NAME}.deb"
echo "  sudo apt-get install -f  # Fix dependencies if needed"

# Clean up build directory
rm -rf "$BUILD_DIR"
