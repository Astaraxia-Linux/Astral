# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository. Only add
instructions to this file if you've seen an AI agent mess up that particular bit of logic in practice.

## Licensing and Legal Requirements

All contributions must comply with the licensing requirements:

- All code must be compatible with GPL-3.0-only
- Use appropriate SPDX license identifiers

## Key Documentation

Always consult these files as needed:

- `DOCS/ARCHITECTURE.md` — code organization and component relationships
- `DOCS/HACKING.md` — development workflow
- `DOCS/CODING_STYLE.md` — full style guide (must-read before writing code)
- `DOCS/CONTRIBUTING.md` — contribution guidelines and PR workflow

## Execution & Tooling Rules

- Never invent your own build commands or try to optimize the build process.
- Never use `head`, `tail`, or pipe (`|`) the output of build or test commands. Always let the full output display. This is critical for diagnosing build and test failures.
- Astral must be run as sudo/doas; ask the user to execute the command.
- Never use `grep -q` in pipelines; use `grep >/dev/null` instead (avoids `SIGPIPE`).
- **Comment Policy**: Keep comments minimal and precise. Only explain "why" for complex logic; do not describe "what" the code is doing if it is self-evident.
- **Shell Constraint**: All `.sh` or top-level scripts (astral, astral-sync, etc.) MUST be strictly **POSIX sh** compliant. Do not use Bash-isms or Zsh features.
- **C++ Constraint**: Use `std::string_view` for read-only string access. Do not use RTTI. Follow RAII strictly for resource management.

## Signed-off-by and Developer Certificate of Origin

AI agents MUST NOT add Signed-off-by tags. Only humans can legally certify the Developer Certificate of Origin (DCO). The human submitter is responsible for:

- Reviewing all AI-generated code
- Ensuring compliance with licensing requirements
- Adding their own Signed-off-by tag to certify the DCO
- Taking full responsibility for the contribution

## Attribution

When AI tools contribute to the development, proper attribution helps track the evolving role of AI in the development process. Contributions should include an Assisted-by tag in the following format:

`Assisted-by: AGENT_NAME:MODEL_VERSION [TOOL1] [TOOL2]`

Where:
- `AGENT_NAME` is the name of the AI tool or framework
- `MODEL_VERSION` is the specific model version used
- `[TOOL1] [TOOL2]` are optional specialized analysis tools used (e.g., coccinelle, sparse, smatch, clang-tidy)

Basic development tools (git, gcc, make, editors) should not be listed.
Example:

`Assisted-by: Claude:claude-4.6-opus coccinelle sparse`

## AI Agent Pre-Flight Checklist

BEFORE presenting code or commands to the user, verify compliance with these rules:

### 1. Legal & Attribution
- [ ] **No `Signed-off-by`**: I have NOT added a DCO tag (only the human user may do this).
- [ ] **Attribution Included**: My suggested commit message includes `Assisted-by: AGENT_NAME:MODEL_VERSION [TOOLS]`.
- [ ] **SPDX Header**: New files include `// SPDX-License-Identifier: GPL-3.0-only`.

### 2. Shell Scripting (POSIX)
- [ ] **No Bash-isms**: Checked for `[[ ]]`, `declare`, `array()`, or `function` keyword.
- [ ] **Quoting**: Every variable expansion is quoted (e.g., `"$var"`).
- [ ] **Safety Flags**: Ensured `set -e` and `set -u` are present.
- [ ] **Indentation**: Exactly 4 spaces, no tabs.

### 3. C++ (Zero-Overhead)
- [ ] **Brace Style**: Verified K&R (opening brace on the same line).
- [ ] **Indentation**: Exactly 4 spaces for all lines, including function parameters (no 6-space offsets).
- [ ] **No RTTI**: Verified no use of `dynamic_cast` or `typeid`.
- [ ] **Memory**: Verified `std::string_view` for read-only strings and `std::unique_ptr` for ownership.
- [ ] **Naming**: Classes are `PascalCase`, functions/variables are `snake_case`, namespaces are `camelcase`.

### 4. Execution & Testing
- [ ] **No Piped Output**: I am asking the user to run commands WITHOUT `| head`, `| tail`, or `grep -q`.
- [ ] **Sudo/Doas**: I have explicitly asked the user to use `sudo` for `astral` operations.
- [ ] **Manual Test Plan**: I have provided a specific command (e.g., `sudo ./astral -S <pkg>`) for the user to manually verify.

### 5. Communication
- [ ] **Comments**: Removed all "what" comments; only "why" remains for complex logic.
- [ ] **Review Cycle**: Reminded the user that PR reviews typically take **two weeks**.
