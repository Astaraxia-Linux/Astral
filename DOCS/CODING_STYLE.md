# Coding Style

This is a short document describing the preferred coding style. Coding style is personal, and I'll to not **force** my views on anybody. Please atleast consider the points made here.

---

## Formatting For Posix SH Scripts

The shell scripts (`astral`, `astral-recipegen`, `astral-setup`, `astral-sync`) follow POSIX sh conventions.

### Indentation

- Use 4 spaces for indentation.
- No tabs.

### Comments

- Use `#` for all comments.
- Comments should explain *why*, not *what* (the code should be self-explanatory).

```sh
# This is a comment
# Multi-word variables use underscores
some_variable="value"

# Functions use parentheses after name, no space before brace
function_name() {
    local arg="$1"
    echo "$arg"
}
```

### Variables

- Use lowercase with underscores: `variable_name="value"`
- Use `local` for function-local variables
- Quote variable expansions: `"$variable"` not `$variable`
- Use `${var}` for clarity when concatenating

```sh
# Use this:
local config_dir="/etc/astral"
if [ -f "$config_dir/conf" ]; then

# Instead of this:
local=config # don't use =
echo $var    # always quote
```

### Control Structures

```sh
# if/then/elif/else/fi
if [ "$condition" ]; then
    do_something
elif [ "$other" ]; then
    do_other
else
    do_default
fi

# while/do/done
while read -r line; do
    process "$line"
done < "$input_file"

# case/esac
case "$value" in
    foo)
        do_foo
        ;;
    bar)
        do_bar
        ;;
    *)
        do_default
        ;;
esac

# for/do/done
for item in list; do
    process "$item"
done
```

### Functions

- Define functions without `function` keyword
- Use parentheses after function name
- Put opening brace on same line as function name

```sh
# Use this:
my_function() {
    local arg1="$1"
    local arg2="${2:-default}"
}

# Instead of this:
my_function()
{
    ...
}
```

### Redirection

- No space after redirection operators:

```sh
# Use this:
echo "text" > file.txt
grep "pattern" < input.txt
command >> log.txt

# Instead of this:
echo "text" >  file.txt   # extra space
```

### Exit Codes

- Return 0 for success, non-zero for failure
- Use `set -e` to exit on error (in scripts)
- Use `set -u` to catch undefined variables

---

## Formatting For C++

The C++ code follows modern C++ practices with some project-specific conventions.

### Indentation

- Use 4 spaces for indentation.
- No tabs.
- Use single indentation (4 spaces) for continuation lines, including function parameters.

```cpp
// Good - single indentation for parameters
void some_function(
        int param_one,
        bool param_two) {
    // function body
}

// Good - single indentation for condition continuations
if (some_long_condition &&
    another_condition) {
    do_something();
}
```

### Comments

- Use `//` for all comments (single-line and multi-line).
- Use `/* */` only when necessary (e.g., commenting out code blocks).

```cpp
// This is a single-line comment

// This is a multi-line
// comment spread across
// multiple lines

/*
 * Block comment for
 * temporarily disabling code
 */
```

### Braces

- Use K&R style: opening brace on same line.
- Always use braces for control structures, even single-line bodies.

```cpp
// Good
if (condition) {
    do_something();
} else {
    do_other();
}

// Not this (no braces for single line):
if (condition)
    do_something();
```

### Naming Conventions

- **Classes**: PascalCase
  ```cpp
  class TempDir { };
  class TempFile { };
  class File { };
  ```

- **Functions**: snake_case
  ```cpp
  void read_file(const std::filesystem::path& path);
  std::string compute_hash(std::string_view name, std::string_view version);
  ```

- **Variables**: snake_case
  ```cpp
  std::string config_path;
  int max_jobs = 4;
  bool is_enabled = false;
  ```

- **Namespaces**: camelCase (lowercase)
  ```cpp
  namespace config { }
  namespace util { }
  namespace lock { }
  ```

- **Constants**: SCREAMING_SNAKE_CASE or snake_case depending on scope
  ```cpp
  constexpr int MAX_RETRIES = 3;
  const std::string default_config_path = "/etc/astral/config";
  ```

### File Organization

- Header files: `.hpp` extension
- Implementation files: `.cpp` extension
- One class per file (when practical)
- Include order:
  1. Corresponding header (if any)
  2. Standard library headers
  3. System headers
  4. Project headers

