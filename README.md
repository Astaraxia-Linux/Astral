# Astral
Astaraxia Package Manager, made using shell scripts, because the dev is too dumb to make it in C or python

## Table of Contents
- [How to install](#how-to-install)
- [How to make the recipes](#how-to-make-the-recipes)

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
We will use ```app-test``` as an example

#### 1. version (Simple Metadata)
This file should contain just the version string.
```
1.0.0
```
#### 2. sources (Source Retrieval)
List the remote URLs for the source code archives.
```
https://example.com/downloads/app-test-1.0.0.tar.gz
```

#### 3. depends (Dependency Tracking)
List one required package name per line. This is used by astral --compile to check if dependencies are met, and by astral --RemoveDep to safely clean up.
```
lib-app-test
ncurses
```

### III. The Build Workflow (Scripts)
The build and package scripts are executed sequentially by astral. They are always run from the main temporary build directory ($buildtmp).

#### 1. build Script (Download, Extract, and Compile)
