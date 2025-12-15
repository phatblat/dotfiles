# Markdown Validator

Validate Markdown documentation files for correctness, style, and consistency.

## Capability

This skill validates Markdown files for syntax errors, style violations, broken links, formatting issues, and best practices compliance. It supports CommonMark, GitHub Flavored Markdown (GFM), and other Markdown variants.

## Supported Operations

### Validation Checks
- **syntax** - Check Markdown syntax errors
- **style** - Validate style consistency (headings, lists, emphasis)
- **links** - Verify internal and external links
- **formatting** - Check code blocks, tables, indentation
- **accessibility** - Ensure accessible content (alt text, heading hierarchy)
- **spelling** - Check spelling and grammar (optional)
- **all** - Complete validation (default)

## Usage Protocol

Agents invoke this skill by specifying validation parameters:

```json
{
  "action": "markdown",
  "command": "validate",
  "args": {
    "path": "docs/",
    "checks": "all",
    "flavor": "gfm",
    "configFile": ".markdownlint.json"
  }
}
```

### Parameters

- **action** (required): Always `"markdown"`
- **command** (required): Validation command (always "validate")
- **args** (required): Command-specific arguments (see below)
- **workdir** (optional): Working directory for command execution
- **timeout** (optional): Timeout in seconds (default: 120s)

### Validate Args
```json
{
  "path": "README.md",
  "checks": "all",
  "flavor": "gfm",
  "configFile": ".markdownlint.json",
  "strictMode": false,
  "fixable": true
}
```

## Output Format

Returns structured JSON validation report:

```json
{
  "validationReport": {
    "timestamp": "2025-12-14T18:00:00Z",
    "action": "markdown",
    "command": "validate",
    "path": "docs/",
    "exitCode": 0,
    "duration": "1.8s",
    "status": "success",
    "filesChecked": 23,
    "issues": [
      {
        "file": "docs/api.md",
        "line": 45,
        "column": 1,
        "severity": "error",
        "rule": "MD041",
        "message": "First line in file should be a top level heading",
        "fixable": true,
        "suggestion": "Add # Heading at the top of the file"
      },
      {
        "file": "docs/guide.md",
        "line": 123,
        "column": 15,
        "severity": "warning",
        "rule": "MD034",
        "message": "Bare URL used",
        "fixable": true,
        "suggestion": "Use [link text](url) format instead of bare URL"
      },
      {
        "file": "docs/reference.md",
        "line": 89,
        "column": 5,
        "severity": "suggestion",
        "rule": "MD012",
        "message": "Multiple consecutive blank lines",
        "fixable": true,
        "suggestion": "Remove extra blank lines"
      }
    ],
    "summary": {
      "errors": 4,
      "warnings": 15,
      "suggestions": 7,
      "fixableIssues": 20
    },
    "linkCheck": {
      "totalLinks": 156,
      "validLinks": 148,
      "brokenLinks": 5,
      "skippedLinks": 3,
      "brokenLinkDetails": [
        {
          "file": "docs/api.md",
          "line": 234,
          "url": "https://example.com/missing",
          "status": 404,
          "message": "Not Found"
        }
      ]
    },
    "metrics": {
      "totalFiles": 23,
      "totalLines": 3456,
      "averageLineLength": 67,
      "headingCount": 89,
      "codeBlockCount": 145,
      "linkCount": 156
    }
  }
}
```

### Issue Severities

- **error**: Syntax errors, broken required elements
- **warning**: Style violations, potential issues
- **suggestion**: Minor improvements, formatting preferences

### Markdown Rules (markdownlint)

Common rules checked:
- **MD001**: Heading levels should increment by one
- **MD003**: Heading style consistency
- **MD004**: Unordered list style consistency
- **MD009**: No trailing spaces
- **MD012**: No multiple consecutive blank lines
- **MD013**: Line length (default 80 characters)
- **MD022**: Headings should be surrounded by blank lines
- **MD025**: Only one top-level heading
- **MD031**: Code blocks should be fenced
- **MD034**: Bare URLs should be formatted as links
- **MD040**: Code blocks should specify language
- **MD041**: First line should be top-level heading

## Common Markdown Operations

### Validate Single File
```json
{
  "action": "markdown",
  "command": "validate",
  "args": {
    "path": "README.md",
    "checks": "all",
    "flavor": "gfm"
  }
}
```

### Check Only Links
```json
{
  "action": "markdown",
  "command": "validate",
  "args": {
    "path": "docs/",
    "checks": "links",
    "flavor": "gfm"
  }
}
```

### Validate with Custom Config
```json
{
  "action": "markdown",
  "command": "validate",
  "args": {
    "path": "docs/",
    "checks": "all",
    "configFile": ".markdownlint.json",
    "strictMode": true
  }
}
```

### Find Fixable Issues
```json
{
  "action": "markdown",
  "command": "validate",
  "args": {
    "path": "*.md",
    "checks": "style",
    "fixable": true
  }
}
```

## Supported Markdown Flavors

- **CommonMark**: Standard Markdown specification
- **GFM** (GitHub Flavored Markdown): GitHub's variant (default)
- **Kramdown**: Jekyll/GitHub Pages Markdown
- **MultiMarkdown**: Extended Markdown with metadata
- **Pandoc**: Pandoc's extended Markdown

## Common Issues Detected

### Heading Issues

```markdown
❌ Error: MD001 - Heading levels skip
# Heading 1
### Heading 3

✅ Fixed: Increment by one level
# Heading 1
## Heading 2
```

### Link Issues

```markdown
❌ Warning: MD034 - Bare URL
Check out https://example.com for more info.

✅ Fixed: Proper link format
Check out [Example Site](https://example.com) for more info.
```

