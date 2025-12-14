# Documentation Extractor Skill

Extract and analyze code to identify documentation requirements and extract documentation-relevant information.

## Capability

Analyzes source code to:
- **Extract documentation comments** — Pull existing doc comments, doc blocks, and inline explanations
- **Identify undocumented code** — Find public APIs, functions, and classes missing documentation
- **Parse code structure** — Extract method signatures, parameters, return types, and examples
- **Validate code examples** — Check syntax and identify executable examples in comments
- **Suggest structure** — Recommend documentation outline based on code organization

Returns structured data to inform documentation writing.

## Supported Languages

- Rust (doc comments: `///`, `//!`)
- Python (docstrings: `"""`, `'''`)
- Go (doc comments: `//`)
- JavaScript/TypeScript (JSDoc: `/** */`)
- Swift (doc comments: `///`, `/** */`)
- Ditto SDK documentation patterns (across languages)

## How to Use This Skill

### Input
```
{
  "action": "extract",
  "sourcePath": "src/lib.rs",              // File or directory
  "language": "rust",                      // rust|python|go|js|ts|swift|auto
  "extractTypes": "all",                   // all|comments|structure|examples|undocumented
  "publicOnly": true,                      // Only extract public APIs
  "includeExamples": true                  // Extract code examples from comments
}
```

### Output

Returns structured documentation data:
```
{
  "source": "src/lib.rs",
  "language": "rust",
  "summary": {
    "publicItems": 24,
    "documented": 18,
    "undocumented": 6,
    "documentationCoverage": "75%"
  },
  "items": [
    {
      "type": "struct",
      "name": "PaymentProcessor",
      "visibility": "public",
      "line": 42,
      "documentation": "Handles payment processing with async support.",
      "fields": [
        {
          "name": "client",
          "type": "HttpClient",
          "docs": "HTTP client for API requests"
        }
      ],
      "methods": [
        {
          "name": "process_payment",
          "signature": "async fn process_payment(&self, amount: u64) -> Result<Receipt>",
          "documentation": "Process a payment and return receipt.",
          "parameters": [
            {
              "name": "amount",
              "type": "u64",
              "docs": "Amount in cents"
            }
          ],
          "returns": {
            "type": "Result<Receipt>",
            "docs": "Payment receipt or error"
          },
          "examples": [
            {
              "code": "let receipt = processor.process_payment(1000).await?;",
              "inline": true
            }
          ]
        }
      ]
    }
  ],
  "undocumentedItems": [
    {
      "type": "fn",
      "name": "validate_amount",
      "line": 156,
      "signature": "fn validate_amount(amount: u64) -> bool"
    }
  ],
  "codeExamples": [
    {
      "location": "src/lib.rs:87",
      "language": "rust",
      "code": "let processor = PaymentProcessor::new(client);",
      "context": "Creating a payment processor",
      "syntaxValid": true
    }
  ],
  "suggestedStructure": [
    {
      "section": "Overview",
      "subsections": ["Purpose", "Key Features"]
    },
    {
      "section": "API Reference",
      "subsections": ["PaymentProcessor", "Receipt", "Error Types"]
    },
    {
      "section": "Examples",
      "subsections": ["Basic Usage", "Error Handling", "Advanced Patterns"]
    }
  ],
  "extractionTime": "0.5s"
}
```

## Extraction Types

### comments

Extract all documentation comments and docstrings.

**Returns**:
- Full text of doc comments
- Doc block structure (parameters, returns, examples)
- Associated code items

### structure

Extract code structure and organization.

**Returns**:
- Public APIs (functions, classes, traits, interfaces)
- Method signatures with parameter types
- Return types and error types
- Module/namespace organization

### examples

Extract and validate code examples from documentation.

**Returns**:
- Code snippets from doc comments
- Example context and purpose
- Syntax validation results
- Language and executable status

### undocumented

Identify code lacking documentation.

**Returns**:
- List of public items without doc comments
- Item types and signatures
- Location in source

## Protocol

1. **Receive source path** (file or directory)
2. **Detect language** (from extension or specified)
3. **Parse source code** and extract documentation artifacts
4. **Collect extraction data**:
   - Existing documentation
   - Code structure and signatures
   - Code examples
   - Undocumented items
5. **Analyze documentation coverage**
6. **Return structured data** (no document writing)
7. **Do NOT generate documentation** (agent's responsibility)

## Constraints

This skill **does not**:
- Write or generate documentation
- Modify source code
- Execute code examples (only validates syntax)
- Make decisions about documentation structure
- Enforce documentation standards
- Rewrite or improve existing documentation

## Example Invocation

**Agent**: "Help me document this Rust API"

```
[invoke doc-extractor]
input: {
  "action": "extract",
  "sourcePath": "src/payment.rs",
  "language": "rust",
  "extractTypes": "all"
}

Output:
{
  "source": "src/payment.rs",
  "summary": {
    "publicItems": 8,
    "documented": 6,
    "undocumented": 2,
    "documentationCoverage": "75%"
  },
  "items": [
    {
      "type": "fn",
      "name": "process_payment",
      "visibility": "public",
      "signature": "async fn process_payment(amount: u64) -> Result<Receipt>",
      "documentation": "Process a payment amount and return receipt."
    },
    ...
  ],
  "undocumentedItems": [
    {
      "type": "fn",
      "name": "validate_amount",
      "signature": "fn validate_amount(amount: u64) -> bool"
    }
  ],
  "suggestedStructure": [
    { "section": "Overview" },
    { "section": "API Reference" },
    { "section": "Examples" }
  ]
}

Agent then: "I found 8 public items with 75% documentation coverage.
Let me write documentation for the 2 undocumented functions and
improve the existing documentation with more examples..."
```

## Extraction Results Schema

| Field | Type | Purpose |
|-------|------|---------|
| `publicItems` | int | Count of public APIs |
| `documented` | int | Count with doc comments |
| `undocumented` | int | Count missing docs |
| `documentationCoverage` | string | Percentage documented |
| `items` | array | Detailed API information |
| `undocumentedItems` | array | APIs needing documentation |
| `codeExamples` | array | Extracted code examples |
| `suggestedStructure` | array | Recommended doc outline |

## Error Cases

| Scenario | Response |
|----------|----------|
| Source not found | `"Source not found: [path]"` |
| Unsupported language | `"Language not auto-detected. Specify language parameter."` |
| Parse error | `"Parse error in [file]:[line]. Check syntax."` |
| No public APIs found | `"No public APIs found in source"` |
| Invalid extraction type | `"Unknown extraction type: [type]. Use: all, comments, structure, examples, undocumented"` |

## Integration Notes

- **Used by agents**: tech-writer, documentation-reviewer, api-designer
- **Returns structured data**: Agent interprets and decides what to document
- **Language-aware**: Handles language-specific comment syntax
- **Example-focused**: Extracts runnable examples for validation
- **Coverage analysis**: Shows documentation gaps
- **No side effects**: Read-only operation, no file modifications
