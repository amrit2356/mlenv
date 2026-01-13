Name:           mlenv
Version:        2.0.0
Release:        1%{?dist}
Summary:        ML Environment Manager - GPU Container Management

License:        MIT
URL:            https://github.com/your-username/mlenv
Source0:        %{name}-%{version}.tar.gz

BuildArch:      x86_64
Requires:       docker >= 20.10, sqlite >= 3.0, bash >= 4.0
Recommends:     jq, nvidia-container-toolkit

%description
MLEnv is a production-grade command-line tool for managing NVIDIA
GPU-accelerated Docker containers for deep learning and scientific computing.

Features:
- Zero-config GPU access with automatic detection
- VS Code Dev Containers integration
- Smart Jupyter Lab management
- Resource monitoring and admission control
- NGC container catalog integration
- Project templates for quick start
- Crash prevention with safety checks

%prep
%setup -q

%build
# Nothing to build (bash scripts)

%install
rm -rf $RPM_BUILD_ROOT

# Create directories
mkdir -p $RPM_BUILD_ROOT/usr/local/bin
mkdir -p $RPM_BUILD_ROOT/usr/local/lib/mlenv
mkdir -p $RPM_BUILD_ROOT/etc/mlenv
mkdir -p $RPM_BUILD_ROOT/usr/local/share/mlenv
mkdir -p $RPM_BUILD_ROOT/var/mlenv/registry

# Install files
cp bin/mlenv $RPM_BUILD_ROOT/usr/local/bin/
cp -r lib/mlenv/* $RPM_BUILD_ROOT/usr/local/lib/mlenv/
cp etc/mlenv/mlenv.conf $RPM_BUILD_ROOT/etc/mlenv/
cp -r share/mlenv/* $RPM_BUILD_ROOT/usr/local/share/mlenv/

%post
echo "Setting up MLEnv..."

# Create necessary directories
mkdir -p /var/mlenv/registry
mkdir -p /var/mlenv/cache
mkdir -p /var/mlenv/plugins

# Set proper permissions
chmod 755 /usr/local/bin/mlenv
chmod 755 /usr/local/lib/mlenv/core/*.sh
chmod 755 /usr/local/lib/mlenv/adapters/*/*.sh

# Initialize database
if [ -f /usr/local/lib/mlenv/database/init.sh ]; then
    export MLENV_LIB=/usr/local/lib/mlenv
    export MLENV_VAR=/var/mlenv
    source /usr/local/lib/mlenv/utils/logging.sh
    source /usr/local/lib/mlenv/database/init.sh
    
    db_init >/dev/null 2>&1 || true
fi

echo "MLEnv installed successfully!"
echo ""
echo "Quick start:"
echo "  1. Verify: mlenv version"
echo "  2. Check: docker info"
echo "  3. Create: mlenv init --template pytorch my-project"
echo ""

%postun
if [ $1 -eq 0 ]; then
    # Uninstall
    rm -rf /var/mlenv
fi

%files
%defattr(-,root,root,-)
/usr/local/bin/mlenv
/usr/local/lib/mlenv/*
%config(noreplace) /etc/mlenv/mlenv.conf
/usr/local/share/mlenv/*
%dir /var/mlenv

%changelog
* Mon Jan 13 2025 MLEnv Team <mlenv@example.com> - 2.0.0-1
- Complete rewrite with modular architecture
- Added NGC registry integration
- Added resource monitoring and admission control
- Added project templates
- Added auto GPU detection

* Mon Jan 01 2024 MLEnv Team <mlenv@example.com> - 1.1.0-1
- Initial RPM package
