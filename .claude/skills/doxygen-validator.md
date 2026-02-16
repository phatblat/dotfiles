# Doxygen Validator

Validate Doxygen documentation comments in source code for correctness, completeness, and link generation.

## Capability

This skill validates Doxygen documentation comments in C++, C, Java, Python, and other supported languages. It checks tag usage, cross-references, formatting, content quality, and organization, returning structured reports with issues and suggestions.

## Supported Operations

### Validation Checks
- **link-generation** - Verify cross-references and links
- **tag-usage** - Check proper Doxygen tag usage
- **formatting** - Validate comment style and structure
- **content-quality** - Check for typos, clarity, accuracy
- **organization** - Review grouping and documentation structure
- **all** - Complete validation (default)

## Usage Protocol

Agents invoke this skill by specifying validation parameters:

```json
{
  "action": "doxygen",
  "command": "validate",
  "args": {
    "path": "src/",
    "checks": "all",
    "language": "cpp",
    "configFile": "Doxyfile"
  }
}
```

### Parameters

- **action** (required): Always `"doxygen"`
- **command** (required): Validation command (always "validate")
- **args** (required): Command-specific arguments (see below)
- **workdir** (optional): Working directory for command execution
- **timeout** (optional): Timeout in seconds (default: 300s)

### Validate Args
```json
{
  "path": "src/api.h",
  "checks": "all",
  "language": "cpp",
  "configFile": "Doxyfile",
  "strictMode": false
}
```

## Output Format

Returns structured JSON validation report:

```json
{
  "validationReport": {
    "timestamp": "2025-12-14T18:00:00Z",
    "action": "doxygen",
    "command": "validate",
    "path": "src/api.h",
    "exitCode": 0,
    "duration": "2.3s",
    "status": "success",
    "coverage": {
      "totalItems": 45,
      "documentedItems": 38,
      "percentage": 84.4
    },
    "issues": [
      {
        "file": "src/api.h",
        "line": 123,
        "severity": "error",
        "category": "link-generation",
        "message": "Invalid cross-reference: @ref MyClass should be @ref MyNamespace::MyClass",
        "suggestion": "Add namespace qualification for proper link generation"
      },
      {
        "file": "src/api.h",
        "line": 156,
        "severity": "warning",
        "category": "tag-usage",
        "message": "Missing @return tag for non-void function",
        "suggestion": "Add @return description explaining return value semantics"
      },
      {
        "file": "src/api.h",
        "line": 189,
        "severity": "suggestion",
        "category": "organization",
        "message": "Consider using @defgroup for related functions",
        "suggestion": "Group authentication functions with @defgroup auth and @ingroup tags"
      }
    ],
    "summary": {
      "errors": 3,
      "warnings": 12,
      "suggestions": 8,
      "criticalIssues": 1
    },
    "missingDocumentation": [
      {
        "file": "src/api.h",
        "line": 234,
        "item": "void processRequest(Request* req)",
        "type": "function"
      },
      {
        "file": "src/api.h",
        "line": 267,
        "item": "class InternalHelper",
        "type": "class"
      }
    ]
  }
}
```

### Issue Severities

- **error**: Breaks documentation generation or creates invalid links
- **warning**: Missing required documentation elements
- **suggestion**: Style improvements and best practices

### Check Categories

- **link-generation**: Cross-references, @ref, @see, \link commands
- **tag-usage**: @param, @return, @throws, @brief, @details tags
- **formatting**: Comment style, indentation, code blocks
- **content-quality**: Typos, clarity, accuracy, examples
- **organization**: @defgroup, @ingroup, @page, @file, @namespace

## Common Doxygen Operations

### Validate Single File
```json
{
  "action": "doxygen",
  "command": "validate",
  "args": {
    "path": "include/mylib.h",
    "checks": "all",
    "language": "cpp"
  }
}
```

### Check Only Link Generation
```json
{
  "action": "doxygen",
  "command": "validate",
  "args": {
    "path": "src/",
    "checks": "link-generation",
    "language": "cpp"
  }
}
```