```cpp
#include "config/conf.hpp"    // Corresponding header
#include <iostream>            // Standard library
#include <string>              // Standard library
#include <unistd.h>            // System header
#include "util/file.hpp"      // Project header
```

### Modern C++ Features

The codebase uses modern C++ features:

- **std::string_view**: For string parameters that don't take ownership
  ```cpp
  void write_file(const std::filesystem::path& path, std::string_view content);
  ```

- **std::optional**: For values that may not be present
  ```cpp
  std::optional<std::string> find_config();
  ```

- - **std::unique_ptr**: For ownership. It has **zero runtime overhead** compared to a raw pointer and ensures RAII safety. Avoid `std::shared_ptr` unless actual shared ownership is required (due to atomic ref-count overhead).
  ```cpp
  std::vector<std::unique_ptr<SnapConfig>> load_snap_config();
  ```

- **std::filesystem**: For path operations
  ```cpp
  std::filesystem::path config_path = "/etc/astral";
  if (std::filesystem::exists(config_path)) { }
  ```

- **auto**: For type deduction when type is obvious
  ```cpp
  auto result = some_function();
  auto config = std::make_unique<Config>();
  ```

### Error Handling

The codebase uses exceptions for error handling:

- Use `throw std::runtime_error("message")` for fatal errors
- Wrap potentially throwing code in try/catch blocks
- Catch by `const std::exception&` for general error handling
- Use `catch (...)` sparingly for cleanup operations
- Prefer Value-Based Errors: Use `std::optional<T>` or `std::expected<T, E>` for logic errors in hot paths to avoid stack-unwinding overhead.
- Exceptions: Use `throw` only for truly exceptional/fatal failures (e.g., Out of Memory, missing core config).
- Mark `noexcept`: Aggressively mark functions as `noexcept` if they don't throw. This allows the compiler to skip generating exception-handling tables.


```cpp
try {
    auto content = util::read_file(path);
    // process content
} catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << "\n";
    return -1;
} catch (...) {
    // Catch-all for specific cleanup scenarios
    cleanup();
    throw;
}
```

### RAII

Use RAII for resource management:

```cpp
// Good - RAII wrapper
class TempDir {
    std::filesystem::path path_;
public:
    explicit TempDir(std::string_view prefix);
    ~TempDir() {
        if (!path_.empty()) {
            std::filesystem::remove_all(path_);
        }
    }
};

// Usage
void some_function() {
    TempDir tmp("/tmp/myapp");
    // tmp automatically cleaned up on scope exit
}
```

### noexcept

Mark move constructors and move assignment operators as `noexcept`:

```cpp
class TempDir {
public:
    TempDir(TempDir&& other) noexcept
        : path_(std::move(other.path_)),
          released_(other.released_) {
    }

    TempDir& operator=(TempDir&& other) noexcept {
        if (this != &other) {
            path_ = std::move(other.path_);
            released_ = other.released_;
        }
        return *this;
    }
};
```

### Pointers and References

- Use references when not null is guaranteed: `const std::string&`
- Use pointers when null is valid: `const char*`
- Prefer references over pointers when possible

```cpp
// Reference - caller must provide valid object
void process_config(const Config& config);

// Pointer - null is valid
const char* getenv_cached(const char* name);
```

### Return Values

- Use return values for simple results
- Use output parameters (references) for complex results
- Use `std::optional` when result may not exist
- Use exceptions for error conditions

```cpp
// Simple return
std::string get_name() const;

// Output parameter
void parse_config(const std::string& input, Config& output);

// Optional return
std::optional<Config> load_config(const std::filesystem::path& path);
```

### Zero-Overhead Constraints
- **No RTTI**: Do not use `dynamic_cast` or `typeid`.
- **No Hidden Copies**: 
  - Use `std::string_view` for read-only strings (extensively used).
  - Pass large objects by `const T&`.

## Summary
The key points are:

1. **4 spaces for indentation** for both shell and C++ (6 spaces NOT used)
2. **No tabs and No trailing whitespace**
3. Shell: # comments, local variables, and quoted expansions.
4. C++: `//` comments for everything.
5. C++ Naming: PascalCase classes, snake_case functions/variables, camelcase namespaces.
6. C++ RAII: Mandatory for all resource management (memory, fds, locks).
7. Zero Overhead: No RTTI.
8. Performance: Use `std::string_view` to avoid copies.
9. Error Handling: Exceptions are used extensively (throw/try/catch).
