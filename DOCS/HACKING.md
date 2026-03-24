# Hacking Guide

This guide covers the development workflow for the Astral project.

## Prerequisites

- POSIX-compliant shell (/bin/sh)
- C++23 compiler (GCC 13+ or Clang 17+)
- Make
- git

## Building

### Shell Scripts

Shell scripts are executable as-is:
```sh
./astral --help
```

### C++ (astral-env)

```sh
cd astral-env
make -j$(nproc)
```

## Testing

Currently there are no automated tests. To manually test:

```sh
# Test installation
sudo ./astral-setup install

# Test package operations
sudo astral -S <package>
sudo astral -R <package>

# Test recipe generation
./astral-recipegen --help

# Test sync tool
./astral-sync --help
```

## Debugging

### Shell Scripts

- Add `set -x` to trace command execution
- Use `echo "DEBUG: variable=$variable"` for custom debug output
- Check exit codes with `echo "Exit code: $?"`

### C++ (astral-env)

- Build with debug symbols: Edit Makefile to add `-g` to CFLAGS
- Use `gdb` or `lldb` for debugging
- Check logs at `/var/log/astral-env-snapd.log`

## Code Organization

- Shell scripts in project root
- C++ code in `astral-env/`
- Documentation in `DOCS/`
- Man pages in `man/`

## Adding New Features

1. Read DOCS/CODING_STYLE.md
2. Follow the coding conventions
3. Test thoroughly
4. Submit PR
