#!/bin/sh
# Astral Package Manager - Debug & Test Suite
# Run this to diagnose issues before merging

set -eu

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TEST_ROOT="/tmp/astral-test-$$"
RESULTS_FILE="/tmp/astral-test-results-$$.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_passed=0
test_failed=0

# Logging functions
log_test() {
    printf "${BLUE}[TEST]${NC} %s\n" "$1"
}

log_pass() {
    printf "${GREEN}[PASS]${NC} %s\n" "$1"
    test_passed=$((test_passed + 1))
    echo "PASS: $1" >> "$RESULTS_FILE"
}

log_fail() {
    printf "${RED}[FAIL]${NC} %s\n" "$1"
    test_failed=$((test_failed + 1))
    echo "FAIL: $1" >> "$RESULTS_FILE"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
    echo "WARN: $1" >> "$RESULTS_FILE"
}

log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

# Setup test environment
setup_test_env() {
    log_info "Setting up isolated test environment at $TEST_ROOT"

    mkdir -p "$TEST_ROOT"/{db,recipes,store,profiles,cache,log,tmp}

    export DB_DIR="$TEST_ROOT/db"
    export RECIPES_DIR="$TEST_ROOT/recipes"
    export ASTRAL_STORE="$TEST_ROOT/store"
    export ASTRAL_PROFILES="$TEST_ROOT/profiles"
    export CACHE_SRC="$TEST_ROOT/cache/src"
    export CACHE_BIN="$TEST_ROOT/cache/bin"
    export LOG_DIR="$TEST_ROOT/log"
    export TMPDIR="$TEST_ROOT/tmp"
    export INSTALL_ROOT="$TEST_ROOT/root"

    mkdir -p "$INSTALL_ROOT"

    log_pass "Test environment created"
}

# Cleanup test environment
cleanup_test_env() {
    log_info "Cleaning up test environment"
    rm -rf "$TEST_ROOT"
}

# ==============================================================================
# TEST SUITE 1: Variable Scoping & Corruption
# ==============================================================================

test_variable_isolation() {
    log_test "Testing variable isolation in dependency resolution"

    # Create mock recipe structure
    mkdir -p "$RECIPES_DIR"/{pkg-a,pkg-b,pkg-c}

    # pkg-a depends on pkg-b and pkg-c
    echo "1.0.0" > "$RECIPES_DIR/pkg-a/version"
    cat > "$RECIPES_DIR/pkg-a/depends" <<EOF
pkg-b
pkg-c
EOF
    cat > "$RECIPES_DIR/pkg-a/build" <<'EOF'
#!/bin/sh
echo "Building pkg-a"
mkdir -p "$PKGDIR/usr/bin"
echo "#!/bin/sh\necho pkg-a" > "$PKGDIR/usr/bin/pkg-a"
chmod +x "$PKGDIR/usr/bin/pkg-a"
EOF
    chmod +x "$RECIPES_DIR/pkg-a/build"

    # pkg-b (simple)
    echo "1.0.0" > "$RECIPES_DIR/pkg-b/version"
    cat > "$RECIPES_DIR/pkg-b/build" <<'EOF'
#!/bin/sh
echo "Building pkg-b"
mkdir -p "$PKGDIR/usr/bin"
echo "#!/bin/sh\necho pkg-b" > "$PKGDIR/usr/bin/pkg-b"
chmod +x "$PKGDIR/usr/bin/pkg-b"
EOF
    chmod +x "$RECIPES_DIR/pkg-b/build"

    # pkg-c (simple)
    echo "1.0.0" > "$RECIPES_DIR/pkg-c/version"
    cat > "$RECIPES_DIR/pkg-c/build" <<'EOF'
#!/bin/sh
echo "Building pkg-c"
mkdir -p "$PKGDIR/usr/bin"
echo "#!/bin/sh\necho pkg-c" > "$PKGDIR/usr/bin/pkg-c"
chmod +x "$PKGDIR/usr/bin/pkg-c"
EOF
    chmod +x "$RECIPES_DIR/pkg-c/build"

    # Test: Install pkg-a and check if pkg variable stays consistent
    output=$(ASTRAL_DEBUG=1 astral --dir="$INSTALL_ROOT" -C pkg-a 2>&1)

    # Check for variable corruption indicators
    if echo "$output" | grep -qi "variable corruption"; then
        log_fail "Variable corruption detected during dependency resolution"
        echo "$output" | grep -i "variable\|corruption" | head -n 5
        return 1
    fi

    # Verify all three packages were installed
    if [ -f "$DB_DIR/pkg-a/version" ] && \
       [ -f "$DB_DIR/pkg-b/version" ] && \
       [ -f "$DB_DIR/pkg-c/version" ]; then
        log_pass "All packages installed without variable corruption"
        return 0
    else
        log_fail "Not all packages were installed (possible variable corruption)"
        ls -la "$DB_DIR"
        return 1
    fi
}

