# astral-recipegen Documentation

> *"Because manually writing boilerplate is for people with time to spare"*

Version: 2.0.0  
Last Updated: January 2026  
For: Astral Package Manager

---

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Commands](#commands)
5. [Recipe Formats](#recipe-formats)
6. [Advanced Usage](#advanced-usage)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

### What is astral-recipegen?

`astral-recipegen` is a recipe generator tool for Astral package manager. It automates the tedious process of creating `.stars` recipe files by:

- **Auto-detecting** build systems
- **Generating** checksums automatically
- **Converting** between recipe formats (v1, v2, v3)
- **Migrating** directory-based recipes to `.stars`
- **Supporting** Git repositories

Think of it as a recipe wizard. Except instead of making cookies, it makes package recipes. And instead of delicious treats, you get... more software to compile.

### Why Use It?

- **Save time**: No more copy-pasting boilerplate
- **Reduce errors**: Auto-generated checksums and dependencies
- **Stay consistent**: Templates ensure proper format
- **Easy migration**: Convert old recipes to new formats
- **Git support**: Generate recipes directly from repositories

---

## Installation

### Prerequisites

```bash
# Required
sh (POSIX-compliant shell)
curl (for downloading sources)
sha256sum (for checksums)

# Optional but recommended
git (for Git repository support)
```

### Install

```bash
# Download
curl -O https://raw.githubusercontent.com/Astaraxia-Linux/Astral/main/astral-recipegen

# Make executable
chmod +x astral-recipegen

# Install system-wide
sudo mv astral-recipegen /usr/bin/

# Test
astral-recipegen --version
```

---

## Quick Start

### Generate a Recipe in 30 Seconds

```bash
# Interactive mode (easiest)
astral-recipegen interactive v3

# Follow the prompts:
# - Package name: nano
# - Category: app-editors
# - Version: 8.2
# - Description: Text editor
# - Build system: autotools
# - Dependencies: ncurses
```

**Output**: `nano.stars` ready to use!

### Auto-Detect from URL

```bash
astral-recipegen auto nano https://nano.org/dist/nano-8.2.tar.xz
```

This will:
1. Download the source
2. Detect it uses autotools
3. Extract version (8.2)
4. Generate SHA256 checksum
5. Create a working recipe

**Magic!** ✨

---

## Commands

### `interactive [version]`

Interactive wizard for creating recipes.

```bash
# Generate v3 recipe (recommended)
astral-recipegen interactive v3

# Generate v2 recipe
astral-recipegen interactive v2

# Generate v1 recipe (legacy)
astral-recipegen interactive v1
```

**When to use**: You're creating a recipe from scratch and want to be guided through the process.

---

### `auto <name> <url> [version]`

Auto-detect build system and generate recipe from source URL.

```bash
# Auto-detect everything
astral-recipegen auto nano https://nano.org/dist/nano-8.2.tar.xz

# Specify output format
astral-recipegen auto vim https://github.com/vim/vim/archive/v9.0.tar.gz v3

# Custom output location
astral-recipegen auto gcc https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz -o gcc.stars
```

**Detects**:
- Autotools (configure, configure.ac)
- CMake (CMakeLists.txt)
- Meson (meson.build)
- Python (setup.py, pyproject.toml)
- Plain Makefile

**When to use**: You have a source tarball and want a recipe generated automatically.

---

### `git <name> <url> [branch] [version]`

Generate recipe from Git repository.

```bash
# Clone and generate
astral-recipegen git neovim https://github.com/neovim/neovim.git

# Specify branch
astral-recipegen git dwm https://git.suckless.org/dwm stable

# Specify format
astral-recipegen git myproject https://github.com/user/repo main v3
```

**Detects Build Systems**:
- Autotools
- CMake
- Meson
- Python (setup.py, pyproject.toml)
- **Cargo** (Rust)
- **Go** (go.mod)
- **NPM** (package.json)
- Plain Makefile

**Git Source Format**:
```
git+https://github.com/user/repo.git#branch=main
git+https://github.com/user/repo.git#commit=abc123
```

**When to use**: Package is actively developed on Git and you want the latest code.

---

### `template <type> [version]`

Generate empty template for specific build system.

```bash
# CMake template (v3 format)
astral-recipegen template cmake v3 -o mypackage.stars

# Autotools template (v2 format)
astral-recipegen template autotools v2

# Python template
astral-recipegen template python v3
```

**Available Types**:
- `autotools` - GNU Autotools
- `cmake` - CMake
- `meson` - Meson
- `python` - Python packages
- `make` - Plain Makefile

**When to use**: You want to manually fill in details but need the structure.

---

### `dir-to-stars <directory> [version]`

Convert directory-based recipe to `.stars` file.

```bash
# Convert to v3 format
astral-recipegen dir-to-stars /usr/src/astral/recipes/app-editors/nano

# Convert to v2 format
astral-recipegen dir-to-stars /usr/src/astral/recipes/sys-libs/glibc v2

# Custom output
astral-recipegen dir-to-stars /path/to/recipe -o output.stars
```

**Reads**:
- `version` file
- `depends`, `bdepends`, `rdepends` files
- `build`, `package` scripts
- `sources`, `checksums` files
- `info` file

**When to use**: Migrating old directory recipes to modern `.stars` format.

---

### `convert <recipe> <version>`

Convert recipe between formats.

```bash
# Convert v2 to v3
astral-recipegen convert mypackage.stars v3

# Convert v1 to v2
astral-recipegen convert old-recipe.stars v2

# Convert directory to v3
astral-recipegen convert /path/to/recipe-dir v3
```

**Smart Features**:
- Auto-splits dependencies (build vs runtime)
- Preserves all metadata
- Keeps scripts intact
- Updates syntax

**When to use**: Updating existing recipes to newer formats.

---

### `migrate <recipe>`

Migrate recipe to latest version (v3).

```bash
# Migrate to v3 (default)
astral-recipegen migrate mypackage.stars

# Same as convert but always targets v3
astral-recipegen migrate old-recipe.stars
```

**When to use**: Quick upgrade to the latest format.

---

### `from-pkgbuild <file> [version]`

Convert Arch Linux PKGBUILD to `.stars` (experimental).

```bash
# Convert to v3
astral-recipegen from-pkgbuild /path/to/PKGBUILD v3

# Convert to v2
astral-recipegen from-pkgbuild PKGBUILD v2
```

**Extracts**:
- `pkgname`, `pkgver`, `pkgdesc`
- `depends`, `makedepends`
- `source`, `sha256sums`

**Note**: Build/package functions are **not** converted automatically. You'll need to review and adapt them manually.

**When to use**: Porting Arch packages to Astral (proceed with caution).

---

## Recipe Formats

### v1 - Legacy Format

```bash
VERSION="1.0.0"
DESCRIPTION="Package description"

@DEPENDS
gcc
make

@BUILD
./configure
make

@PACKAGE
make DESTDIR="$PKGDIR" install
```

**Status**: Deprecated but still supported.

---

### v2 - Current Format

```bash
$PKG.Metadata: {
    VERSION = "1.0.0"
    DESCRIPTION = "Package description"
    CATEGORY = "app-misc"
};

$PKG.Depend {
    $PKG.Depend.Depends {
        gcc
        make
    };
};

$PKG.Build {
    ./configure --prefix=/usr
    make -j$(nproc)
};

$PKG.Package {
    make DESTDIR="$PKGDIR" install
};
```

**Status**: Current standard.

---

### v3 - Modern Format (Recommended)

```bash
$PKG.Version = "3"

$PKG.Metadata: {
    Version = "1.0.0"
    Description = "Package description"
    Category = "app-misc"
};

$PKG.Depend.BDepends: {
    gcc
    make
};

$PKG.Depend.RDepends: {
    ncurses
    readline
};

$PKG.Sources: {
    urls = "https://example.com/source.tar.gz"
};

$PKG.Checksums: {
    sha256:abc123... source.tar.gz
};

$PKG.Build: {
    ./configure --prefix=/usr
    make -j$(nproc)
};

$PKG.Package: {
    make DESTDIR="$PKGDIR" install
};
```

**Key Feature**: Separated build-time and runtime dependencies!

**Status**: Future-proof, recommended for all new recipes.

---

## Advanced Usage

### Smart Dependency Detection

When migrating to v3, `astral-recipegen` attempts to intelligently split dependencies:

**Build Tools** (→ BDepends):
- gcc, g++, clang
- make, cmake, meson, ninja
- autoconf, automake, libtool
- pkg-config, bison, flex

**Everything Else** (→ RDepends):
- Libraries (ncurses, readline, openssl)
- Runtime utilities
- Interpreters (python, perl)

```bash
# Auto-split dependencies
astral-recipegen migrate old-recipe.stars v3
```

---

### Custom Output Locations

```bash
# Specify output file
astral-recipegen auto nano https://... -o ~/recipes/nano.stars

# Specify recipe directory
astral-recipegen -d /custom/recipes interactive v3
```

---

### Format Selection

```bash
# Default format (v3)
astral-recipegen interactive

# Force v2
astral-recipegen -f v2 interactive

# Per-command format
astral-recipegen template cmake v2
```

---

### Batch Conversion

```bash
# Convert all recipes in directory
for recipe in /usr/src/astral/recipes/*/*.stars; do
    astral-recipegen migrate "$recipe"
done

# Convert directory recipes
for dir in /usr/src/astral/recipes/*/*/; do
    astral-recipegen dir-to-stars "$dir"
done
```

---

## Examples

### Example 1: Create Recipe from Scratch

```bash
$ astral-recipegen interactive v3

Package name: htop
Category (e.g., app-editors, sys-apps): sys-process
Version: 3.3.0
Description: Interactive process viewer
Homepage: https://htop.dev
Source URL: https://github.com/htop-dev/htop/archive/3.3.0.tar.gz
Build system (autotools/cmake/meson/make): autotools
Build dependencies (space-separated): gcc make autoconf automake
Runtime dependencies (space-separated): ncurses
Optional dependencies (space-separated): 

✓ Recipe generated: /usr/src/astral/recipes/sys-process/htop.stars
```

---

### Example 2: Auto-Generate from URL

```bash
$ astral-recipegen auto nano https://nano.org/dist/nano-8.2.tar.xz

Downloading source: nano-8.2.tar.xz
Extracting archive...
✓ Detected: GNU Autotools
  Detected version: 8.2
  Checksum: fb53c30b58a81fe0b3b4e64aedb9a53311ddda301ec9c1c2b42d659e50f5e13a

Category (default: app-misc): app-editors
Description: GNU nano text editor
Homepage URL: https://nano-editor.org

✓ Recipe generated: /usr/src/astral/recipes/app-editors/nano.stars
```

---

### Example 3: Git Repository

```bash
$ astral-recipegen git neovim https://github.com/neovim/neovim.git

Cloning repository...
✓ Cloned successfully
  Detected version: v0.10.0
  ✓ CMake

Category (default: app-misc): app-editors
Description: Vim-fork focused on extensibility
Homepage URL (default: https://github.com/neovim/neovim.git): https://neovim.io

Build dependencies (press Enter for auto): 
Runtime dependencies: 

✓ Git recipe generated: /usr/src/astral/recipes/app-editors/neovim.stars

Note: Git sources are cloned during build.
```

---

### Example 4: Convert Directory Recipe

```bash
$ astral-recipegen dir-to-stars /usr/src/astral/recipes/sys-libs/glibc v3

Converting Directory Recipe to .stars

  Source:  /usr/src/astral/recipes/sys-libs/glibc
  Package: glibc
  Format:  v3

✓ Converted to v3: /usr/src/astral/recipes/sys-libs/glibc.stars
```

---

### Example 5: Migrate All Recipes

```bash
# Create backup first
cp -r /usr/src/astral/recipes /usr/src/astral/recipes.backup

# Migrate all v2 recipes to v3
find /usr/src/astral/recipes -name "*.stars" | while read recipe; do
    echo "Migrating: $recipe"
    astral-recipegen migrate "$recipe" v3
done
```

---

## Troubleshooting

### "git is not installed"

Git support requires `git` to be installed.

**Fix**:
```bash
sudo astral -S dev-vcs/git
# or
sudo apt install git  # on Debian/Ubuntu
```

---

### "Failed to download source"

Network issues or invalid URL.

**Fix**:
1. Check internet connection
2. Verify URL is correct
3. Try alternative mirror

---

### "Could not detect build system"

Source doesn't have recognizable build files.

**Fix**:
```bash
# Use template and fill manually
astral-recipegen template make v3 -o mypackage.stars

# Or use interactive mode
astral-recipegen interactive v3
```

---

### "Unknown archive format"

Unsupported archive type.

**Supported**:
- `.tar.gz`, `.tgz`
- `.tar.bz2`, `.tbz`
- `.tar.xz`, `.txz`
- `.zip`

**Fix**: Extract manually and use `dir-to-stars` if you have a recipe directory.

---

### Output File Already Exists

**Fix**:
```bash
# Force overwrite with -o
astral-recipegen auto pkg https://... -o existing.stars

# Or rename output
astral-recipegen auto pkg https://... -o pkg-new.stars
```

---

## Command Reference

### Global Options

```
-o, --output <file>      Output file
-d, --dir <dir>          Recipe directory (default: /usr/src/astral/recipes)
-f, --format <v1|v2|v3>  Output format version (default: v3)
-v, --version            Show version
-h, --help               Show help
```

### Commands Summary

| Command | Purpose | Usage |
|---------|---------|-------|
| `interactive` | Guided recipe creation | `interactive [v1\|v2\|v3]` |
| `auto` | Auto-detect from URL | `auto <name> <url> [version]` |
| `git` | Generate from Git repo | `git <name> <url> [branch] [version]` |
| `template` | Generate template | `template <type> [version]` |
| `dir-to-stars` | Convert directory recipe | `dir-to-stars <dir> [version]` |
| `convert` | Convert between formats | `convert <recipe> <version>` |
| `migrate` | Migrate to latest (v3) | `migrate <recipe>` |
| `from-pkgbuild` | Convert PKGBUILD | `from-pkgbuild <file> [version]` |

---

## Best Practices

1. **Always use v3 format** for new recipes
2. **Test generated recipes** before committing
3. **Review auto-detected dependencies** (might miss some)
4. **Add descriptions** that are actually helpful
5. **Use Git recipes** for development packages
6. **Backup before batch migration** (seriously)

---

## Contributing

Found a bug? Have a feature request?

- **Repository**: https://github.com/Astaraxia-Linux/Astral
- **Issues**: Submit a bug report
- **Pull Requests**: Contributions welcome!

---

## FAQ

### Can I use this without Astral?

Technically yes, but why would you? The generated `.stars` files are specifically for Astral.

### Does it support [insert build system here]?

Check the auto-detection list. If not, use `template make` and adapt manually.

### Can it convert my Gentoo ebuilds?

No, but you can try `from-pkgbuild` as a starting point and adapt from there. Good luck.

### Why three formats?

Legacy reasons. We couldn't break backwards compatibility. v3 is the future, use that.

### Is the dependency detection perfect?

No. It's smart, but not psychic. Always review the generated dependencies.

---

## See Also

- [Astral Documentation](README.md)
- [.stars Format Specification](STARS_FORMAT.md)
- [Contributing Guide](CONTRIBUTING.md)

---

**Last updated**: January 2026  
**Version**: 2.0.0  
**Maintained by**: One Maniac

> *"Generating recipes so you don't have to"*  
> — astral-recipegen, probably
