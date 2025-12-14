# Astral FAQ – Language Choices

This document exists solely to answer the recurring question:
**"Why is Astral written in POSIX sh and not [insert favorite language]?"**

Short answer: because Astral is designed for reality, not hype.

---

## Why POSIX sh?

Because Astral must work **before** the system is comfortable.

At Astral time, you may not have:

* Python
* Go
* Rust
* systemd
* a package manager
* patience

But you *will* have:

* `/bin/sh`
* basic coreutils
* a compiler toolchain (hopefully)

If `/bin/sh` is broken, you do not need a package manager.
You need a rescue disk and life choices.

POSIX sh gives Astral:

* zero bootstrapping cost
* maximum portability
* total transparency

Every action Astral performs is readable, auditable, and debuggable with `set -x` and `echo`.

---

## Why not C?

Because C buys performance Astral does not need, while charging interest in complexity.

A C rewrite would require:

* a build system
* compiler flags
* platform assumptions
* memory safety audits
* debugging tools that don’t exist during early bootstrap

Astral is I/O-bound, not CPU-bound.
The slow part is `make`, not the shell glue around it.

Writing Astral in C would:

* make it harder to hack
* make it harder to audit
* make it harder to bootstrap

Also, segfaulting your package manager while building `glibc` is a character-building experience.
Not a good one.

---

## Why not Go?

Because Go assumes a world Astral explicitly does not live in.

Go requires:

* a full Go toolchain
* a runtime
* a working libc
* significant disk space

Astral is meant to exist **before** all of that.

If your system is advanced enough to have Go comfortably installed,
Astral has already done its job.

Go is fine for:

* post-bootstrap tooling
* helpers
* optional userland utilities

Go is not fine for:

* the *first* package manager on a dead-simple system

Also, shipping a static Go binary just to untar tarballs and run shell scripts is… ambitious.

---

## Why not Rust?

Because Astral is supposed to build systems that *eventually* install Rust.
Not require Rust to exist first.

Also:

* Rust toolchains are huge
* compile times are long
* bootstrap complexity is real

Astral values:

* boring reliability
* minimal assumptions
* zero magic

Rust is great.
Astral just isn’t the place for it.

---

## The actual philosophy

Astral is intentionally:

* boring
* obvious
* blunt

It is not trying to be clever.
It is trying to be **unavoidable**.

If Astral breaks, you can read it.
If Astral misbehaves, you can trace it.
If Astral does something stupid, you can fix it at 3AM without recompiling half your system.

That is the point.

---

If someone still insists Astral should be rewritten in another language:

* they are free to do so
* Astral will still exist
* both can be wrong in different ways

Entropy wins eventually anyway.