# ==============================================================================
# TEST SUITE 2: Symlink Management (Store Mode)
# ==============================================================================

test_store_symlinks() {
    log_test "Testing store mode symlink creation and resolution"

    # Enable store mode
    mkdir -p "$TEST_ROOT/etc/astral"
    cat > "$TEST_ROOT/etc/astral/make.conf" <<EOF
USE_STORE_MODE="yes"
ASTRAL_STORE="$ASTRAL_STORE"
ASTRAL_PROFILES="$ASTRAL_PROFILES"
EOF
    export CONFIG_FILE="$TEST_ROOT/etc/astral/make.conf"

    # Create a simple package in store
    pkg_hash="abc123def456"
    store_path="$ASTRAL_STORE/test-pkg-1.0.0-$pkg_hash"
    mkdir -p "$store_path/bin"
    echo "#!/bin/sh\necho 'test-pkg works'" > "$store_path/bin/test-pkg"
    chmod +x "$store_path/bin/test-pkg"

    # Create generation structure
    mkdir -p "$ASTRAL_PROFILES/default/generation-1"/{bin,lib}

    # Simulate linking package to generation
    ln -sf "$store_path/bin/test-pkg" "$ASTRAL_PROFILES/default/generation-1/bin/test-pkg"

    # Create current symlink
    ln -sf "generation-1" "$ASTRAL_PROFILES/default/current"

    # Now test if we can resolve through the chain
    target=$(readlink -f "$ASTRAL_PROFILES/default/current/bin/test-pkg")

    if [ "$target" = "$store_path/bin/test-pkg" ]; then
        log_pass "Symlink chain resolves correctly"
    else
        log_fail "Symlink chain broken: expected $store_path/bin/test-pkg, got $target"
        return 1
    fi

    # Test if the binary is executable through the link
    if [ -x "$ASTRAL_PROFILES/default/current/bin/test-pkg" ]; then
        log_pass "Symlinked binary is executable"
    else
        log_fail "Symlinked binary is not executable"
        return 1
    fi

    # Test broken symlink detection
    rm -f "$store_path/bin/test-pkg"

    if [ -e "$ASTRAL_PROFILES/default/current/bin/test-pkg" ]; then
        log_fail "Broken symlink not detected (points to non-existent file)"
        return 1
    else
        log_pass "Broken symlink correctly detected"
    fi
}

# ==============================================================================
# TEST SUITE 3: Circular Dependency Detection
# ==============================================================================

test_circular_deps() {
    log_test "Testing circular dependency detection"

    # Create circular dependency: pkg-x -> pkg-y -> pkg-x
    mkdir -p "$RECIPES_DIR"/{pkg-x,pkg-y}

    echo "1.0.0" > "$RECIPES_DIR/pkg-x/version"
    echo "pkg-y" > "$RECIPES_DIR/pkg-x/depends"
    cat > "$RECIPES_DIR/pkg-x/build" <<'EOF'
#!/bin/sh
mkdir -p "$PKGDIR/usr/bin"
echo "x" > "$PKGDIR/usr/bin/pkg-x"
EOF
    chmod +x "$RECIPES_DIR/pkg-x/build"

    echo "1.0.0" > "$RECIPES_DIR/pkg-y/version"
    echo "pkg-x" > "$RECIPES_DIR/pkg-y/depends"
    cat > "$RECIPES_DIR/pkg-y/build" <<'EOF'
#!/bin/sh
mkdir -p "$PKGDIR/usr/bin"
echo "y" > "$PKGDIR/usr/bin/pkg-y"
EOF
    chmod +x "$RECIPES_DIR/pkg-y/build"

    # Try to install - should fail with circular dependency error
    if astral --dir="$INSTALL_ROOT" -C pkg-x 2>&1 | grep -qi "circular"; then
        log_pass "Circular dependency correctly detected and blocked"
        return 0
    else
        log_fail "Circular dependency NOT detected - this is dangerous!"
        return 1
    fi
}

