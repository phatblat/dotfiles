# Code Browser Skill

Search and locate code implementations, patterns, and relationships within a codebase.

## Capability

Systematically searches a codebase to find specific functionality, implementations, usage patterns, and code relationships. Returns complete results with file paths, line numbers, and code snippets.

## Use Cases

- **Find implementations**: "Where is the authentication system implemented?"
- **Locate usage**: "Where is `fetchUser()` being called?"
- **Trace patterns**: "Show all error handling in the codebase"
- **Map relationships**: "What calls `processPayment()`?"
- **Search concepts**: "Find all code related to MQTT messaging"

## How to Use This Skill

### Input
```
{
  "action": "search",
  "query": "user authentication flow",      // What to find
  "searchType": "concept",                  // concept|function|pattern|implementation|usage
  "fileFilter": "**/*.{ts,tsx,js}",        // Optional: limit to file types
  "workDir": "."                            // Optional: search root directory
}
```

### Output

Returns structured results:
```
{
  "findings": [
    {
      "file": "src/auth/login.ts",
      "line": 42,
      "type": "implementation",
      "snippet": "function authenticate(credentials) { ... }",
      "relevance": "primary"
    },
    {
      "file": "src/middleware/auth.ts",
      "line": 15,
      "type": "usage",
      "snippet": "const result = authenticate(user);",
      "relevance": "related"
    }
  ],
  "summary": "Found 12 files with authentication code: 3 implementations, 9 usages",
  "searchStrategy": ["grepped for 'authenticate', 'login', 'credential', 'auth'],
  "totalResults": 12,
  "searchTime": "1.2s"
}
```

## Search Types

| Type | Finds | Examples |
|------|-------|----------|
| `implementation` | Function/class definitions, core logic | Where `getUserById` is defined |
| `usage` | Function calls, references, invocations | Where `getUserById()` is called |
| `pattern` | Code patterns, architectures, conventions | All error handling patterns |
| `concept` | Related code by feature/domain | "Payment processing" code |
| `inheritance` | Class hierarchies, interfaces | What extends `BaseController` |

## Protocol

1. **Parse Query**: Identify keywords and search terms
2. **Develop Strategy**: Break down into specific searches
   - Exact function/class names
   - Related naming variants (getUser, fetchUser, loadUser)
   - Common patterns (error handlers, middleware, etc.)
3. **Execute Searches**: Use grep, file patterns, code analysis
4. **Collect Results**: File paths, line numbers, code snippets
5. **Group Results**: By relevance (primary implementations vs. usage)
6. **Return Complete Results**: All matches found, let agent interpret

## Constraints

This skill **does not**:
- Analyze or interpret search results
- Recommend architectural changes
- Summarize findings beyond raw results
- Execute code or run tests
- Modify any files
- Provide performance analysis

## Example Invocation

**Agent**: "I need to understand the payment flow in this codebase"

```
[invoke code-browser skill]
Input: {
  "action": "search",
  "query": "payment processing flow",
  "searchType": "concept"
}

Output:
{
  "findings": [
    {
      "file": "src/payments/processor.ts",
      "line": 34,
      "type": "implementation",
      "snippet": "export async function processPayment(amount, method) { ... }",
      "relevance": "primary"
    },
    {
      "file": "src/api/routes/checkout.ts",
      "line": 156,
      "type": "usage",
      "snippet": "const result = await processPayment(cart.total, 'card');",
      "relevance": "primary"
    },
    ...
  ],
  "summary": "Found 15 files: 3 implementations, 12 usages/related code",
  "totalResults": 15
}

Agent then: "I found the payment system with 3 main implementations and 12 related files. The core is in src/payments/processor.ts. Let me read those files to understand the flow..."
```

## Error Cases

| Scenario | Response |
|----------|----------|
| No results found | `"No code found matching query: '[query]'. Try alternative terms or broader search."` |
| Invalid file filter | `"File filter didn't match any files. Check pattern: '[filter]'"` |
| Timeout on large searches | `"Search timeout after 30s. Try more specific query or narrower file filter."` |
| Working directory not found | `"Directory not found: '[path]'"` |
| Query too vague | `"Query too broad: '[query]'. Provide more specific keywords or use searchType parameter."` |

## Integration Notes

- **Used by agents**: research, code-analyzer, implementor, architecture-reviewer
- **Returns raw data**: Agent interprets results and decides what to read/analyze
- **Respects .gitignore**: Does not search ignored files/directories
- **Language-agnostic**: Works across any text-based code language
- **Scale**: Efficient on codebases from 100 to 100,000+ files