### Validate with Custom Doxyfile
```json
{
  "action": "doxygen",
  "command": "validate",
  "args": {
    "path": "src/",
    "checks": "all",
    "configFile": "docs/Doxyfile",
    "strictMode": true
  }
}
```

### Find Missing Documentation
```json
{
  "action": "doxygen",
  "command": "validate",
  "args": {
    "path": "include/",
    "checks": "tag-usage",
    "language": "cpp"
  }
}
```

## Supported Languages

- **C++**: Classes, functions, templates, namespaces
- **C**: Functions, structs, enums, typedefs
- **Java**: Classes, interfaces, methods, packages
- **Python**: Classes, functions, modules
- **C#**: Classes, methods, properties, namespaces

## Common Issues Detected

### Link Generation Issues

```cpp
// ❌ Error: Unqualified reference
/**
 * @see MyClass
 */

// ✅ Fixed: Namespace-qualified reference
/**
 * @see MyNamespace::MyClass
 */
```

### Missing Documentation Tags

```cpp
// ❌ Warning: Missing @return
/**
 * Calculate the sum of two numbers.
 * @param a First number
 * @param b Second number
 */
int add(int a, int b);

// ✅ Fixed: Complete documentation
/**
 * Calculate the sum of two numbers.
 * @param a First number
 * @param b Second number
 * @return Sum of a and b
 */
int add(int a, int b);
```

### Formatting Issues

```cpp
// ❌ Error: Malformed code block
/**
 * Example usage:
 * @code
 * MyClass obj;
 * // Missing @endcode
 */

// ✅ Fixed: Proper code block
/**
 * Example usage:
 * @code
 * MyClass obj;
 * obj.doSomething();
 * @endcode
 */
```

### Organization Suggestions

```cpp
// ❌ Suggestion: Ungrouped related functions
/**
 * Login to the system.
 */
void login(const char* user, const char* pass);

/**
 * Logout from the system.
 */
void logout();

// ✅ Fixed: Grouped with @defgroup
/**
 * @defgroup auth Authentication Functions
 * Functions for user authentication and session management.
 * @{
 */

/**
 * Login to the system.
 * @ingroup auth
 */
void login(const char* user, const char* pass);

/**
 * Logout from the system.
 * @ingroup auth
 */
void logout();

/** @} */ // end of auth group
```

## Tool Requirements

- **Doxygen**: Doxygen 1.9.0 or later (for validation)
- **Parser**: Language-specific parser (Clang for C++, javadoc for Java, etc.)
- **Config**: Optional Doxyfile for project-specific settings

## Constraints

This skill does NOT:
- Generate HTML/PDF documentation output (use doxygen directly)
- Modify source code or documentation comments
- Write new documentation content
- Install Doxygen or configure build systems
- Execute full Doxygen builds
- Interpret code behavior or logic
- Generate API documentation from scratch

## Error Handling

Returns structured error information for:

- **Doxygen not found**: Doxygen not installed or not in PATH
- **Invalid path**: File or directory doesn't exist
- **Parse errors**: Unable to parse source files
- **Invalid config**: Malformed or missing Doxyfile
- **Unsupported language**: Language not supported by Doxygen
- **Syntax errors**: Invalid Doxygen tag syntax
- **Timeout**: Validation exceeding time limit

Example error response:

```json
{
  "error": {
    "type": "doxygen-not-found",
    "message": "Doxygen not found. Install from https://www.doxygen.nl/download.html",
    "installCommand": "brew install doxygen"
  }
}
```

## Common Doxygen Tag Issues

### Parameter Documentation

```cpp
// ❌ Error: Undocumented parameter
/**
 * Process the request.
 * @param req The request object
 */
void process(Request* req, Options* opts);

// ✅ Fixed: All parameters documented
/**
 * Process the request.
 * @param req The request object to process
 * @param opts Processing options (can be NULL for defaults)
 */
void process(Request* req, Options* opts);
```

