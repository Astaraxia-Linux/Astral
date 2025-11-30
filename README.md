# Astral
Astaraxia Package Manager, made using shell scripts, because the dev is too dumb to make it in C or python

## Table of Contents
- [Testing phase](#testing-phase)
- [How to install](#how-to-install)
- [How to make the recipes](#how-to-make-the-recipes)

## TESTING PHASE
### Compiling - 2/3
1. Compiling wihout depend... - CHECK
2. Compiling with depend... - CHECK
3. Compiling with 2 or more apps using the same depend... - X
### Binary - 0/3
1. Installing wihout depend... - X
2. Installing with depend... - X
3. Installing with 2 or more apps using the same depend... - X

## HOW TO INSTALL
### From a Terminal
Copy Everyting in [Astral](https://github.com/Astaraxia-Linux/Astral/blob/main/astral) and then paste it on to your terminal.
### Manually
Copy Everyting in [Astral](https://github.com/Astaraxia-Linux/Astral/blob/main/astral) and remove from the line of the codes
```
tee /usr/bin/astral > /dev/null <<'SH'
chmod +x /usr/bin/astral
```

and place it on /usr/bin

## HOW TO MAKE THE RECIPES

### I. Recipe Directory Structure
Every recipe requires at least three files and is housed in its own directory:
```
/usr/src/astral/recipes/pkgname/
├── version        # The version number of the software (e.g., 7.1.0)
├── build          # Shell script for downloading and building the source (required)
├── package        # Shell script for installing files into $PKGDIR (required)
└── depends        # List of other Astaraxia packages required (optional, but recommended)
└── sources        # List of URLs for source files (required if compiling)
```

### II. The Core Recipe File
We will use ```example-app``` as an example

#### 1. version (Simple Metadata)
This file should contain just the version string.
```
1.0.0
```
#### 2. sources (Source Retrieval)
List the remote URLs for the source code archives.
```
https://example.com/downloads/example-app-1.0.0.tar.gz
```

#### 3. depends (Dependency Tracking)
List one required package name per line. This is used by astral --compile to check if dependencies are met, and by astral --RemoveDep to safely clean up.
```
libc
ncurses
```

### III. The Build Workflow (Scripts)
The build and package scripts are executed sequentially by astral. They are always run from the main temporary build directory ($buildtmp).

#### 1. build Script (Download, Extract, and Compile): /usr/src/astral/recipes/example-app/build
```
#!/bin/sh
set -e # Exit immediately if any command fails

PKG_NAME="example-app"
PKG_VERSION=$(cat version) # Read version from file

# 1. Download and Check Integrity (manual for now, but crucial!)
echo "Downloading $PKG_NAME $PKG_VERSION..."
# Use URL from the 'sources' file
wget -q "$(cat sources)" -O "${PKG_NAME}-${PKG_VERSION}.tar.gz"

# 2. Extract and move into the source directory
tar xf "${PKG_NAME}-${PKG_VERSION}.tar.gz"
cd "${PKG_NAME}-${PKG_VERSION}" # Move into the extracted source folder

# 3. Configure (for standard source packages)
./configure --prefix=/usr --sysconfdir=/etc

# 4. Compile
make

# Leave the shell in the source directory for the package script!
```

#### 2. package Script (Install into $PKGDIR): /usr/src/astral/recipes/example-app/package
This script's primary job is to move all built files into the safe staging area, $PKGDIR. It must NEVER write outside of $PKGDIR. If it does open an issue on this repo
- Key Concept: The $PKGDIR variable is injected by astral and points to the safe, isolated install location. All files destined for /usr must go to $PKGDIR/usr, etc.
```
#!/bin/sh
set -e

PKG_NAME="example-app"
SOURCE_DIR="${PKG_NAME}-$(cat version)"

# --- Installation Step 1: Standard Make Install ---
# Use the DESTDIR variable, which points to the safe package directory.
# This assumes the 'make' process finished successfully in the build script.
# We must first change into the source directory if the build script did not persist.
cd "$SOURCE_DIR"

echo "Installing files to safe stage: $PKGDIR"
make DESTDIR="$PKGDIR" install

# --- Installation Step 2: Custom Files (e.g., Neofetch files) ---
# For packages without make install (like Neofetch), you must manually copy files.
# Example: If you needed to copy a custom license file:
# mkdir -p "$PKGDIR/usr/share/doc/$PKG_NAME"
# cp LICENSE "$PKGDIR/usr/share/doc/$PKG_NAME/"

# 3. Final cleanup (optional)
# Remove documentation or examples we don't need in the final system
rm -rf "$PKGDIR/usr/share/doc/$PKG_NAME/examples" || true
```

#### IV. Summary of Key Variables
| Variable | Source | Purpose |
| :------- | :----: | ------: |
|$PKGDIR|Injected by ```astral```|CRITICAL! The temporary, isolated staging directory. All files must be installed here. ($PKGDIR/usr/, $PKGDIR/etc/, etc.)|
|version|File content|Provides the version string used to name binaries and source archives.|
|$buildtmp|Internal to astral|The main temporary location where all source archives and extracted folders reside.|

Once these files are created and placed in the recipe directory, you can compile the package using:
```
astral --compile example-app
```