### Code Block Issues

```markdown
❌ Warning: MD040 - Missing language
```
def hello():
    print("Hello")
```

✅ Fixed: Specify language
```python
def hello():
    print("Hello")
```
```

### List Issues

```markdown
❌ Error: MD004 - Inconsistent list style
* Item 1
- Item 2
+ Item 3

✅ Fixed: Consistent markers
* Item 1
* Item 2
* Item 3
```

### Spacing Issues

```markdown
❌ Warning: MD012 - Multiple blank lines



Content here

✅ Fixed: Single blank line

Content here
```

### Image Alt Text

```markdown
❌ Warning: Missing alt text
![](image.png)

✅ Fixed: Descriptive alt text
![Architecture diagram showing data flow](image.png)
```

## Tool Requirements

- **markdownlint**: Node.js markdownlint-cli for style checking
- **markdown-link-check**: Link validation tool
- **remark**: Markdown processor (optional)
- **vale**: Prose linter (optional, for advanced style checking)

## Constraints

This skill does NOT:
- Convert Markdown to HTML/PDF
- Modify Markdown files automatically
- Generate Markdown content
- Install validation tools
- Render Markdown for preview
- Check code examples within Markdown
- Validate embedded diagrams (mermaid, etc.)
- Perform deep content analysis

## Error Handling

Returns structured error information for:

- **Validator not found**: markdownlint not installed
- **Invalid path**: File or directory doesn't exist
- **Parse errors**: Malformed Markdown syntax
- **Invalid config**: Malformed .markdownlint.json
- **Network errors**: Failed to check external links
- **Timeout**: Validation exceeding time limit

Example error response:

```json
{
  "error": {
    "type": "markdownlint-not-found",
    "message": "markdownlint-cli not found. Install with npm install -g markdownlint-cli",
    "installCommand": "npm install -g markdownlint-cli"
  }
}
```

## Configuration Example

### .markdownlint.json

```json
{
  "default": true,
  "MD003": { "style": "atx" },
  "MD004": { "style": "dash" },
  "MD007": { "indent": 2 },
  "MD013": {
    "line_length": 120,
    "code_blocks": false,
    "tables": false
  },
  "MD024": { "siblings_only": true },
  "MD033": false,
  "MD041": false
}
```

### .markdownlintignore

```
node_modules/
.git/
vendor/
CHANGELOG.md
```

## Best Practices

### Document Structure

```markdown
# Project Name

Brief description of the project.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Contributing](#contributing)

## Installation

Installation instructions here.

## Usage

Usage examples here.

```bash
npm install my-package
```

## API Reference

API documentation here.

## Contributing

Contribution guidelines here.
```

### Code Blocks with Language

```markdown
✅ Always specify language
```javascript
const greeting = "Hello World";
console.log(greeting);
```

```python
def greet():
    print("Hello World")
```

```bash
npm install
npm test
```
```

### Link Formatting

```markdown
✅ Descriptive link text
See the [API documentation](./docs/api.md) for details.

❌ Avoid "click here" links
Click [here](./docs/api.md) for details.
```

### Image Best Practices

```markdown
✅ Descriptive alt text
![System architecture diagram showing microservices](./images/arch.png)

✅ Relative paths for local images
![Logo](./assets/logo.png)

✅ Reference style for repeated images
![Logo][logo]

[logo]: ./assets/logo.png "Company Logo"
```

### Table Formatting

```markdown
✅ Aligned columns
| Feature    | Supported | Notes           |
|------------|-----------|-----------------|
| Auth       | Yes       | OAuth 2.0       |
| Caching    | Yes       | Redis backend   |
| Logging    | Partial   | Console only    |
```

## Integration with Build Systems

### npm Scripts

```json
{
  "scripts": {
    "lint:md": "markdownlint '**/*.md' --ignore node_modules",
    "lint:md:fix": "markdownlint '**/*.md' --ignore node_modules --fix",
    "check:links": "markdown-link-check README.md"
  }
}
```

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.39.0
    hooks:
      - id: markdownlint
        args: ['--fix']
```

### GitHub Actions

```yaml
name: Markdown Validation
on: [push, pull_request]
jobs:
  markdown:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm install -g markdownlint-cli
      - run: markdownlint '**/*.md'
```

## Documentation Quality Metrics

The validator reports:
- **Files checked**: Total Markdown files validated
- **Issue density**: Issues per 100 lines
- **Link health**: % of valid links
- **Style compliance**: % of rules passing
- **Fixable ratio**: % of issues auto-fixable

Example metrics:

```json
{
  "metrics": {
    "filesChecked": 23,
    "totalLines": 3456,
    "issueDensity": 0.75,
    "linkHealth": 95.8,
    "styleCompliance": 88.3,
    "fixableRatio": 76.9
  }
}
```

## Common Markdown Pitfalls

### Heading Hierarchy

```markdown
❌ Skip heading levels
# Main Title
### Subsection

✅ Proper hierarchy
# Main Title
## Section
### Subsection
```

### List Indentation

```markdown
❌ Inconsistent indentation
* Item 1
  * Subitem 1
    * Sub-subitem 1

✅ Consistent 2-space indentation
* Item 1
  * Subitem 1
    * Sub-subitem 1
```

### Code Block Fencing

```markdown
❌ Indented code blocks (less clear)
    def hello():
        print("Hello")

✅ Fenced code blocks with language
```python
def hello():
    print("Hello")
```
```

### Emphasis Style

```markdown
❌ Mixing styles
This is *italic* and this is _also italic_.

✅ Consistent style (choose one)
This is *italic* and this is *also italic*.
```