### Return Value Documentation

```cpp
// ❌ Warning: Missing return documentation
/**
 * Check if user is authenticated.
 */
bool isAuthenticated();

// ✅ Fixed: Return value documented
/**
 * Check if user is authenticated.
 * @return true if user is authenticated, false otherwise
 */
bool isAuthenticated();
```

### Exception Documentation

```cpp
// ❌ Warning: Undocumented exception
/**
 * Open a network connection.
 * @param host The hostname to connect to
 */
void connect(const char* host);

// ✅ Fixed: Exception documented
/**
 * Open a network connection.
 * @param host The hostname to connect to
 * @throws NetworkException if connection fails
 * @throws InvalidHostException if host is NULL or empty
 */
void connect(const char* host);
```

## Best Practices

### Complete Function Documentation

```cpp
/**
 * @brief Process payment transaction
 *
 * @details This function validates payment details, charges the card,
 * and updates the transaction record. The operation is atomic and will
 * roll back on any failure.
 *
 * @param amount Transaction amount in cents (must be positive)
 * @param card Card details for payment (must be valid)
 * @param receipt Output parameter for transaction receipt
 *
 * @return true if payment succeeded, false on validation failure
 *
 * @throws PaymentException if payment processing fails
 * @throws DatabaseException if transaction record update fails
 *
 * @note This function requires an active database connection
 * @warning Card details are not validated by this function
 *
 * @see validateCard() for card validation
 * @see refundPayment() for reversing transactions
 *
 * Example usage:
 * @code
 * PaymentCard card = {"4111111111111111", "12/25", "123"};
 * Receipt receipt;
 * if (processPayment(1000, &card, &receipt)) {
 *     printf("Payment successful: %s\n", receipt.id);
 * }
 * @endcode
 */
bool processPayment(int amount, PaymentCard* card, Receipt* receipt);
```

### Class Documentation

```cpp
/**
 * @brief Payment processing service
 *
 * @details Handles payment transactions including authorization,
 * capture, refunds, and transaction history. Supports multiple
 * payment methods and currencies.
 *
 * Thread-safe: All public methods can be called concurrently.
 *
 * Example usage:
 * @code
 * PaymentService service;
 * service.initialize("api_key_here");
 * auto result = service.charge(1000, card);
 * @endcode
 *
 * @see PaymentCard
 * @see Transaction
 * @see Receipt
 *
 * @ingroup payment Payment Processing
 */
class PaymentService {
    // ...
};
```

### File Documentation

```cpp
/**
 * @file payment.h
 * @brief Payment processing API
 *
 * @details This file provides the core payment processing interface
 * for the application. It includes functions for charging cards,
 * processing refunds, and managing transactions.
 *
 * @author Engineering Team
 * @version 2.0
 * @date 2025-12-14
 *
 * @copyright Copyright (c) 2025 Company Name
 */
```

## Integration with Build Systems

### CMake Integration

```cmake
find_package(Doxygen REQUIRED)

set(DOXYGEN_GENERATE_HTML YES)
set(DOXYGEN_GENERATE_MAN NO)
set(DOXYGEN_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/docs)

doxygen_add_docs(
    docs
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_SOURCE_DIR}/src
    COMMENT "Generating API documentation with Doxygen"
)
```

### Makefile Integration

```makefile
.PHONY: docs docs-validate

docs:
	doxygen Doxyfile

docs-validate:
	@echo "Validating Doxygen documentation..."
	# Validation happens through the skill
```

## Documentation Quality Metrics

The validator reports:
- **Coverage**: % of public items with documentation
- **Completeness**: % of docs with all required tags
- **Link validity**: % of cross-references that resolve
- **Quality score**: Overall documentation quality (0-100)

Example metrics:

```json
{
  "metrics": {
    "coverage": 84.4,
    "completeness": 76.2,
    "linkValidity": 95.8,
    "qualityScore": 82
  }
}
```