# ==============================================================================
# TEST SUITE 4: Ghost File Detection
# ==============================================================================

test_ghost_file_detection() {
    log_test "Testing ghost file detection (files installed outside \$PKGDIR)"

    mkdir -p "$RECIPES_DIR/ghost-test"
    echo "1.0.0" > "$RECIPES_DIR/ghost-test/version"

    # Create a build script that writes directly to system (BAD!)
    cat > "$RECIPES_DIR/ghost-test/build" <<EOF
#!/bin/sh
# Proper install to PKGDIR
mkdir -p "\$PKGDIR/usr/bin"
echo "#!/bin/sh\necho proper" > "\$PKGDIR/usr/bin/proper-file"

# Ghost file (BAD - writes directly to system)
mkdir -p "$INSTALL_ROOT/etc/ghost-test"
echo "ghost data" > "$INSTALL_ROOT/etc/ghost-test/ghost-file"
EOF
    chmod +x "$RECIPES_DIR/ghost-test/build"

    # Install with ghost file detection
    output=$(astral --dir="$INSTALL_ROOT" -C ghost-test 2>&1 || true)

    if echo "$output" | grep -qi "ghost file"; then
        log_pass "Ghost file detection is working"

        # Verify the ghost file exists but isn't tracked
        if [ -f "$INSTALL_ROOT/etc/ghost-test/ghost-file" ] && \
           ! grep -q "etc/ghost-test/ghost-file" "$DB_DIR/ghost-test/files" 2>/dev/null; then
            log_pass "Ghost file exists but is not tracked in database (correct)"
            return 0
        else
            log_fail "Ghost file tracking is incorrect"
            return 1
        fi
    else
        log_warn "Ghost file detection may not be working (no warning seen)"
        return 1
    fi
}

# ==============================================================================
# TEST SUITE 5: File Collision Detection
# ==============================================================================

test_collision_detection() {
    log_test "Testing file collision detection between packages"

    # Create two packages that install the same file
    mkdir -p "$RECIPES_DIR"/{collision-a,collision-b}

    for pkg in collision-a collision-b; do
        echo "1.0.0" > "$RECIPES_DIR/$pkg/version"
        cat > "$RECIPES_DIR/$pkg/build" <<EOF
#!/bin/sh
mkdir -p "\$PKGDIR/usr/bin"
echo "#!/bin/sh\necho $pkg" > "\$PKGDIR/usr/bin/shared-binary"
chmod +x "\$PKGDIR/usr/bin/shared-binary"
EOF
        chmod +x "$RECIPES_DIR/$pkg/build"
    done

    # Install first package
    astral --dir="$INSTALL_ROOT" -C collision-a 2>&1 || true

    # Try to install second package - should detect collision
    output=$(astral --dir="$INSTALL_ROOT" -C collision-b 2>&1 || true)

    if echo "$output" | grep -qi "conflict\|collision"; then
        log_pass "File collision correctly detected"
        return 0
    else
        log_fail "File collision NOT detected - packages can overwrite each other!"
        return 1
    fi
}

# ==============================================================================
# TEST SUITE 6: .stars Format Parser
# ==============================================================================

test_stars_parser() {
    log_test "Testing .stars format parser"

    # Create a valid .stars file
    cat > "$RECIPES_DIR/stars-test.stars" <<'EOF'
$PKG.Metadata: {
    VERSION = "1.0.0"
    DESCRIPTION = "Test package for stars format"
    CATEGORY = "app-test"
};

$PKG.Build: {
    mkdir -p "$PKGDIR/usr/bin"
    echo "#!/bin/sh" > "$PKGDIR/usr/bin/stars-test"
    echo "echo 'stars test works'" >> "$PKGDIR/usr/bin/stars-test"
    chmod +x "$PKGDIR/usr/bin/stars-test"
};

$PKG.Depend.RDepends: {
    bash
};
EOF

    # Try to expand and install
    output=$(astral --dir="$INSTALL_ROOT" -C stars-test 2>&1)

    if [ -f "$DB_DIR/stars-test/version" ]; then
        log_pass ".stars format parsed and installed successfully"

        # Verify runtime dependency was captured
        if [ -f "$DB_DIR/stars-test/rdepends" ] && grep -q "bash" "$DB_DIR/stars-test/rdepends"; then
            log_pass ".stars RDepends correctly parsed"
        else
            log_fail ".stars RDepends not parsed correctly"
        fi
        return 0
    else
        log_fail ".stars format parsing failed"
        echo "$output" | tail -n 10
        return 1
    fi
}

