# Astral Package Manager Documentation

> *"Because compiling from source should be less painful than a root canal"*

Version: 3.4.1.1 Main  
Last Updated: 7 January 2026 (GMT+8) 
Maintained by: One Maniac (yes, just one)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Basic Usage](#basic-usage)
4. [Recipe Formats](#recipe-formats)
5. [Package Management](#package-management)
6. [Dependency System](#dependency-system)
7. [Configuration](#configuration)
8. [Advanced Features](#advanced-features)
9. [Recipe Generator](#recipe-generator)
10. [Troubleshooting](#troubleshooting)
11. [Contributing](#contributing)

---

## Introduction

### What is Astral?

Astral is a minimal POSIX package manager for [Astaraxia Linux](https://github.com/Astaraxia-Linux/Astaraxia/). It builds packages from source because apparently, we hate ourselves enough to avoid binary packages. Think of it as Gentoo's Portage, but written by someone who values their sanity (debatable).

### Why Astral?

- **Source-based**: Because you *totally* want to compile everything
- **POSIX-compliant**: Works on any UNIX-like system (in theory)
- **Minimal dependencies**: Just `sh`, `curl`, and your tears
- **Four recipe formats**: dir, v1, v2, and v3 (because backwards compatibility is a thing)
- **Smart dependency resolution**: It won't delete your `/usr` (anymore :sob:)

### Why Not Astral?

- You value your time
- You have a slow computer
- You prefer binary packages
- You're a normal person

---

## Installation

### Prerequisites

You'll need:
- A POSIX-compliant shell (bash, dash, etc.)
- `curl` and/or `wget` (for downloading things)
- `sha256sum` (for paranoia)
- Root access (because `sudo`/`doas` is your friend)
- Coffee (not technically required, but highly recommended)

### Quick Install

```bash
# Clone the repository (or download the script)
curl -O https://raw.githubusercontent.com/Astaraxia-Linux/Astral/main/astral
chmod +x astral
sudo mv astral /usr/bin/

# Initialize directories
sudo astral --version  # This creates necessary directories
```

### Configuration

Create `/etc/astral/make.conf`:

```bash
# Build flags (adjust for your masochism level)
CFLAGS="-O2 -pipe -march=native"
CXXFLAGS="$CFLAGS"
MAKEFLAGS="-j$(nproc)"

# Enable ccache (because compiling twice is for chumps)
CCACHE_ENABLED="yes"

# Features
FEATURES="ccache parallel-make strip"
```

**Pro tip**: `-march=native` optimizes for your CPU. Don't use it if you're building for other machines, genius.

---

## Basic Usage

### Installing Packages

```bash
# Install from official repository (AOHARU)
sudo astral -S package-name

# Install from community overlay (ASURA)
sudo astral -SA package-name

# Build from local recipe
sudo astral -C category/package-name
```

### Removing Packages

```bash
# Remove package only
sudo astral -R package-name

# Remove package + orphaned dependencies
sudo astral -r package-name

# Remove all orphans (spring cleaning!)
sudo astral --autoremove
```

### Searching & Information

```bash
# Search for packages
astral -s nano

# Show package info
astral -I bash

# Show dependency tree
astral -D gcc

# Why is this installed?
astral -w readline
```

### System Maintenance

```bash
# Update repository indexes
sudo astral -u

# Upgrade all packages (grab some coffee)
sudo astral --Upgrade-All

# Clean cache
sudo astral -Cc

# Rebuild file index
sudo astral -RI
```

---

## Recipe Formats

Astral supports four recipe formats because we couldn't decide on one and now we're stuck with all four.

### Dir Format (Directory Based)

The Ancient format. Messy, spaghetti and deprecated (who uses these?)

- [Read here](https://github.com/Astaraxia-Linux/Astral/blob/main/Dir.md)

### v1 Format (@SECTION)

The OG format. Simple, clean, and deprecated.

```bash
VERSION="1.2.3"
DESCRIPTION="A cool package"
HOMEPAGE="https://example.com"

@DEPENDS
gcc
make

@SOURCES
https://example.com/package-1.2.3.tar.gz

@CHECKSUMS
sha256:abc123... package-1.2.3.tar.gz

@BUILD
./configure --prefix=/usr
make -j$(nproc)

@PACKAGE
make DESTDIR="$PKGDIR" install
```

**Use when**: You're feeling nostalgic or hate yourself.

### v2 Format ($PKG.*)

The current standard. More verbose, more powerful.

```bash
$PKG.Metadata: {
    VERSION = "1.2.3"
    DESCRIPTION = "A cool package"
    HOMEPAGE = "https://example.com"
    CATEGORY = "app-editors"
};

$PKG.Depend {
    $PKG.Depend.Depends {
        gcc
        make
        ncurses
    };
};

$PKG.Sources {
    urls = "https://example.com/package-1.2.3.tar.gz"
};

$PKG.Checksums {
    sha256:abc123... package-1.2.3.tar.gz
};

$PKG.Build {
    cd package-1.2.3
    ./configure --prefix=/usr
    make -j$(nproc)
};

$PKG.Package {
    cd package-1.2.3
    make DESTDIR="$PKGDIR" install
};
```

**Use when**: You want structure but don't need dependency separation.

### v3 Format (Separated Dependencies)

The future is now. Finally separates build-time and runtime dependencies.

```bash
$PKG.Version = "3"

$PKG.Metadata: {
    Version = "1.2.3"
    Description = "A cool package"
    Homepage = "https://example.com"
    Category = "app-editors"
};

$PKG.Depend.BDepends: {
    gcc
    make
};

$PKG.Depend.RDepends: {
    ncurses
    readline
};

$PKG.Depend.Optional: {
    bash-completion
};

$PKG.Sources: {
    urls = "https://example.com/package-1.2.3.tar.gz"
};

$PKG.Checksums: {
    sha256:abc123... package-1.2.3.tar.gz
};

$PKG.Build: {
    cd package-1.2.3
    ./configure --prefix=/usr
    make -j$(nproc)
};

$PKG.Package: {
    cd package-1.2.3
    make DESTDIR="$PKGDIR" install
};
```

**Use when**: You want a clean system without build tools polluting your runtime.

**Key differences**:
- `BDepends`: Build-time only (removed after build)
- `RDepends`: Runtime dependencies (kept forever)
- `Optional`: Nice-to-have features (user choice)

---

## Package Management

### The World Set

The "world set" is your list of explicitly installed packages. Think of it as your package wishlist, except you already got everything.

```bash
# List world set
astral -W

# Add to world (manual tracking)
echo "my-package" >> /var/lib/astral/db/world_set

# Remove from world
astral -R my-package  # Also removes from world
```

**Important**: Orphaned packages (not in world, not depended on) can be removed with `--autoremove`.

### Dependency Resolution

Astral uses recursive dependency resolution. It's like a family tree, but with software.

```bash
# Preview what will be installed
astral -p bash

# Interactive dependency selection
astral -S bash
# Shows a tree with:
# [✓✓] - Already installed
# [✓ ] - On host (can skip)
# [  ] - Will install
# [OPT] - Optional
```

**Pro tip**: Press Enter to install all, or type numbers to skip (e.g., `1 3 5`).

### Host Dependencies

Some packages might already be on your system. Astral checks:

1. `pkg-config` (most reliable)
2. Binary in `$PATH`
3. Shared library in `/lib`, `/usr/lib`, etc.
4. Your manually configured `HOST_PROVIDED` list

```bash
# Test if package is on host
astral --host-check gcc

# Show all host dependencies
astral --host-deps
```

---

## Dependency System

### Dependency Types (v3)

- **BDepends**: Build-time dependencies (gcc, make, cmake)
- **RDepends**: Runtime dependencies (libraries, interpreters)
- **Optional**: Extra features (bash-completion, docs)

### Versioned Dependencies

You can specify version constraints:

```
ncurses >= 6.0
readline = 8.2
python < 3.12
```

Operators: `=`, `>=`, `<=`, `>`, `<`

### Virtual Packages

Virtual packages provide alternatives:

```bash
# /etc/astral/virtuals/compiler
gcc
clang
tcc
```

If you request `virtual/compiler`, Astral checks if *any* provider is installed.

### Circular Dependencies

Astral detects circular dependencies and will yell at you:

```
ERROR: [pkg-a] CIRCULAR DEPENDENCY DETECTED! Chain: pkg-a -> pkg-b -> pkg-a
```

**Solution**: Fix your damn dependencies. Or cry. Both work.

---

## Configuration

### make.conf

Located at `/etc/astral/make.conf`:

```bash
# Compiler flags
CFLAGS="-O2 -pipe -march=native"
CXXFLAGS="$CFLAGS"
LDFLAGS="-Wl,--as-needed"
MAKEFLAGS="-j$(nproc)"

# ccache (compile cache)
CCACHE_ENABLED="yes"
CCACHE_DIR="/var/cache/ccache"
CCACHE_MAXSIZE="5G"

# Features
FEATURES="ccache parallel-make strip"

# Binary packages (not implemented yet, lol)
BINPKG_ENABLED="no"

# Host-provided packages
HOST_PROVIDED="gcc make glibc linux-headers"

# Stripping
STRIP_BINARIES="yes"
STRIP_LIBS="yes"
STRIP_STATIC="yes"

# Collision detection
COLLISION_DETECT="yes"
GHOST_FILE_CHECK="yes"
```

### Package Masking

Prevent installation of specific versions:

```bash
# /etc/astral/package.mask
broken-package
experimental-tool >= 3.0
old-library < 2.0
```

```bash
# Mask a package
astral --mask "firefox >= 120.0"

# Unmask
astral --unmask firefox
```

---

## Advanced Features

### Parallel Downloads

Downloads up to 4 sources concurrently (configurable):

```bash
# In make.conf
ASTRAL_MAX_PARALLEL=4
```

Saves time when packages have multiple source files.

### ccache Support

ccache caches compilation objects. Install once, compile twice (or more) at lightning speed.

```bash
# Install ccache
sudo astral -S dev-util/ccache

# Enable in make.conf
CCACHE_ENABLED="yes"

# Check stats
astral --ccache-stats

# Clear cache
astral --ccache-clear
```

**Warning**: ccache needs disk space. Set `CCACHE_MAXSIZE` appropriately.

### Build State Management

Resume interrupted builds:

```bash
# If build fails or is interrupted
sudo astral -Re package-name

# Astral resumes from last successful stage
```

Stages: `configure` → `build` → `package`

### Ghost File Detection

Detects files installed outside `$PKGDIR` (packaging bugs):

```bash
# Automatically checked during installation
# Shows warning if package installs directly to /usr
```

**What to do**: File a bug report. The package recipe is broken.

### Atomic Installation

Packages are installed atomically. Either everything succeeds, or nothing happens.

**Benefits**:
- No half-installed packages
- Safe interruption (Ctrl+C won't break your system)
- Rollback on failure

---

## Recipe Generator

### astral-recipegen

A tool to generate `.stars` recipes without manually typing boilerplate.

### Interactive Mode

```bash
astral-recipegen interactive v3
```

Prompts for:
- Package name
- Version
- Description
- Dependencies
- Build system

### Auto-Detection

```bash
astral-recipegen auto nano https://nano.org/dist/nano-8.2.tar.xz
```

Does the following:
1. Downloads source
2. Detects build system (autotools/cmake/meson/etc.)
3. Extracts version from filename
4. Generates checksum
5. Creates recipe

**Magic**: It actually works most of the time.

### Template Generation

```bash
astral-recipegen template cmake v3 -o mypackage.stars
astral-recipegen template python v2
```

Generates pre-filled templates for common build systems.

### Converting Directory Recipes

```bash
astral-recipegen dir-to-stars /usr/src/astral/recipes/app-editors/nano
```

Converts old directory-based recipes to `.stars` format.

### Migration

```bash
# Migrate v2 → v3
astral-recipegen migrate mypackage.stars v3

# Smart dependency splitting (auto-detects build vs runtime)
astral-recipegen migrate old-recipe.stars v3
```

### From PKGBUILD (Experimental)

```bash
astral-recipegen from-pkgbuild /path/to/PKGBUILD v3
```

Converts Arch Linux PKGBUILDs. Results may vary. Review manually.

---

## Troubleshooting

### Common Issues

#### "Another instance of astral is already running"

Someone (probably you) is already running astral.

**Fix**:
```bash
# Check if actually running
ps aux | grep astral

# If it's a stale lock
sudo rm -rf /var/lock/astral.lock.d
```

#### "Package version X.Y.Z is MASKED"

The package version is explicitly blocked.

**Fix**:
```bash
# Check why
cat /etc/astral/package.mask

# Unmask if you're brave
astral --unmask package-name
```

#### "CIRCULAR DEPENDENCY DETECTED"

Your dependency graph has a loop. Math says this is impossible, but here we are.

**Fix**: Fix the recipes. You can't install A if A depends on B and B depends on A. It's turtles all the way down.

#### "Checksum mismatch"

The downloaded file doesn't match the expected checksum.

**Causes**:
1. Source file changed (bad upstream)
2. Network corruption (bad luck)
3. MITM attack (bad day)

**Fix**:
```bash
# Re-download
rm /var/cache/astral/src/*

# If it persists, update checksum in recipe
sha256sum /var/cache/astral/src/package-1.2.3.tar.gz
```

#### "Failed to download source"

Network issues or dead link.

**Fix**:
1. Check internet connection (turn it off and on again)
2. Try again later
3. Update recipe with working mirror

#### Build fails with "command not found"

Missing build dependency.

**Fix**:
```bash
# Check what's missing
astral -D package-name

# Install missing dependencies
sudo astral -S missing-package
```

### Debugging

Enable verbose output:

```bash
sudo astral -v -S package-name
```

Check build logs:

```bash
# Build logs
ls /tmp/astral-build-*

# Sync logs
tail -f /var/log/astral_sync_*.log
```

---

## Contributing

### Writing Recipes

1. **Use v3 format** (it's the future, embrace it)
2. **Separate dependencies** (BDepends vs RDepends)
3. **Test your recipe** before submitting
4. **Use descriptive commit messages** ("fixed stuff" is not descriptive)

### Recipe Guidelines

- **Checksums are mandatory** (we're paranoid for a reason)
- **Use `$PKGDIR`** for installation (never install directly to `/`)
- **Strip binaries** unless there's a good reason
- **Clean up** (remove docs/examples if nobody reads them)

### Submitting to ASURA

ASURA is the community overlay. Submit your recipes there.

```bash
# Fork the repository
git clone https://codeberg.org/Izumi/ASURA

# Add your recipe
cd ASURA/recipes
mkdir -p category/package-name
cp your-recipe.stars category/package-name.stars

# Commit and push
git add .
git commit -m "Add package-name-1.2.3"
git push
```

### Contributing to Astral Core

1. Read the code (good luck)
2. Test your changes (seriously)
3. Submit a PR
4. Wait for the One Maniac™ to review (may take up to 3 business weekss)

**Coding style**: POSIX sh, no bashisms, keep it stupid simple.

---

## FAQ

### Why POSIX sh?

Because if `/bin/sh` isn't working, you have bigger problems than package management.

### Why not just use [insert package manager here]?

Because we're special snowflakes who compile from source.

### Does Astral support binary packages?

Technically yes (`BINPKG_ENABLED="no"` in the config), but actually no.

### Can I use Astral on [insert distro here]?

Probably. It's POSIX-compliant. Your mileage may vary.

### Why three recipe formats?

Legacy reasons. We couldn't break backwards compatibility without angering the *three* people using v1.

### Is Astral stable?

Define "stable". It won't delete your `/usr` anymore, so... yes?

### How do I pronounce "Astral"?

Like "astral projection", but for packages.

### What's the difference between AOHARU and ASURA?
- **AOHARU**: Official, manually reviewed, trusted
- **ASURA**: Community-contributed, use at your own risk

### Do I need to review recipes?  
For AOHARU: No, we review them. 
For ASURA: **YES, ALWAYS.** Never run untrusted code as the damn root.

### Who maintains this?

One Maniac. Just one. Send help (or coffee).

---

## Credits

- **Created by**: One Maniac™
- **Inspired by**: Gentoo Portage, Arch Pacman, KISS Linux, and pain
- **Special thanks**: Everyone who reported bugs instead of rage-quitting (if theres one)

---

## License

Just plain GPL-3.0

---

## Final Notes

> *"Astral: Because life's too short to not compile everything from source"*  
> — Nobody, ever

Astral is still evolving. Expect the code to be a spagetti, the philosophy to be based, and the implementation to be extremely transparent.

If you made it this far, congratulations! You're either very thorough or very bored (very me). Either way, happy compiling!

---

**Last updated**: 7 January 2026 (GMT+8) 
**Documentation version**: 3.0  
**Sanity level**: Questionable
