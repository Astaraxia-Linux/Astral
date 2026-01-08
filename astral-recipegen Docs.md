# Astral `.stars` Format Specification v3

> *"Now with 100% more dependency separation!"*

Version: 3.0  
Last Updated: 8 January 2026  
For: Astral Package Manager

---

## Quick Reference

**Too lazy to read?** Use [astral-recipegen](https://github.com/Astaraxia-Linux/Astral/blob/main/astral-recipegen):

```bash
astral-recipegen interactive v3
```

Done. You're welcome.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Format Versions](#format-versions)
3. [v3 Format Specification](#v3-format-specification)
4. [v2 Format (Legacy)](#v2-format-legacy)
5. [v1 Format (Deprecated)](#v1-format-deprecated)
6. [Migration Guide](#migration-guide)
7. [Examples](#examples)
8. [Best Practices](#best-practices)

---

## Introduction

### What is .stars Format?

The `.stars` format is a structured, type-safe way to define package recipes for Astral package manager. After a sleepless night and 2 shots of espresso, the Astaraxia devs made this possible.

### Why Three Formats?

Good question. Here's the timeline:
- **v1**: Created in a caffeine-induced haze
- **v2**: "Let's make it better!" (narrator: they did)
- **v3**: "But what about separating build and runtime deps?" (perfection achieved)

We support all three because breaking backwards compatibility is mean.

---

## Format Versions

### Version Detection

Astral automatically detects the format version:

```bash
# v3: Has version marker
$PKG.Version = "3"

# v2: Uses $PKG.* declarations
$PKG.Metadata: { ... }

# v1: Uses @SECTION markers
@BUILD
```

### Which Should I Use?

| Format | Status | Use When |
|--------|--------|----------|
| v3 | ✅ Recommended | Always (if starting fresh) |
| v2 | ⚠️ Supported | Existing recipes, gradual migration |
| v1 | 🗿 Deprecated | Maintaining ancient recipes |

**TL;DR**: Use v3. Just do it.

---

## v3 Format Specification

### Structure Overview

```bash
$PKG.Version = "3"                  # Format version marker

$PKG.Metadata: { ... };             # Package metadata
$PKG.Depend.BDepends: { ... };      # Build dependencies
$PKG.Depend.RDepends: { ... };      # Runtime dependencies
$PKG.Depend.Optional: { ... };      # Optional dependencies
$PKG.Sources: { ... };              # Source URLs
$PKG.Checksums: { ... };            # File checksums
$PKG.Build: { ... };                # Build instructions
$PKG.Package: { ... };              # Installation instructions
$PKG.PostInstall: { ... };          # Post-install hooks
$PKG.PostRemove: { ... };           # Post-remove hooks
```

---

### 1. Version Marker

**Required**: Yes (for v3)  
**Format**: `$PKG.Version = "3"`

```bash
$PKG.Version = "3"
```

This tells Astral "hey, I'm using the fancy new format with separated dependencies!"

---

### 2. Metadata Section

**Required**: Yes  
**Format**: `$PKG.Metadata: { KEY = "VALUE" };`

```bash
$PKG.Metadata: {
    Version = "1.2.3"
    Description = "A cool package that does cool things"
    Homepage = "https://example.com"
    Category = "app-editors"
    License = "GPL-3.0"
    Maintainer = "Your Name <email@example.com>"
};
```

**Available Keys**:
- `Version` (required): Package version (e.g., "1.2.3")
- `Description` (optional): One-line description
- `Homepage` (optional): Project homepage URL
- `Category` (optional): Package category (e.g., sys-libs, dev-util)
- `License` (optional): Software license (e.g., GPL-3.0, MIT)
- `Maintainer` (optional): Recipe maintainer info

**Note**: Keys are now capitalized in v3 (unlike v2's ALL_CAPS).

---

### 3. Build Dependencies (BDepends)

**Required**: No  
**Format**: `$PKG.Depend.BDepends: { dependencies };`

Build-time dependencies are **removed after building**. Perfect for compilers and build tools.

```bash
$PKG.Depend.BDepends: {
    gcc >= 11.0
    make
    cmake >= 3.20
    pkg-config
    autoconf
    automake
};
```

**What Goes Here**:
- Compilers (gcc, clang, rustc)
- Build systems (make, cmake, meson, ninja)
- Build tools (autoconf, automake, libtool)
- Code generators (bison, flex)

**Version Constraints**:
```bash
gcc >= 11.0      # Minimum version
python = 3.11    # Exact version
cmake <= 3.25    # Maximum version
make             # Any version
```

**Operators**: `=`, `>=`, `<=`, `>`, `<`

---

### 4. Runtime Dependencies (RDepends)

**Required**: No  
**Format**: `$PKG.Depend.RDepends: { dependencies };`

Runtime dependencies **stay forever**. These are what your package needs to actually run.

```bash
$PKG.Depend.RDepends: {
    glibc >= 2.35
    ncurses >= 6.0
    readline
    openssl >= 3.0
};
```

**What Goes Here**:
- Libraries (ncurses, readline, openssl)
- Runtime interpreters (python, perl)
- Required utilities
- Dynamic linker dependencies

---

### 5. Optional Dependencies

**Required**: No  
**Format**: `$PKG.Depend.Optional: { dependencies };`

Optional features. User can skip these during installation.

```bash
$PKG.Depend.Optional: {
    bash-completion
    man-db
    documentation
};
```

**Use Cases**:
- Shell completions
- Documentation packages
- Extra features
- Recommended but not required packages

---

### 6. Sources Section

**Required**: Yes (if downloading files)  
**Format**: `$PKG.Sources: { urls = "..." };`

```bash
$PKG.Sources: {
    urls = "https://example.com/package-1.2.3.tar.gz"
};
```

**Multiple Sources**:
```bash
$PKG.Sources: {
    urls = "https://example.com/source.tar.gz"
    urls = "https://example.com/patch-001.patch"
    urls = "https://mirror.com/source.tar.gz"
};
```

**Git Sources**:
```bash
$PKG.Sources: {
    urls = "git+https://github.com/user/repo.git#branch=main"
};
```

**Git Syntax**:
- `git+<url>#branch=<name>` - Clone specific branch
- `git+<url>#commit=<hash>` - Clone specific commit
- `git+<url>#tag=<tag>` - Clone specific tag

---

### 7. Checksums Section

**Required**: No (but highly recommended)  
**Format**: `$PKG.Checksums: { algorithm:hash filename };`

```bash
$PKG.Checksums: {
    sha256:fb53c30b58a81fe0b3b4e64aedb9a53311ddda301ec9c1c2b42d659e50f5e13a package-1.2.3.tar.gz
};
```

**Supported Algorithms**:
- `sha256` (recommended)
- `sha512` (paranoid level)
- `md5` (please don't, it's 2026)

**Multiple Files**:
```bash
$PKG.Checksums: {
    sha256:abc123... source.tar.gz
    sha256:def456... patch-001.patch
};
```

**Git Sources**: No checksums needed (Git handles integrity).

---

### 8. Build Section

**Required**: Yes  
**Format**: `$PKG.Build: { script };`

```bash
$PKG.Build: {
    cd package-1.2.3
    ./configure --prefix=/usr --sysconfdir=/etc
    make -j$(nproc)
};
```

**Architecture-Specific Builds**:
```bash
$PKG.Build [IF arch=x86_64]: {
    ./configure --prefix=/usr --enable-sse4 --enable-avx2
    make -j$(nproc)
};

$PKG.Build [IF arch=aarch64]: {
    ./configure --prefix=/usr --enable-neon
    make -j$(nproc)
};

$PKG.Build [IF arch=riscv64]: {
    ./configure --prefix=/usr --disable-asm
    make
};
```

**Available Conditions**:
- `[IF arch=x86_64]` - Intel/AMD 64-bit
- `[IF arch=aarch64]` - ARM 64-bit
- `[IF arch=riscv64]` - RISC-V 64-bit
- `[IF arch=i686]` - Intel/AMD 32-bit (if anyone still uses this)

**Environment Variables**:
- `$PKGDIR` or `$DESTDIR`: Installation staging directory
- `$CFLAGS`, `$CXXFLAGS`, `$LDFLAGS`: Compiler flags
- `$MAKEFLAGS`: Make parallelism (from make.conf)

---

### 9. Package Section

**Required**: No (but highly recommended)  
**Format**: `$PKG.Package: { script };`

```bash
$PKG.Package: {
    cd package-1.2.3
    make DESTDIR="$PKGDIR" install
    
    # Install additional files
    install -Dm644 README.md "$PKGDIR/usr/share/doc/$PKG/README"
    install -Dm644 LICENSE "$PKGDIR/usr/share/licenses/$PKG/LICENSE"
    
    # Create symlinks
    ln -sf package "$PKGDIR/usr/bin/pkg"
};
```

**Purpose**: Install built files into `$PKGDIR` (staging directory).

**Important**: Always use `$PKGDIR`, never install directly to `/usr`!

---

### 10. Post-Install Section

**Required**: No  
**Format**: `$PKG.PostInstall: { script };`

```bash
$PKG.PostInstall: {
    # Update system caches
    ldconfig
    update-desktop-database
    
    # Generate files
    glib-compile-schemas /usr/share/glib-2.0/schemas
    
    echo "Package installed successfully!"
    echo "Run 'man package' for help"
};
```

**Purpose**: System updates after installation.

**Common Tasks**:
- Update `ldconfig` cache
- Compile schemas
- Update icon/mime databases
- Print helpful messages

---

### 11. Post-Remove Section

**Required**: No  
**Format**: `$PKG.PostRemove: { script };`

```bash
$PKG.PostRemove: {
    echo "Package removed."
    echo "Configuration files remain in /etc/"
};
```

**Purpose**: Cleanup after package removal.

---

## v2 Format (Legacy)

### Overview

v2 uses `$PKG.*` syntax but doesn't separate build/runtime dependencies.

```bash
$PKG.Metadata: {
    VERSION = "1.0.0"
    DESCRIPTION = "Package description"
    HOMEPAGE = "https://example.com"
    CATEGORY = "app-misc"
};

$PKG.Depend {
    $PKG.Depend.Depends {
        gcc
        make
        ncurses
        readline
    };
};

$PKG.Sources {
    urls = "https://example.com/source.tar.gz"
};

$PKG.Checksums {
    sha256:abc123... source.tar.gz
};

$PKG.Build {
    ./configure --prefix=/usr
    make -j$(nproc)
};

$PKG.Package {
    make DESTDIR="$PKGDIR" install
};
```

**Key Differences from v3**:
- No version marker
- `ALL_CAPS` metadata keys
- Combined dependencies in `Depends`
- No Optional dependencies

**Status**: Still supported, use for existing recipes.

---

## v1 Format (Deprecated)

### Overview

The original format. Simple, but limited.

```bash
VERSION="1.0.0"
DESCRIPTION="Package description"
HOMEPAGE="https://example.com"

@DEPENDS
gcc
make
ncurses

@SOURCES
https://example.com/source.tar.gz

@CHECKSUMS
sha256:abc123... source.tar.gz

@BUILD
./configure --prefix=/usr
make -j$(nproc)

@PACKAGE
make DESTDIR="$PKGDIR" install

@POST_INSTALL
echo "Installed!"
```

**Status**: Deprecated. Migrate to v3 using `astral-recipegen migrate`.

---

## Migration Guide

### v1 → v3

```bash
astral-recipegen migrate old-recipe.stars v3
```

**Manual Migration**:

**Before (v1)**:
```bash
VERSION="1.2.3"
@DEPENDS
gcc
make
ncurses
```

**After (v3)**:
```bash
$PKG.Version = "3"

$PKG.Metadata: {
    Version = "1.2.3"
};

$PKG.Depend.BDepends: {
    gcc
    make
};

$PKG.Depend.RDepends: {
    ncurses
};
```

---

### v2 → v3

```bash
astral-recipegen migrate recipe.stars v3
```

**Manual Migration**:

**Before (v2)**:
```bash
$PKG.Depend {
    $PKG.Depend.Depends {
        gcc
        make
        ncurses
    };
};
```

**After (v3)**:
```bash
$PKG.Depend.BDepends: {
    gcc
    make
};

$PKG.Depend.RDepends: {
    ncurses
};
```

---

### Directory Recipe → v3

```bash
astral-recipegen dir-to-stars /path/to/recipe v3
```

Converts directory-based recipes (with separate `build`, `depends` files) to `.stars` format.

---

## Examples

### Example 1: Simple Autotools Package

```bash
$PKG.Version = "3"

$PKG.Metadata: {
    Version = "2.7.6"
    Description = "GNU patch utility"
    Homepage = "https://savannah.gnu.org/projects/patch/"
    Category = "sys-devel"
    License = "GPL-3.0"
};

$PKG.Depend.BDepends: {
    gcc
    make
};

$PKG.Depend.RDepends: {
    glibc
};

$PKG.Sources: {
    urls = "https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz"
};

$PKG.Checksums: {
    sha256:ac610bda97abe0d9f6b7c963255a11dcb196c25e337c61f94e4778d632f1d8fd patch-2.7.6.tar.xz
};

$PKG.Build: {
    cd patch-2.7.6
    ./configure --prefix=/usr
    make -j$(nproc)
};

$PKG.Package: {
    cd patch-2.7.6
    make DESTDIR="$PKGDIR" install
};
```

---

### Example 2: CMake Package with Optional Deps

```bash
$PKG.Version = "3"

$PKG.Metadata: {
    Version = "3.28.1"
    Description = "Cross-platform build system"
    Homepage = "https://cmake.org"
    Category = "dev-util"
};

$PKG.Depend.BDepends: {
    gcc
    make
};

$PKG.Depend.RDepends: {
    glibc
    ncurses
    curl
};

$PKG.Depend.Optional: {
    qt5
    sphinx
};

$PKG.Sources: {
    urls = "https://cmake.org/files/v3.28/cmake-3.28.1.tar.gz"
};

$PKG.Checksums: {
    sha256:15e94f83e647f7d620a140a7a5da76349fc47a1bfed66d0f5cdee8e7344079ad cmake-3.28.1.tar.gz
};

$PKG.Build: {
    cd cmake-3.28.1
    ./bootstrap --prefix=/usr --parallel=$(nproc)
    make -j$(nproc)
};

$PKG.Package: {
    cd cmake-3.28.1
    make DESTDIR="$PKGDIR" install
};
```

---

### Example 3: Git Repository

```bash
$PKG.Version = "3"

$PKG.Metadata: {
    Version = "0.10.0"
    Description = "Hyperextensible Vim-based text editor"
    Homepage = "https://neovim.io"
    Category = "app-editors"
};

$PKG.Depend.BDepends: {
    git
    gcc
    cmake
    ninja
};

$PKG.Depend.RDepends: {
    glibc
    libtermkey
    libuv
    msgpack-c
};

$PKG.Sources: {
    urls = "git+https://github.com/neovim/neovim.git#tag=v0.10.0"
};

$PKG.Checksums: {
    # Git sources don't need checksums
};

$PKG.Build: {
    cd neovim
    mkdir -p build
    cd build
    cmake .. -GNinja -DCMAKE_INSTALL_PREFIX=/usr
    ninja
};

$PKG.Package: {
    cd neovim/build
    DESTDIR="$PKGDIR" ninja install
};
```

---

### Example 4: Architecture-Specific

```bash
$PKG.Version = "3"

$PKG.Metadata: {
    Version = "13.2.0"
    Description = "GNU Compiler Collection"
    Homepage = "https://gcc.gnu.org"
    Category = "sys-devel"
};

$PKG.Depend.BDepends: {
    make
    binutils
    gmp
    mpfr
    mpc
};

$PKG.Build [IF arch=x86_64]: {
    cd gcc-13.2.0
    ./configure \\
        --prefix=/usr \\
        --enable-languages=c,c++ \\
        --enable-shared \\
        --enable-threads=posix \\
        --enable-multiarch \\
        --enable-cet
    make -j$(nproc)
};

$PKG.Build [IF arch=aarch64]: {
    cd gcc-13.2.0
    ./configure \\
        --prefix=/usr \\
        --enable-languages=c,c++ \\
        --enable-shared \\
        --enable-threads=posix \\
        --disable-multiarch
    make -j$(nproc)
};

$PKG.Package: {
    cd gcc-13.2.0
    make DESTDIR="$PKGDIR" install
    
    # Remove conflicting files
    rm -f "$PKGDIR/usr/lib/libstdc++.so.6"
};
```

---

## Best Practices

### 1. Always Use v3 for New Recipes

Just do it. Future you will thank present you.

### 2. Separate Build and Runtime Deps

```bash
# Good
$PKG.Depend.BDepends: {
    gcc
    make
};

$PKG.Depend.RDepends: {
    ncurses
};

# Bad (v2 style in v3)
$PKG.Depend.Depends: {
    gcc
    make
    ncurses
};
```

### 3. Include Checksums

```bash
# Good
$PKG.Checksums: {
    sha256:abc123... source.tar.gz
};

# Bad (no checksum)
$PKG.Checksums: {
    # TODO: Add checksum
};
```

### 4. Use Version Constraints When Needed

```bash
# Good (when compatibility matters)
$PKG.Depend.RDepends: {
    python >= 3.10
    openssl >= 3.0
};

# Acceptable (when any version works)
$PKG.Depend.RDepends: {
    zlib
};
```

### 5. Never Install Directly to /

```bash
# Good
$PKG.Package: {
    make DESTDIR="$PKGDIR" install
};

# Bad (will break your system)
$PKG.Package: {
    make install
};
```

### 6. Keep Build Scripts Simple

```bash
# Good
$PKG.Build: {
    cd package-1.2.3
    ./configure --prefix=/usr
    make -j$(nproc)
};

# Bad (complex logic belongs upstream)
$PKG.Build: {
    if [ -f configure ]; then
        ./configure
    else
        cmake .
    fi
    # ... 50 more lines of bash spaghetti
};
```

---

## Troubleshooting

### Syntax Errors

Common mistakes:

```bash
# Wrong: Missing quotes
Version = 1.0.0

# Correct
Version = "1.0.0"

# Wrong: Forgot closing brace
$PKG.Build: {
    make

# Correct
$PKG.Build: {
    make
};
```

### Recipe Not Detected as v3

Make sure the first line is:

```bash
$PKG.Version = "3"
```

### Dependencies Still Combined

You're using v2 syntax in a v3 file:

```bash
# Wrong (v2 style)
$PKG.Depend {
    $PKG.Depend.Depends {
        gcc
    };
};

# Correct (v3 style)
$PKG.Depend.BDepends: {
    gcc
};
```

---

## See Also

- [Astral Documentation](README.md)
- [astral-recipegen Documentation](RECIPEGEN.md)
- [Contributing Guide](CONTRIBUTING.md)

---

**Last updated**: January 2026  
**Version**: 3.0  
**Status**: Official Specification

> *"Three formats enter, one format leaves"*  
> — Mad Max: Dependency Road
