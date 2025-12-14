# Astral

Astaraxia Package Manager, written entirely in POSIX shell, because writing it in C would make me lose 10 years of lifespan.

Astral is a **source-based** package manager designed for extremely small, hand-rolled Linux systems like [Astaraxia](https://github.com/Astaraxia-Linux/Astaraxia/) (LFS, custom distros, experimental systems). The goal is a simple, transparent, hackable package manager with minimal assumptions.

## Why Astral Exists (And Why It’s Standalone)

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

  If those are missing, your system has larger problems.

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

* [CHANGES](#changes)
* [Features](#features-current-state)
* [Architecture Overview](#architecture-overview)
* [Installation](#installation)
* [Recipe Format](#recipe-format)
* [Build Script Example](#build-script-example-build)
* [Package Script Example](#package-script-example-package)
* [Using Astral](#using-astral)
* [Behavior Notes (Important)](#behavior-notes-important)
* [TODO](#todo)
* [Troubleshooting](#troubleshooting)
* [FAQ](#faq)

## CHANGES (v0.7.2.7)

### New in v0.7.2.7
- **Transactional installs**: Packages now install atomically to staging, preventing partial installs
- **File ownership database**: Fast O(1) file conflict detection via `.files.index`
- **Security hardening**: Malicious script detection (blocks `rm -rf /`, fork bombs, disk destruction)
- **Versioned dependencies**: Support for `pkg >= 1.2.3` syntax in depends files
- **Dry-run mode** (`-n`): Preview changes without modifying system
- **Per-command force** (`-f`): Override conflicts on a per-command basis
- **Circular dependency detection**: Prevents infinite loops in dependency chains
- **Safe directory handling**: No longer auto-deletes shared directories during removal

### Breaking Changes
- `depends` file now supports version constraints: `package >= version`
- Old format (`package` only) still works for backward compatibility
- dry-run            Dry-run mode: show what would happen without doing it.

---

Many planned features are now done!

### ✅ Implemented (v0.7.1.1)
* ✅ File ownership database (`.files.index`)
* ✅ Conflict detection before install
* ✅ Safe uninstall (never removes shared directories)
* ✅ Versioned dependencies
* ✅ Security checks on build scripts
* ✅ Atomic transactions
* ✅ Dry-run mode

### 🚧 Not implemented yet (but planned)
* Signature checking / GPG verification
* Multiple repository priorities
* Parallel builds
* Download resume for interrupted transfers
* Binary package caching (started, incomplete)
* Delta upgrades

## Architecture Overview

Astral’s pipeline:

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

Planned DB structure:

```
/var/lib/astral/db/<pkg>/
    version
    files
/var/lib/astral/db/index      # file → owner map (future)
```

---

## Installation

### Manual Installation

Place the script into `/usr/bin/astral`:

```
curl -o /usr/bin/astral https://raw.githubusercontent.com/Astaraxia-Linux/Astral/main/astral
chmod +x /usr/bin/astral
```

Astral must be a single executable file.

---

## Recipe Format

Each package lives in:

```
/usr/src/astral/recipes/<pkgname>/
```

A valid recipe **requires** at least:

```
version   # REQUIRED – version string
build     # REQUIRED – build script
package   # REQUIRED – packaging script
```

Optional files:

```
depends   # OPTIONAL – one package per line
sources   # OPTIONAL – URLs for source tarballs
info      # OPTIONAL – human-readable description
```

### File Rules (Strict)

```
version — must contain ONLY the version string
build   — MUST NOT write outside $buildtmp
package — MUST NOT write outside $PKGDIR
depends — plain list, no commas
sources — URLs only
info    — free text
```

---

## Example Recipe Structure

```
example-app/
├── version
├── sources
├── depends
├── build
├── package
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

### Example: `depends`
### Old Version (Still eh idk Supported i guess?)

```
libc
ncurses
```
### New Version
```
libc >= 2.38
gcc >= 12.0.0
python <= 3.11
zlib = 1.2.13
```


---

## Build Script Example (`build`)

```
#!/bin/sh
set -e

PKG_NAME="example-app"
PKG_VERSION=$(cat version)

wget -q "$(cat sources)" -O "${PKG_NAME}-${PKG_VERSION}.tar.gz"
tar xf "${PKG_NAME}-${PKG_VERSION}.tar.gz"
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

rm -rf "$PKGDIR/usr/share/doc/$PKG_NAME/examples" || true
```

---

## Using Astral

Compile from recipes:

```
astral --Compile category/example-app
```

Remove (Leaves Depends):

```
astral --Remove example-app
```

RemoveDeps:

```
astral --RemoveDep example-app
```

Sync repos (FROM [AOHARU](https://github.com/Izumi-Sonoka/AOHARU/tree/main)):

```
astral --Sync category/example-app
```

---

## Behavior Notes (Important)

### Upgrades

Current behavior:

* Installs new version over the old one
* Does **not** remove old files yet
* No conflict resolution yet

### Dependencies

* `depends` is respected during build
* Removal of dependency packages is not fully safe until file ownership DB is implemented

### Safety Guarantees

* All scripts run under `set -e`
* Package scripts cannot write to `/` directly
* Only final install phase touches the root filesystem
* All build work is isolated in `$buildtmp`

---

## TODO

* Repo update detection
* Force install flag (`-f`)
* Proper uninstall with reverse-dependency tracking
* File ownership DB
* Conflict detection
* ~~- Rewrite in Rust for “speed”~~ (never happening)

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

**"Lock file exists"**
- Another Astral instance is running
- Solution: Wait, or remove stale lock: `rm -rf /var/lock/astral.lock.d`

**"File index missing"**
- First-time install or corrupted index
- Solution: `astral -RI` to rebuild index

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

---

Astral is still evolving. Expect the code to be scuffed, the philosophy to be based, and the implementation to be extremely transparent.
