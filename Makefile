# MLEnv Makefile
# Version: 2.0.0

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib/mlenv
ETCDIR = /etc/mlenv
SHAREDIR = $(PREFIX)/share/mlenv
VARDIR = /var/mlenv

.PHONY: all install uninstall test clean help

all: help

help:
	@echo "MLEnv Build System"
	@echo ""
	@echo "Usage:"
	@echo "  make install      Install MLEnv to $(PREFIX)"
	@echo "  make uninstall    Remove MLEnv from $(PREFIX)"
	@echo "  make test         Run test suite"
	@echo "  make test-unit    Run unit tests"
	@echo "  make clean        Clean build artifacts"
	@echo "  make help         Show this help"
	@echo ""

install:
	@echo "Installing MLEnv to $(PREFIX)..."
	@echo ""
	
	# Create directories
	install -d $(BINDIR)
	install -d $(LIBDIR)
	install -d $(ETCDIR)
	install -d $(SHAREDIR)
	install -d $(VARDIR)
	
	# Install binaries
	@echo "Installing binaries..."
	install -m 0755 bin/mlenv $(BINDIR)/mlenv
	
	# Install libraries
	@echo "Installing libraries..."
	cp -r lib/mlenv/* $(LIBDIR)/
	chmod +x $(LIBDIR)/core/*.sh
	chmod +x $(LIBDIR)/adapters/*/*.sh
	chmod +x $(LIBDIR)/commands/*.sh 2>/dev/null || true
	
	# Install configuration
	@echo "Installing configuration..."
	install -m 0644 etc/mlenv/mlenv.conf $(ETCDIR)/mlenv.conf
	
	# Install shared files
	@echo "Installing templates and examples..."
	cp -r share/mlenv/* $(SHAREDIR)/
	
	# Install shell completions
	@if [ -d $(PREFIX)/share/bash-completion/completions ]; then \
		echo "Installing bash completions..."; \
		install -d $(PREFIX)/share/bash-completion/completions; \
	fi
	
	# Create var directories
	install -d $(VARDIR)/registry
	install -d $(VARDIR)/cache
	install -d $(VARDIR)/plugins
	
	@echo ""
	@echo "✓ MLEnv installed successfully!"
	@echo ""
	@echo "Try: mlenv help"

uninstall:
	@echo "Uninstalling MLEnv from $(PREFIX)..."
	rm -f $(BINDIR)/mlenv
	rm -rf $(LIBDIR)
	rm -rf $(ETCDIR)
	rm -rf $(SHAREDIR)
	@echo "✓ MLEnv uninstalled"
	@echo ""
	@echo "Note: $(VARDIR) preserved (contains user data)"

test: test-unit test-integration test-e2e
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "All tests complete! ✓"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test-unit:
	@echo "Running unit tests..."
	@echo ""
	@for test in tests/unit/test-*.sh; do \
		if [ -f "$$test" ]; then \
			bash "$$test" || exit 1; \
		fi \
	done

test-integration:
	@echo ""
	@echo "Running integration tests..."
	@echo ""
	@for test in tests/integration/test-*.sh; do \
		if [ -f "$$test" ]; then \
			bash "$$test" || exit 1; \
		fi \
	done

test-e2e:
	@echo ""
	@echo "Running end-to-end tests..."
	@echo ""
	@for test in tests/e2e/test-*.sh; do \
		if [ -f "$$test" ]; then \
			bash "$$test" || exit 1; \
		fi \
	done

test-config:
	@echo "Testing configuration system..."
	@bash tests/unit/test-config-parser.sh

clean:
	@echo "Cleaning build artifacts..."
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name ".DS_Store" -delete 2>/dev/null || true
	@echo "✓ Clean complete"

dev-install:
	@echo "Development install (symlinks)..."
	@echo ""
	@echo "Setting MLENV_LIB=$(PWD)/lib/mlenv"
	@echo ""
	@echo "Run: export MLENV_LIB=$(PWD)/lib/mlenv"
	@echo "Then: ./bin/mlenv help"

check:
	@echo "Checking prerequisites..."
	@command -v docker >/dev/null 2>&1 || { echo "✗ Docker not found"; exit 1; }
	@command -v sqlite3 >/dev/null 2>&1 || { echo "✗ sqlite3 not found"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "⚠ jq not found (optional)"; }
	@docker info >/dev/null 2>&1 || { echo "✗ Docker daemon not running"; exit 1; }
	@echo "✓ Prerequisites check passed"

version:
	@grep "^VERSION=" bin/mlenv | cut -d'"' -f2

build-deb:
	@echo "Building Debian package..."
	@chmod +x packaging/build-deb.sh
	@./packaging/build-deb.sh

build-rpm:
	@echo "Building RPM package..."
	@chmod +x packaging/build-rpm.sh
	@./packaging/build-rpm.sh

build-packages: build-deb
	@echo "✓ Packages built"

test-package:
	@echo "Testing DEB package installation..."
	@if [ -f packaging/mlenv_*.deb ]; then \
		sudo dpkg -i packaging/mlenv_*.deb || true; \
		sudo apt-get install -f -y; \
		mlenv version; \
	else \
		echo "No package found. Run 'make build-deb' first."; \
	fi

.PHONY: dev-install check version build-deb build-rpm build-packages test-package test-integration test-e2e