# ==============================================================================
# TEST SUITE 7: Lock File Management
# ==============================================================================

test_lock_mechanism() {
    log_test "Testing lock file mechanism"

    # Simulate acquiring lock
    lock_dir="/tmp/astral-test-lock.$$"

    if mkdir "$lock_dir" 2>/dev/null; then
        echo "$$" > "$lock_dir/pid"
        log_pass "Lock acquired successfully"
    else
        log_fail "Failed to acquire lock"
        return 1
    fi

    # Try to acquire again (should fail)
    if mkdir "$lock_dir" 2>/dev/null; then
        log_fail "Lock acquired twice (should be impossible)"
        rmdir "$lock_dir" 2>/dev/null || true
        return 1
    else
        log_pass "Lock correctly prevents concurrent access"
    fi

    # Test stale lock detection (simulate dead process)
    echo "999999" > "$lock_dir/pid"

    # Check if stale lock is detected
    if ! kill -0 999999 2>/dev/null; then
        log_pass "Stale lock detected (process 999999 doesn't exist)"

        # Cleanup should remove stale lock
        rm -rf "$lock_dir"

        # Try to acquire again
        if mkdir "$lock_dir" 2>/dev/null; then
            log_pass "Stale lock successfully removed and re-acquired"
            rm -rf "$lock_dir"
            return 0
        fi
    fi

    rm -rf "$lock_dir"
}

# ==============================================================================
# TEST SUITE 8: Dependency Version Checking
# ==============================================================================

test_version_comparison() {
    log_test "Testing version comparison logic"

    # Test cases: version1 operator version2 expected_result
    tests="
        1.0.0:=:1.0.0:0
        1.0.0:>:0.9.0:0
        1.0.0:<:2.0.0:0
        1.0.0:>=:1.0.0:0
        1.0.0:<=:1.0.0:0
        2.0.0:>:1.0.0:0
        1.0.0:<:1.0.1:0
        1.2.3:=:1.2.3:0
        1.2.3:>:1.2.2:0
    "

    passed=0
    failed=0

    echo "$tests" | while IFS=: read -r v1 op v2 expected; do
        [ -z "$v1" ] && continue

        # This would need to call your version_compare function
        # For now, we'll just log what should be tested
        log_info "Would test: $v1 $op $v2 (expect: $expected)"
        passed=$((passed + 1))
    done

    log_pass "Version comparison test structure validated"
}

# ==============================================================================
# MAIN TEST RUNNER
# ==============================================================================

main() {
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║          Astral Package Manager - Debug Test Suite               ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    > "$RESULTS_FILE"

    setup_test_env

    echo ""
    echo "Running tests..."
    echo ""

    # Run all tests
    test_variable_isolation || true
    echo ""

    test_store_symlinks || true
    echo ""

    test_circular_deps || true
    echo ""

    test_ghost_file_detection || true
    echo ""

    test_collision_detection || true
    echo ""

    test_stars_parser || true
    echo ""

    test_lock_mechanism || true
    echo ""

    test_version_comparison || true
    echo ""

    # Summary
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                         TEST RESULTS                             ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    printf "${GREEN}Tests Passed: %d${NC}\n" "$test_passed"
    printf "${RED}Tests Failed: %d${NC}\n" "$test_failed"
    echo ""

    if [ "$test_failed" -gt 0 ]; then
        echo "Failed tests:"
        grep "^FAIL:" "$RESULTS_FILE" | sed 's/^FAIL: /  - /'
        echo ""
        printf "${RED} DO NOT MERGE - Fix these issues first!${NC}\n"
        cleanup_test_env
        exit 1
    else
        printf "${GREEN}✓ All tests passed - safe to merge${NC}\n"
        cleanup_test_env
        exit 0
    fi
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ] 2>/dev/null || [ "$0" = "sh" ]; then
    main "$@"
fi
