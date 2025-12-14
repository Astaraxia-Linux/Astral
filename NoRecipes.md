# Why Astral Does Not Ship With All the Recipes

This document answers a very practical question:

**"Why doesn’t Astral just ship with recipes for everything already?"**

Short answer: I am one person, not a distribution foundation—time, trust, and reality are finite.

---

## Single‑Maintainer Reality

Astral and Astaraxia are maintained by one developer. That means:

* Every recipe is written by hand
* Every patch is reviewed by hand
* Every breakage is debugged by hand
* Every toolchain issue is diagnosed manually

There is no build farm. There is no corporate sponsor paying people to babysit edge cases.

If something breaks, it breaks on *my* machine first.

---

## Recipe Writing Is Not Trivial Busywork

A proper Astral recipe is not just:

* Download
* Configure
* Make
* Install

A *good* recipe requires:

* Understanding upstream build systems
* Knowing which files are safe to install
* Avoiding host contamination
* Handling cross-bootstrap edge cases
* Respecting `$buildtmp` and `$PKGDIR` strictly

Doing this correctly once is work.
Doing it for *hundreds* of packages is a second job.

---

## Astral Is Built for Early Systems, Not Comfort

Astral targets environments where:

* Documentation is missing
* Tooling is incomplete
* Failures are expensive
* Mistakes brick systems

In that context, **blindly mass-generating recipes is dangerous**.

Every recipe is executable code running as root.
Shipping low-quality or unreviewed recipes would be worse than shipping none.

---

## Quality Over Quantity (By Necessity, Not Ego)

Astral’s official repos prioritize:

* Correctness
* Auditability
* Minimal assumptions

This means:

* Fewer recipes
* Slower growth
* More manual work

That is not a design flex.
That is the cost of not lying to the system.

---

## Trust Does Not Scale Automatically

A package manager can scale faster than its trust model.

Astral deliberately avoids:

* Auto-generated recipes
* Mass imports from other distros
* Unchecked conversions

Because:

* Upstream build systems differ wildly
* File layouts are inconsistent
* Dependency semantics do not map cleanly

One bad recipe can silently corrupt a system.
That risk is not worth speed.

---

## This Is Why AOHARU and ASURA Exist

Astral separates concerns:

* **AOHARU**: official, reviewed, slow, boring, trusted
* **ASURA**: community, faster, messy, and *read the recipe*

Astral itself does not pretend all recipes are equal.
That separation is intentional.

---

## "But I Don’t Have Time Either"

Correct.

Which is why the *right* solution is not:

* Writing 500 recipes alone
* Making a ton of categories
* Pretending automation solves understanding

The correct direction is:

* Better scaffolding
* Better tooling
* Shared review
* Explicit trust boundaries

Not pretending recipe writing is free.

---

## Manual Patching Is Not a Hobby

Maintaining recipes is not just:

* Downloading tarballs
* Running `./configure && make`

It involves:

* Patching upstream build systems
* Dealing with non-deterministic configure scripts
* Fixing toolchain assumptions
* Chasing LFS-specific breakage
* Re-patching when upstream releases again

Doing this for *every* package is not a weekend project.
It is unpaid distro maintenance.

At some point, it stops being "fun" and becomes operational debt.

---

## Why Astral Prioritizes the Tool, Not the Catalog

Astral focuses on:

* Correctness of the build pipeline
* Transparency of behavior
* Safety during bootstrap
* Predictable results

Recipes are **policy**.
Astral is **mechanism**.

A solid mechanism allows:

* Small curated repos (AOHARU)
* Experimental community repos (ASURA)
* Personal overlays
* Hand-rolled local recipes

Trying to ship a massive official recipe set would:

* Slow development
* Increase maintenance burden
* Turn Astral into a full distro commitment

That is not the goal.

---

## Comparison to Large Distros

Portage, pacman, and apt work because they have:

* Dozens to thousands of contributors
* Automated testing infrastructure
* Release engineering teams

Astaraxia & Astral have:

* One maintainer
* Shell scripts

Expecting the same coverage is unrealistic.

---

## Community Is the Scaling Strategy

Astral is intentionally designed so that:

* Recipes are simple
* Patching is obvious
* Mistakes are visible

If users want more coverage:

* Contribute recipes
* Maintain overlays
* Share patches

Astral gives you the tools. It does not promise infinite free labor.

---

## The Honest Answer

Astral does not ship with all recipes because:

* Writing them correctly takes time
* Reviewing them takes more time
* Maintaining them never stops
* It is exhausting
* Time-consuming
* Sometimes frustrating

Astral chooses to be incomplete rather than dishonest.
Astral exists because it *needs* to exist. Not because maintaining a thousand packages is fun.

This is a system built for people who understand trade-offs.
If you want convenience, use a mainstream distro.
If you want control, Astral gives you that—and the responsibility that comes with it.

That is not laziness.
That is refusing to outsource responsibility to automation and hope.

That is the deal.

---

## If This Bothers You

That reaction is valid.

You can:

* Write recipes you care about
* Contribute them
* Maintain your own repo
* Accept trade-offs consciously

Astral will not optimize away reality for convenience.

Someone else can build that package manager.
Astral is not it.
