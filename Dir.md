# Astral `.stars` Format Specification v2

## Overview

An Ancient format.

## Why Dir instead of `.stars`?

Ask the Maintainer™. Not us

---

## Directory Based:
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

## See Also

- Astral Package Manager Documentation
- .stars v2 & v1 specs
- `astral --help`
- Example recipes: `/usr/src/astral/recipes/`
