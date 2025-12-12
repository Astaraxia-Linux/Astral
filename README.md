# Astral

Astaraxia Package Manager, written entirely in POSIX shell, because writing it in C would make me lose 10 years of lifespan.

Astral is a **source-based** package manager designed for extremely small, hand-rolled Linux systems like Astaraxia (LFS, custom distros, experimental systems). The goal is a simple, transparent, hackable package manager with minimal assumptions.

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
* [FAQ](#faq)

## CHANGES (v5.1.3)

Added astral.conf in /etc/astral/astral.conf for make

---

## Features (Current State)

* Build from source using plain POSIX sh
* Staged installs using `$PKGDIR`
* Dependency listing via `depends` file
* Repo sync support
* Optional `sources` and `info` metadata
* Automatic build environment: `CFLAGS`, `MAKEFLAGS`, etc.
* Error-safe execution via `set -e`

### Not implemented yet (but planned)

* File ownership database
* Full conflict detection
* Safe uninstall of unused dependency files
* Proper upgrade file removal
* Signature checking
* Multiple repositories

---

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

```
libc
ncurses
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

## FAQ

* **Why not Rust?**
  Because Astral is supposed to boot on systems that don’t even have `bash` yet, let alone a 200-MB Rust toolchain.

* **Why POSIX sh?**
  Because if `/bin/sh` isn’t working, you have bigger problems than package management.

* **Why not Python?**
  Because Python isn’t installed in LFS unless *you* install it, and Astral must work before that.

* **Will Astral break your system?**
  Only if you intentionally ignore `$PKGDIR` rules or remove `/bin/sh`.

* **Is Astral fast?**
  Depends how fast you can type `make` and `curl`. Don’t expect Rust-level performance.

---

Astral is still evolving. Expect the code to be scuffed, the philo
