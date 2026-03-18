# Architecture

This document describes the high-level architecture of Astaraxia's software.

## Overview

Astral is a minimal POSIX package manager for Astaraxia.

## Components

### Core Scripts

- `astral` - Main package manager
- `astral-recipegen` - Recipe generator
- `astral-setup` - Installation script
- `astral-sync` - Repository sync tool

### Directory Structure

```
/home/sonoka/Astral
├── astral              # Main package manager (POSIX shell)
├── astral-recipegen    # Recipe generator (POSIX shell)
├── astral-setup        # Installation script (POSIX shell)
├── astral-sync         # Repository sync (POSIX shell)
├── completions/        # Shell completions
├── DOCS/               # Documentation
└── man/                # Man pages
```

## Data Flow

```
User Command
     |
     v
astral (main script)
     |
     +---> astral-recipegen (generate recipes)
     |
     +---> astral-sync (sync repository)
     |
     +---> astral-env (C++ environment manager)
               |
               +---> config/ (configuration)
               +---> lock/ (lockfile handling)
               +---> repo/ (package repository)
               +---> store/ (package store)
               +---> snap/ (snapshots)
               +---> system/ (system integration)
```

## Key Design Decisions

1. **POSIX Compliance**: All shell scripts use POSIX sh for portability across different Unix-like systems.

2. **Source-Based**: Astral builds packages from source, allowing custom optimizations and flexibility.

3. **Recipe Formats**: Supports multiple formats (dir, v1, v2, v3) for backward compatibility.

4. **RAII in C++**: Resource management uses RAII patterns for automatic cleanup.

5. **Exception Handling**: C++ code uses exceptions extensively for error handling.

6. **No RTTI**: Runtime Type Information is avoided for performance.

7. **std::string_view**: Used extensively to avoid unnecessary string copies.
