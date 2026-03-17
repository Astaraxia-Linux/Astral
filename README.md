# Astral Package Manager Documentation

> *"Because compiling from source should be less painful than a root canal"*

Version: 5.3.1.6 Main  
Last Updated: 17 March 2026 (GMT+8)  
Maintained by: One Maniac (yes, just one)

*Made in Malaysia, btw*

---

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Basic Usage](#basic-usage)
4. [Recipe Formats](#recipe-formats)
5. [Package Management](#package-management)
6. [Dependency System](#dependency-system)
7. [Service Management](#service-management)
8. [Configuration](#configuration)
9. [Advanced Features](#advanced-features)
10. [Security Features](#security-features)
11. [Transactions & Rollback](#transactions--rollback)
12. [Recipe Generator](#recipe-generator)
13. [Repository Sync Tool](#repository-sync-tool)
14. [Troubleshooting](#troubleshooting)
15. [Contributing](#contributing)
16. [FAQ](#faq)

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
- **Parallel builds and removals**: Because waiting is for the weak
- **Atomic transactions with rollback**: Because mistakes happen
- **Built-in service management**: init-system-agnostic, works everywhere
- **Security features**: GPG signing, certificate pinning, FIM, audit trails
- **Recipe generator**: Auto-generate recipes from URLs or convert from other formats
- **Repository sync tool**: Index generation, checksum verification, GPG signing

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

### Steps.

For a proper installation with all components and man pages, use the setup script:

```bash
# Self-explainatory
git clone https://github.com/Astaraxia-Linux/Astaraxia/Astral
cd Astral
chmod +x ./astral-setup

# Full installation (all tools + man pages)
sudo ./astral-setup install

# Install to /usr/local instead of /usr
sudo ./astral-setup install --local

# Initialize after installation
sudo ./astral-setup init

# Install shell completions
sudo ./astral-setup completions
```

### Man Pages

Astral includes comprehensive man pages for all commands:

```bash
# Read the main Astral man page
man astral

# Read the recipe generator documentation
man astral-recipegen

# Read the sync tool documentation
man astral-sync

# Configuration file format
man astral-stars    # section 5
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

# Install multiple packages in parallel
sudo astral --parallel-build pkg1 pkg2 pkg3

# Resume an interrupted build
sudo astral -Re package-name
```

### Removing Packages

```bash
# Remove a single package
sudo astral -R package-name

# Remove multiple packages in parallel
sudo astral -R pkg1 pkg2 pkg3

# Remove package + orphaned dependencies
sudo astral -r package-name

# Remove multiple packages + their orphaned deps in parallel
sudo astral -r pkg1 pkg2 pkg3

# Remove all orphans (spring cleaning!)
sudo astral --autoremove

# Explicit parallel remove commands
sudo astral --parallel-remove pkg1 pkg2 pkg3
sudo astral --parallel-removedep pkg1 pkg2 pkg3
```

### Searching & Information

```bash
# Search for packages
astral -s nano

# Show package info
astral -I bash

# Show package info as JSON
astral -I bash --json

# Show dependency tree
astral -D gcc

# Check for broken dependencies
astral -Dc

# Why is this installed?
astral -w readline

# Preview what would be installed (no changes)
astral --preview package-name

# Show USE flags
astral --use
astral --use package-name

# Count packages
astral --count          # all
astral --count aoharu
astral --count installed

# List installed packages
astral -ll
astral -ll --json

# List world set (explicitly installed)
astral -W

# Show build environment
astral --show-env
```

### System Maintenance

```bash
# Update repository indexes
sudo astral -u
sudo astral -u aoharu    # specific repo

# Upgrade all packages (grab some coffee)
sudo astral --Upgrade-All

# Clean cache (uninstalled recipes)
sudo astral -Cc

# Rebuild file ownership index
sudo astral -RI

# Generate dependency graph (.dot format)
astral --graph-deps package-name

# Validate a recipe file
astral --validate /path/to/recipe.stars

# Verify installed package file integrity
astral --verify-integrity package-name

# Verify package builds reproducibly
astral --verify-reproducible package-name

# Clean temporary build directories
sudo astral --cleanup-temp

# Check for Astral updates
astral --check-version

# Update Astral itself
sudo astral -U
sudo astral -U dev    # specific branch

# Show current configuration
astral --config
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

The recommended format. Finally separates build-time and runtime dependencies.

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

$PKG.PostInstall: {
    # Optional: runs after installation
};

$PKG.PostRemove: {
    # Optional: runs after removal
};
```

**Use when**: You want a clean system without build tools polluting your runtime.

**Key differences**:
- `BDepends`: Build-time only (removed after build)
- `RDepends`: Runtime dependencies (kept forever)
- `Optional`: Nice-to-have features (user choice)
- `PostInstall` / `PostRemove`: Hooks that run after install/removal

---

## Package Management

### The World Set

The "world set" is your list of explicitly installed packages. Think of it as your package wishlist, except you already got everything.

```bash
# List world set
astral -W

# World set management
astral --world-add package-name
astral --world-remove package-name
astral --world-show
astral --world-sets          # show available sets (@system, @world)
astral --world-depclean      # world-aware dependency cleaning
astral --calc-system         # calculate @system set
```

**Important**: Orphaned packages (not in world, not depended on) can be removed with `--autoremove`.

### Package Holds

Prevent specific packages from being upgraded:

```bash
# Hold a package at its current version
astral --hold package-name

# Release the hold
astral --unhold package-name

# See what's held
astral --list-held
```

### Package Masking

Block specific package versions:

```bash
# Mask a version range
astral --mask "firefox >= 120.0"

# Unmask
astral --unmask firefox

# /etc/astral/package.mask (manual editing)
broken-package
experimental-tool >= 3.0
old-library < 2.0
```

### Dependency Resolution

Astral uses recursive dependency resolution. It's like a family tree, but with software.

```bash
# Preview what will be installed (no changes made)
astral --preview bash

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
# Test if a package is provided by the host
astral --host-check gcc

# Show all detected host dependencies
astral --host-deps
```

### Virtual Packages

Virtual packages allow alternatives:

```bash
# /etc/astral/virtuals/compiler
gcc
clang
tcc
```

If you request `virtual/compiler`, Astral checks if *any* provider is installed.

```bash
# List all virtual package providers
astral --list-virtuals
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

### Circular Dependencies

Astral detects circular dependencies and will yell at you:

```
ERROR: [pkg-a] CIRCULAR DEPENDENCY DETECTED! Chain: pkg-a -> pkg-b -> pkg-a
```

**Solution**: Fix your damn dependencies. Or cry. Both work.

---

## Service Management

Astral has built-in service management that auto-detects your init system. No need to remember which tool your distro uses.

```bash
# Start / stop / restart a service
sudo astral start sshd
sudo astral stop sshd
sudo astral restart sshd

# Enable / disable at boot
sudo astral enable sshd
sudo astral disable sshd

# Check service status
astral status sshd
```

Supported init systems, detected automatically:
- **systemd** - uses `systemctl`
- **OpenRC** - uses `rc-service` / `rc-update`
- **runit** - uses `sv` / symlinks in `/var/service`
- **s6** - uses `s6-rc` / `s6-rc-bundle-update`
- **SysVinit** - uses `service` / `update-rc.d` / `chkconfig`

Astral tells you which init system it detected when you run a service command. If it gets it wrong, file a bug.

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

# Host-provided packages (won't try to install these)
HOST_PROVIDED="gcc make glibc linux-headers"

# Stripping
STRIP_BINARIES="yes"
STRIP_LIBS="yes"
STRIP_STATIC="yes"

# Parallel downloads
ASTRAL_MAX_PARALLEL=4

# Collision detection
COLLISION_DETECT="yes"
GHOST_FILE_CHECK="yes"
```

### astral.stars

Global Astral configuration lives at `/etc/astral/astral.stars`:

```bash
# Create default config
sudo astral --astral-stars-create

# Edit and hot-reload
sudo astral --astral-stars-edit /etc/astral/astral.stars
```

---

## Advanced Features

### Parallel Builds and Removals

Build or remove multiple packages concurrently:

```bash
# Install multiple packages in parallel (respects dependency order)
sudo astral --parallel-build pkg1 pkg2 pkg3

# Remove multiple packages in parallel
sudo astral --parallel-remove pkg1 pkg2 pkg3
sudo astral --parallel-removedep pkg1 pkg2 pkg3

# -R and -r also dispatch to parallel automatically when given multiple packages
sudo astral -R pkg1 pkg2 pkg3
sudo astral -r pkg1 pkg2 pkg3
```

Uses `$(nproc)` jobs by default.

### Parallel Downloads

Downloads up to 4 sources concurrently (configurable):

```bash
# In make.conf
ASTRAL_MAX_PARALLEL=4
```

### ccache Support

ccache caches compilation objects. Install once, compile twice at lightning speed.

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
sudo astral -Re package-name
```

Stages: `configure` → `build` → `package`. Resumes from the last successful stage.

### Sandbox Isolation

Packages build in an isolated sandbox. Astral picks the best available method:

1. **Bubblewrap** (most secure, preferred)
2. **Chroot** (requires root)
3. **Fakechroot** (userspace isolation, no root needed)
4. **Fakeroot** (minimal, better than nothing)

```bash
# Test sandbox isolation on your system
sudo astral --sandbox-test
```

Safety features can be toggled:

```bash
# Show status of all safety features
astral --safety-status

# Enable/disable specific features (script-check, collision, etc.)
sudo astral --on script-check
sudo astral --off collision
```

### Ghost File Detection

Detects files installed outside `$PKGDIR` (packaging bugs). Automatically checked during installation - shows a warning if a package recipe tries to install directly to `/usr`.

**What to do**: File a bug. The recipe is broken.

### Atomic Installation

Packages are installed atomically. Either everything succeeds, or nothing happens.

**Benefits**:
- No half-installed packages
- Safe interruption (Ctrl+C won't wreck your system)
- Automatic rollback on failure

### JSON Output

Several commands support `--json` for scripting:

```bash
astral -s package-name --json
astral -I package-name --json
astral -ll --json
```

### Chroot

```bash
# Chroot into a directory (e.g. a new Astaraxia install)
sudo astral --chroot /mnt/astaraxia
```

---

## Security Features

### GPG Signing

```bash
# Import a repository GPG key
sudo astral --import-key https://example.com/repo.asc

# Verify a file's GPG signature
astral --verify-sig /path/to/file.tar.gz

# Generate a new GPG signing key
sudo astral --gpg-gen-key "My Signing Key"

# List managed keys
astral --gpg-list-keys

# Set trust level (unknown|never|marginal|full|ultimate)
sudo astral --gpg-set-trust <key-id> full

# Generate a revocation certificate
astral --gpg-revoke <key-id>

# Rotate signing key
sudo astral --gpg-rotate <old-key-id> <new-key-id>

# Build Web of Trust graph
astral --gpg-wot
```

### Certificate Pinning

Pin HTTPS certificates for extra paranoia:

```bash
# Pin a host's certificate
sudo astral --pin-cert example.com
sudo astral --pin-cert example.com:443

# Verify a pinned certificate hasn't changed
astral --verify-cert example.com
```

### File Integrity Monitoring (FIM)

Track file hashes and detect unauthorized changes:

```bash
# Record a file's current hash
sudo astral --fim-record /etc/passwd

# Check if a file has changed since recording
astral --fim-check /etc/passwd

# Scan all tracked files at once
astral --fim-scan
```

### Audit Trail

Recipe audit log for accountability:

```bash
# Query the audit log
astral --audit-query

# Verify a recipe's audit trail
astral --audit-verify package-name
```

### Lock System

```bash
# Show current lock status (who's holding it, for how long)
astral --lock-info

# Test the lock system
astral --lock-test
```

---

## Transactions & Rollback

Every install/remove operation is a transaction. Nothing is permanent until it commits.

```bash
# List transactions
astral --transactions          # all
astral --transactions active
astral --transactions committed

# Roll back a specific transaction by ID
sudo astral --rollback <transaction-id>

# Recover from incomplete/interrupted transactions
sudo astral --recover
```

**How it works**: Before any operation, Astral snapshots the DB and all affected paths. If something goes wrong (power cut, Ctrl+C, build failure), `--recover` finds incomplete transactions and rolls them back automatically.

**Note**: This is Astral's package-level transaction system, separate from `astral-env`'s system-level rollback.

---

## Recipe Generator

### astral-recipegen

Generates `.stars` recipes so you don't have to type boilerplate.

### Interactive Mode

```bash
astral-recipegen interactive v3
```

Prompts for package name, version, description, dependencies, and build system.

### Auto-Detection

```bash
astral-recipegen auto nano https://nano-editor.org/dist/v8/nano-8.2.tar.xz
```

Does the following automatically:
1. Downloads source
2. Detects build system (autotools/cmake/meson/python/make)
3. Extracts version from filename
4. Generates checksum
5. Creates v3 recipe

**Magic**: It actually works most of the time.

### Template Generation

```bash
astral-recipegen template cmake v3 -o mypackage.stars
astral-recipegen template python v2
astral-recipegen template autotools v3
astral-recipegen template meson v3
astral-recipegen template make v3
```

### Converting Directory Recipes

```bash
astral-recipegen dir-to-stars /usr/src/astral/recipes/app-editors/nano
```

### Migration

```bash
# Migrate v1/v2 → v3
astral-recipegen migrate mypackage.stars v3

# Convert between any versions
astral-recipegen convert mypackage.stars v2
```

### From PKGBUILD (Experimental)

```bash
astral-recipegen from-pkgbuild /path/to/PKGBUILD v3
```

Converts Arch Linux PKGBUILDs. Results may vary. Always review manually.

### Git Support

```bash
astral-recipegen git
```

---

## Repository Sync Tool

### astral-sync

The repository sync tool generates package indexes, verifies checksums, and can sign/push to GitHub. Essential for maintaining AOHARU or ASURA repositories.

### Index Generation

```bash
# Generate index from recipes
astral-sync generate

# Full sync with GPG signing
astral-sync sync --key A1B2C3D4

# Show index status
astral-sync status

# List packages in category
astral-sync list app-editors

# Show changes since last index
astral-sync diff
```

### Checksum Management

```bash
# Verify source checksums (skips already-verified)
astral-sync checksum

# Auto-fix wrong checksums
astral-sync checksum --fix

# Add checksums to recipes with empty/TODO blocks
astral-sync empty-checksums

# Reset checksum verification state
astral-sync checksum-reset
```

### Recipe Migration

```bash
# Migrate flat recipe tree to sharded layout
astral-sync migrate

# Auto-organize recipes into category/shard/pkg/ structure
astral-sync migrate-organize
```

### Environment Variables

```bash
RECIPES_DIR    # Recipes directory (default: ./recipes)
OUTPUT_DIR     # Output directory for index (default: .)
GPG_KEY        # GPG key ID for signing
AUTO_PUSH=1    # Auto-push after generate
FIX_CHECKSUMS=1  # Auto-fix wrong checksums
DRY_RUN=1      # Dry run mode
```

**Use when**: You're maintaining a repository and need to generate the package index, verify checksums, or push updates to GitHub.

## Troubleshooting

### "Another instance of astral is already running" / Stale Lock

```bash
# Check if actually running
ps aux | grep astral

# Show lock info
astral --lock-info

# Remove stale lock manually (only if astral is definitely not running)
sudo rm -rf /var/lock/astral.lock.d
```

### "Package version X.Y.Z is MASKED"

```bash
# Check why
cat /etc/astral/package.mask

# Unmask if you're brave
astral --unmask package-name
```

### "CIRCULAR DEPENDENCY DETECTED"

Fix the recipes. You can't install A if A depends on B and B depends on A. It's turtles all the way down.

### "Checksum mismatch"

**Causes**: Source file changed upstream, network corruption, or a very bad day (MITM).

```bash
# Re-download
rm /var/cache/astral/src/*

# Update checksum in recipe if source changed upstream
sha256sum /var/cache/astral/src/package-1.2.3.tar.gz
```

### "Failed to download source"

1. Check your internet connection (turn it off and on again)
2. Try again later
3. Update the recipe with a working mirror

### Build fails with "command not found"

Missing build dependency.

```bash
astral -D package-name        # check dependency tree
sudo astral -S missing-dep    # install what's missing
```

### Interrupted build / half-installed package

```bash
# Resume from last successful stage
sudo astral -Re package-name

# Or recover all incomplete transactions
sudo astral --recover
```

### Service command fails / wrong init system detected

```bash
# Check what Astral thinks your init system is
astral status any-service-name
# Output includes "Using init system: <name>"
```

If it's wrong, file a bug with your `/proc/1/comm` output.

### Debugging

```bash
# Verbose output
sudo astral -v -S package-name

# Check build logs
ls /tmp/astral-build-*

# Check sync logs
tail -f /var/log/astral_sync_*.log

# Run test suite
sudo astral --test all
sudo astral --test quick
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
- **PostInstall/PostRemove hooks** for anything that needs to happen after the files land

### Submitting to ASURA

ASURA is the community overlay.

```bash
# Fork the repository
git clone https://codeberg.org/Izumi/ASURA

# Add your recipe
cd ASURA/recipes
cp your-recipe.stars category/package-name.stars

# Commit and push
git add .
git commit -m "Add package-name-1.2.3"
git push
```

### Contributing to Astral Core

1. Read the code (good luck - it's 10k lines of sh)
2. Test your changes (seriously)
3. No bashisms - POSIX sh only
4. Submit a PR
5. Wait for the One Maniac™ to review (may take up to 3 business weeks)

---

## FAQ

### Why POSIX sh?

Because if `/bin/sh` isn't working, you have bigger problems than package management.

### Why not just use [insert package manager here]?

Because we're special snowflakes who compile from source.

### Does Astral support binary packages?

Technically yes (`BINPKG_ENABLED="no"` in the config), but actually no. Not yet.

### Can I use Astral on [insert distro here]?

Probably. It's POSIX-compliant. Your mileage may vary.

### Why four recipe formats?

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
For ASURA: **YES, ALWAYS.** Never run untrusted code as root.

### What's astral-env?

It's the declarative system configuration layer that sits on top of Astral. It lets you describe your entire system - packages, services, dotfiles, snapshots - in a `.stars` file and apply it all at once. [Read the astral-env docs](https://github.com/Astaraxia-Linux/Astral-env).

### Who maintains this?

One Maniac. Just one. Send help (or coffee).

---

## Credits

- **Created by**: One Maniac™
- **Inspired by**: Gentoo Portage, Arch Pacman, KISS Linux, and pain
- **Special thanks**: Everyone who reported bugs instead of rage-quitting (both of you)

---

## License

Just plain GPL-3.0

---

## Final Notes

> *"Astral: Because life's too short to not compile everything from source"*  
> - Nobody, ever

Astral is still evolving. The code is still spaghetti. The philosophy is still based. The implementation is extremely transparent (you can read all 10,000+ lines of it).

If you made it this far, congratulations. You're either very thorough, very bored, or writing documentation for a One Maniac™ project at 2am. Either way, happy compiling.

---

**Last updated**: 17 March 2026 (GMT+8)  
**Documentation version**: 5.1  
**Sanity level**: Questionable, as always