# Astral

Astaraxia Package Manager, written entirely in POSIX shell, because writing it in C would make me lose 10 years of lifespan.

Astral is a **source-based** package manager designed for extremely small, hand-rolled Linux systems like [Astaraxia](https://github.com/Astaraxia-Linux/Astaraxia/) (LFS, custom distros, experimental systems). The goal is a simple, transparent, hackable package manager with minimal assumptions.

## Why Astral Exists (And Why It's Standalone)

Astral is intentionally designed to work **outside of Astaraxia**. This is not an accident.

### The reasoning

* **LFS-first reality**
  Astral is built to function *before* a full distro exists. When bootstrapping from LFS, you need a package manager **before** Python, Rust, systemd, or abstractions appear.

* **Policy vs mechanism separation**
  Astral provides *mechanism* (build, stage, install, register).
  Astaraxia provides *policy* (filesystem layout, defaults, rollback strategy, official repos).

* **Transparency over magic**
  Astral does not attempt to own your system. It executes shell scripts, stages files, and records metadata. Everything it does is visible and auditable.

* **Minimal assumptions**
  Astral assumes:

  * `/bin/sh`
  * basic coreutils
  * a working toolchain

  If those are missing, you do not need a package manager.
You need a rescue disk and life choices.

### What Astral is **not**

Astral is **not**:

* A universal replacement for pacman, emerge, or nix-env
* A dependency solver with global system awareness
* A safety net for arbitrary distributions

Using Astral outside Astaraxia is supported **only if you understand and accept the consequences**.

### Relationship to Astaraxia

> Astaraxia is Astral plus policy.

If Astral works well on its own, that is a feature — not scope creep.

---

## Supported Environments

Astral is known to work (or is expected to work) on:

* Linux From Scratch (LFS / BLFS)
* Minimal chroots
* Custom source-based systems
* Experimental or educational Linux environments

Astral is **not officially supported** on:

* Arch Linux (Does work)
* Gentoo (i dont want to brick gentoo for this)
* Debian / Ubuntu (tested every astral version on crositini)
* NixOS

It may work. It may also break things.

# Table Of Content

* [Installation](#installation)
* [CHANGES](#changes)
* [Versioning](#versioning)
* [Architecture Overview](#architecture-overview)
* [Recipe Format](#recipe-format)
* [Build Script Example](#build-script-example-build)
* [Package Script Example](#package-script-example-package)
* [Using Astral](#using-astral)
* [Behavior Notes (Important)](#behavior-notes-important)
* [Troubleshooting](#troubleshooting)
* [FAQ](#faq)

## Installation

### Manual Installation

Place the script into `/usr/bin/astral`:

```bash
curl -o /usr/bin/astral https://raw.githubusercontent.com/Astaraxia-Linux/Astral/main/astral
chmod +x /usr/bin/astral
```

Astral must be a single executable file.

---

## Changes (v2.0.1.0 Main)

### New in v2.0.1.0
- `.stars` Now supports 2 Version! yey?
- Fixed early host dependency check
---

### Implemented (v2.0.1.0)
*  File ownership database (`.files.index`)
*  Conflict detection before install
*  Safe uninstall (never removes shared directories)
*  Versioned dependencies
*  Security checks on build scripts
*  Atomic transactions
*  Dry-run mode
*  Instant lock detection with process info
*  Force install flag (`-f`)
*  Reverse-dependency tracking
*  Ccache Support
* Supports 2 recipes format, `Directory` based and `.stars` based

### Not implemented yet (but planned)
* Signature checking / GPG verification
* Multiple repository priorities
* Parallel builds
* Download resume for interrupted transfers
* Binary package caching (started, incomplete)
* Delta upgrades

## Versioning

Astral uses `0.MINOR.PATCH.HOTFIX` versioning:
- **0.x**: Pre-release (until stable 1.0.0)
- **MINOR**: Game-changing features (file ownership DB, atomic installs, etc.)
- **PATCH**: Improvements and additions
- **HOTFIX**: Bug fixes and quick patches

Example: `0.7.4.1`
- 0 = Pre-release
- 7 = 7th generation of features
- 4 = 4th patch release
- 1 = 1st hotfix

Once Astral reaches production stability, versioning will switch to SemVer.

## Architecture Overview

Astral's pipeline:

```
recipe → build stage ($buildtmp) → package stage ($PKGDIR) → root install → DB register
```

### Key Directories

```
/usr/src/astral/recipes/      # All recipes
/var/cache/astral/            # Cached source and binary data
/var/lib/astral/db/           # Installed package metadata
/etc/astral/                  # Astral configs
```

Current DB structure:

```
/var/lib/astral/db/<pkg>/
    version                   # Package version
    files                     # List of installed files
    depends                   # Runtime dependencies
/var/lib/astral/db/.files.index   # file → owner map (implemented)
```

---

## Recipe Format
### `.stars` Based

- [`.stars` Specification](https://github.com/Astaraxia-Linux/Astral/blob/V2.0.1.0-Main/.stars.md)

### Directory Based:
Each package lives in:

```
/usr/src/astral/recipes/<pkgname>/
```

A valid recipe **requires** at least:

```
version   # REQUIRED – version string
build     # REQUIRED – build script
```

Optional files:

```
package       # OPTIONAL – packaging script (recommended)
depends       # OPTIONAL – runtime dependencies
bdepends      # OPTIONAL – build-time dependencies
rdepends      # OPTIONAL – runtime-only dependencies
sources       # OPTIONAL – URLs for source tarballs
checksums     # OPTIONAL – SHA256 checksums for sources
info          # OPTIONAL – human-readable description
post_install  # OPTIONAL – post-installation script
post_remove   # OPTIONAL – post-removal script
conflicts     # OPTIONAL – conflicting packages
```

### File Rules (Strict)

```
version — must contain ONLY the version string
build   — MUST NOT write outside $buildtmp
package — MUST NOT write outside $PKGDIR
depends — plain list, no commas, supports version constraints
sources — URLs only
info    — free text
```

---

## Example Recipe Structure

```
example-app/
├── version
├── sources
├── checksums
├── depends
├── build
├── package
├── post_install
└── info
```

### Example: `version`

```
1.0.0
```

### Example: `sources`

```
https://example.com/example-app-1.0.0.tar.gz
```

### Example: `checksums`

```
a1b2c3d4e5f6... example-app-1.0.0.tar.gz
```

### Example: `depends`

**Old Format (Still Supported):**
```
libc
ncurses
```

**New Format (Versioned Dependencies):**
```
libc >= 2.38
gcc >= 12.0.0
python <= 3.11
zlib = 1.2.13
```

Supported operators: `>=`, `<=`, `>`, `<`, `=`

---

## Build Script Example (`build`)

```
#!/bin/sh
set -e

PKG_NAME="example-app"
PKG_VERSION=$(cat version)

# Sources are automatically downloaded and extracted (Only if you have `sources` file in repo)
# Can use Wget

cd "${PKG_NAME}-${PKG_VERSION}"

./configure --prefix=/usr --sysconfdir=/etc
make
```

---

## Package Script Example (`package`)

```
#!/bin/sh
set -e

PKG_NAME="example-app"
SOURCE_DIR="${PKG_NAME}-$(cat version)"

cd "$SOURCE_DIR"
echo "Installing to $PKGDIR"
make DESTDIR="$PKGDIR" install

# Clean up unwanted files
rm -rf "$PKGDIR/usr/share/doc/$PKG_NAME/examples" || true
```

---

## ccache Integration

Astral supports ccache for faster rebuilds of C/C++ packages.

### Installation

```bash
astral -S dev-util/ccache
```

### Configuration

Add to `/etc/astral/make.conf`:

```
CCACHE_ENABLED="yes"
CCACHE_DIR="/var/cache/ccache"
CCACHE_MAXSIZE="5G"
```

### Usage

Once enabled, ccache is automatically used for all package builds.

**Check ccache statistics:**
```
astral --ccache-stats
```

**Clear ccache:**
```
astral --ccache-clear
```

**Manual ccache commands:**
```
ccache -s          # Show stats
ccache -C          # Clear cache
ccache -z          # Zero stats
ccache -M 10G      # Set max size to 10GB
```

### Expected Speedup

- First build: No speedup (cache miss)
- Rebuild: 5-10x faster (cache hit)
- Partial rebuild: 2-5x faster (partial cache hit)

### Cache Location

- System: `/var/cache/ccache`
- User: `~/.ccache`

### Troubleshooting

**ccache not working:**
- Check: `which gcc` should show `/usr/lib/ccache/bin/gcc`
- Check: `ccache -s` should show statistics

**Cache too large:**
- Adjust: `CCACHE_MAXSIZE="10G"` in make.conf
- Or: `ccache -M 10G`

**Poor hit rate:**
- Check: `ccache -s` for cache statistics
- Ensure CFLAGS are consistent across builds

---

## Using Astral

### Basic Operations

**Install from AOHARU (Official Repo):**
```
astral -S category/example-app
```

**Install from ASURA (Community Repo):**
```
astral -Sa category/example-app
```

**Compile from Local Recipe:**
```
astral -C category/example-app
```

**Remove Package (Keep Dependencies):**
```
astral -R example-app
```

**Remove Package + Orphaned Dependencies:**
```
astral -r example-app
```

**Remove All Orphaned Packages:**
```
astral --autoremove
```

### Query Operations

**Search for Packages:**
```
astral -s keyword
```

**Show Package Info:**
```
astral -I example-app
```

**Show Dependency Tree:**
```
astral -D example-app
```

**Check System Dependencies:**
```
astral -Dc
```

**Preview Install (Dry Run):**
```
astral -p example-app
```

**Show Why Package is Installed:**
```
astral -w example-app
```

**List Explicitly Installed Packages:**
```
astral -W
```

**List All Installed Packages:**
```
astral -ll
```

### System Operations

**Update Repository Index:**
```
astral -u              # Update AOHARU
astral -u asura        # Update ASURA
```

**Upgrade All Packages:**
```
astral -UA
```

**Clean Uninstalled Recipe Cache:**
```
astral -Cc
```

**Rebuild File Index:**
```
astral -RI
```

### Advanced Options

**Dry-Run Mode (Preview Only):**
```
astral -n -S package
```

**Force Override Conflicts:**
```
astral -f -S package
```

**Custom Install Root:**
```
astral --dir /mnt/sysroot -S package
```

---

## Behavior Notes (Important)

### Upgrades

Current behavior:

* Installs new version over the old one
* Atomically replaces files to prevent partial upgrades
* Conflict detection ensures file ownership tracking

### Dependencies

* `depends` is respected during build and runtime
* Versioned dependencies are checked before installation
* `bdepends` are build-time only, `rdepends` are runtime-only
* Host-provided dependencies (system libraries) are automatically detected

### Safety Guarantees

* All scripts run under `set -e`
* Package scripts cannot write to `/` directly
* Only final install phase touches the root filesystem
* All build work is isolated in `$buildtmp`
* Transactional installs prevent partial package states
* Security checks block malicious patterns in build scripts

---

## Troubleshooting

### Common Issues

**"PKGDIR: parameter not set"**
- Your `build` or `package` script is using `$PKGDIR` before it's set
- Solution: Only use `$PKGDIR` in the `package()` function

**"Circular dependency detected"**
- Package A depends on B, B depends on A
- Solution: Review your `depends` files, break the cycle

**"File conflict detected"**
- Another package owns this file
- Solution: Use `-f` to force override (dangerous!) or review the conflict

**"Another instance of astral is already running"**
- Another Astral instance is running (shows PID and process name)
- Solution: The error message shows which process is holding the lock
- If it's a stale lock from a crashed process, Astral will auto-remove it
- Manual removal (if needed): `rm -rf /var/lock/astral.lock.d`

**"File index missing"**
- First-time install or corrupted index
- Solution: `astral -RI` to rebuild index

**"Checksum mismatch"**
- Downloaded source doesn't match expected checksum
- Solution: Check if source was modified upstream, update `checksums` file if legitimate

**"Version mismatch" for dependencies**
- Installed dependency doesn't meet version requirement
- Solution: Upgrade the dependency first: `astral -S dependency-name`

### Performance Issues

**Slow conflict detection**
- File index might be missing
- Solution: `astral -RI`

**Slow builds**
- Check `MAKEFLAGS` in `/etc/astral/make.conf`
- Enable ccache: `CCACHE_ENABLED="yes"`

### Getting Help

```
1. Check logs: `/var/log/astral/`
2. Run with dry-run: `astral -n -S package`
3. Inspect recipe: `astral -Ins package`
4. File an issue: https://github.com/Astaraxia-Linux/Astral/issues
```

---

## FAQ

**Why not Rust?**  
Because Astral is supposed to boot on systems that don't even have `bash` yet, let alone a 200-MB Rust toolchain.

**Why POSIX sh?**  
Because if `/bin/sh` isn't working, you have bigger problems than package management.

**Why not Python?**  
Because Python isn't installed in LFS unless *you* install it, and Astral must work before that.

**Why not C?**  
Because C buys performance Astral does not need, while adding complexity Astral explicitly avoids. A C implementation would require careful memory management, a build system, and platform-specific assumptions. Astral's goal is transparency and hackability during early bootstrap, not raw speed.

**Why not Go?**  
Because Go requires a full toolchain and runtime that does not exist during LFS bootstrap. Astral is designed to work *before* higher-level languages are available. Go is suitable for optional post-bootstrap tooling, but not for Astral's core.

**Will Astral break your system?**  
Only if you intentionally ignore `$PKGDIR` rules, run untrusted recipes, or `rm -R glibc`.

**Is Astral fast?**  
Depends how fast you can type `make` and `curl`. It's POSIX shell - don't expect Rust-level performance.

**Can I use Astral on Arch/Gentoo/Debian?**  
Technically yes, but **don't**. Astral is designed for minimal systems where you control everything. On established distros, use the native package manager.

**What's the difference between AOHARU and ASURA?**
- **AOHARU**: Official, manually reviewed, trusted
- **ASURA**: Community-contributed, use at your own risk

**Do I need to review recipes?**  
For AOHARU: No, we review them. For ASURA: **YES, ALWAYS.** Never run untrusted code as root.

**Can Astral coexist with other package managers?**  
Not recommended. File conflicts will occur. Choose one package manager per system.

**Where's the binary package support?**  
Experimental/incomplete. Source-first design means binaries are an optimization, not core.

**Why "Astral"?**  
Because the original dev wanted something that sounded cool and had no taken GitHub repos. Also it fits the space/star theme of Astaraxia.

**How does Astral handle virtual packages?**  
Astral supports virtual packages through `/etc/astral/virtuals/`. A virtual like "compiler" can be satisfied by gcc, clang, or tcc. If any provider is installed or host-provided, the virtual is satisfied.

**What about host-provided dependencies?**  
Astral automatically detects system libraries via `ldconfig`, `pkg-config`, and binaries in `$PATH`. Mark additional host dependencies in `/etc/astral/make.conf` with `HOST_PROVIDED="gcc make libc"`.

**Can I mask packages?**  
Yes! Use `astral --mask package >= 2.0` to prevent installation of specific versions. Manage masks in `/etc/astral/package.mask`.

---

Astral is still evolving. Expect the code to be scuffed, the philosophy to be based, and the implementation to be extremely transparent.
