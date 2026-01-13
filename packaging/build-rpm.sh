#!/bin/bash
# Build RPM package for MLEnv

set -e

VERSION="2.0.0"
PACKAGE_NAME="mlenv-${VERSION}"

echo "Building MLEnv RPM package v$VERSION..."

# Create rpmbuild directory structure
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create source tarball
echo "Creating source tarball..."
tar czf ~/rpmbuild/SOURCES/${PACKAGE_NAME}.tar.gz \
    --transform "s,^,${PACKAGE_NAME}/," \
    bin/ lib/ etc/ share/

# Copy spec file
cp packaging/rpm/mlenv.spec ~/rpmbuild/SPECS/

# Build RPM
echo "Building RPM..."
rpmbuild -ba ~/rpmbuild/SPECS/mlenv.spec

# Copy built RPM to packaging directory
mkdir -p packaging/rpm-build
cp ~/rpmbuild/RPMS/x86_64/mlenv-${VERSION}-1.*.rpm packaging/rpm-build/ 2>/dev/null || \
cp ~/rpmbuild/RPMS/x86_64/mlenv-${VERSION}-1.rpm packaging/rpm-build/ || true

echo ""
echo "✓ RPM package built"
echo ""
echo "Install with:"
echo "  sudo rpm -ivh packaging/rpm-build/mlenv-${VERSION}-1.*.rpm"
echo "or"
echo "  sudo yum install packaging/rpm-build/mlenv-${VERSION}-1.*.rpm"
