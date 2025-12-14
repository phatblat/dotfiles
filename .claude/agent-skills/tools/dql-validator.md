# DQL Validator Skill

Validate Ditto Query Language (DQL) queries for syntax correctness, optimization, and compatibility.

## Capability

Analyzes DQL (Ditto Query Language) queries for:
- **Syntax validation** — Check for correct DQL syntax
- **Compatibility** — Verify compatibility with DQL feature set
- **Optimization** — Suggest performance improvements
- **Migration** — Identify legacy query builder patterns and suggest DQL equivalents
- **Type hints** — Validate type hints for special fields (ATTACHMENT, etc.)

Returns validation report with issues, suggestions, and optimization opportunities.

## How to Use This Skill

### Input
```
{
  "action": "validate",
  "query": "SELECT * FROM users WHERE age > 18",           // DQL query to validate
  "validateFor": "syntax|compatibility|optimization|all",  // Validation type
  "referenceVersion": "v4|v5-preview"                       // SDK version (default: latest)
}
```

### Output

Returns structured validation report:
```
{
  "status": "valid",  // valid|warning|error
  "query": "SELECT * FROM users WHERE age > 18",
  "queryType": "SELECT",
  "validation": {
    "syntax": {
      "status": "valid",
      "issues": []
    },
    "compatibility": {
      "status": "valid",
      "issues": [],
      "supportedIn": ["v4", "v5-preview"]
    },
    "optimization": {
      "status": "ok",
      "suggestions": [
        {
          "type": "index_hint",
          "message": "Consider indexing the 'age' field for faster WHERE clause filtering",
          "priority": "medium"
        }
      ]
    }
  },
  "details": {
    "queryType": "SELECT",
    "clauses": ["FROM", "WHERE"],
    "collections": ["users"],
    "usesTypeHints": false,
    "usesParameters": false
  },
  "validationTime": "0.02s"
}
```

## Validation Types

### syntax
Validates DQL query syntax against language rules.

**Returns**:
- Valid syntax check
- Parse errors with line/column positions
- Missing required clauses

**Example Issues**:
- `"Invalid syntax: Unexpected token 'FORM' at position 15. Did you mean 'FROM'?"`
- `"Missing required clause: INSERT statements require VALUES clause"`
- `"Invalid WHERE condition syntax: operator '==' not supported, use '='"`

### compatibility
Verifies query uses only documented DQL features.

**Returns**:
- Feature compatibility status
- Unsupported syntax errors
- Version-specific feature availability

**Example Issues**:
- `"Unsupported operator '&&' in DQL. Use 'AND' instead"`
- `"LIMIT without ORDER BY may produce non-deterministic results"`
- `"JOINs are not supported in DQL. Use separate queries with document references"`

### optimization
Suggests performance improvements.

**Returns**:
- Indexing recommendations
- Query rewriting suggestions
- Performance implications

**Example Suggestions**:
- `"Add index on 'status' field - WHERE clause references this frequently"`
- `"OFFSET is expensive. Use cursor-based pagination instead"`
- `"Multiple OR conditions on same field - consider IN operator"`

### all
Runs all validation types (syntax + compatibility + optimization).

## DQL Quick Reference (Supported Constructs)

### SELECT
```
SELECT [fields | *]
FROM collection_name
[WHERE condition]
[ORDER BY field [ASC|DESC], ...]
[LIMIT number]
[OFFSET number]
```

### INSERT
```
INSERT INTO collection_name
VALUES([doc1]), ([doc2]), ...
[ON ID CONFLICT [FAIL | DO NOTHING | DO MERGE]]
```

### UPDATE
```
UPDATE collection_name
SET field1 = value1, field2 -> [mutator], ...
[WHERE condition]
```

### DELETE
```
DELETE FROM collection_name
[WHERE condition]
[ORDER BY field]
[LIMIT number]
```

### EVICT
```
EVICT FROM collection_name
[WHERE condition]
```

### Type Hints
```
INSERT INTO collection (field ATTACHMENT) DOCUMENTS (:doc)
```

## Protocol

1. **Receive DQL query** and validation type
2. **Parse query** against DQL grammar
3. **Check syntax** validity
4. **Verify compatibility** with DQL feature set
5. **Analyze performance** implications
6. **Return validation report** with issues and suggestions
7. **Do NOT modify** the query (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or rewrite queries
- Execute queries against Ditto
- Generate DQL from natural language
- Provide SQL-to-DQL conversion (agent's responsibility)
- Validate against specific schema/collections
- Check runtime permissions or authentication

## Common DQL Issues & Fixes

| Issue | Error | Fix |
|-------|-------|-----|
| SQL equality operator | `"Unexpected token '=='"` | Use `=` instead of `==` |
| Missing FROM clause | `"Missing required FROM clause"` | Add `FROM collection_name` |
| Invalid ORDER BY | `"ORDER BY field missing in SELECT"` | Field must be selected or use `*` |
| LIMIT without ORDER BY | Warning | Results non-deterministic, add ORDER BY |
| Unsupported JOIN | `"JOINs not supported"` | Use separate queries, reference documents |
| Legacy COLLECTION keyword | `"Invalid syntax near COLLECTION"` | Use `FROM collection_name` directly |

## Example Invocations

### Validate SELECT Query
```
[invoke dql-validator]
input: {
  "action": "validate",
  "query": "SELECT * FROM tasks WHERE status = 'active' ORDER BY created_at DESC LIMIT 10",
  "validateFor": "all"
}

Output:
{
  "status": "valid",
  "queryType": "SELECT",
  "validation": {
    "syntax": {
      "status": "valid",
      "issues": []
    },
    "compatibility": {
      "status": "valid"
    },
    "optimization": {
      "suggestions": [
        {
          "type": "indexing",
          "message": "Consider indexing 'status' and 'created_at' fields"
        }
      ]
    }
  }
}
```

### Detect Migration Issues
```
[invoke dql-validator]
input: {
  "action": "validate",
  "query": "SELECT * FROM users WHERE age == 18",
  "validateFor": "compatibility"
}

Output:
{
  "status": "error",
  "queryType": "SELECT",
  "validation": {
    "syntax": {
      "status": "valid"
    },
    "compatibility": {
      "status": "error",
      "issues": [
        {
          "type": "syntax_error",
          "message": "DQL uses '=' not '==' for equality",
          "position": 33,
          "suggestion": "Replace '==' with '=' operator"
        }
      ]
    }
  }
}
```

## Error Cases

| Scenario | Response |
|----------|----------|
| Invalid DQL syntax | `"Syntax error at position [N]: [description]. Expected [token]"` |
| Empty query | `"Empty query provided"` |
| Unsupported clause | `"Unsupported clause: [clause]. Supported: SELECT, INSERT, UPDATE, DELETE, EVICT"` |
| Invalid WHERE condition | `"Invalid WHERE condition syntax: [description]"` |
| Type hint error | `"Invalid type hint: [type]. Supported: ATTACHMENT, and all DQL data types"` |
| Collection name missing | `"FROM clause requires collection name"` |

## Integration Notes

- **Used by agents**: dql-expert, ditto-sdk-expert, implementor
- **Returns structured data**: Validation report with issues and suggestions
- **Version-aware**: Can validate against specific SDK versions
- **Migration-aware**: Identifies legacy query builder patterns
- **No execution**: Read-only validation - never executes queries
- **No modification**: Returns issues only - agent handles rewrites
- **Supports all DQL constructs**: SELECT, INSERT, UPDATE, DELETE, EVICT with all optional clauses
- **Comprehensive**: Syntax, compatibility, optimization, and migration detection
