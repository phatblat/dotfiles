# Format Converter Skill

Convert data between different structured and semi-structured formats.

## Capability

Transforms data between:
- **Structured formats**: JSON, YAML, XML, TOML
- **Tabular formats**: CSV, TSV, Markdown tables
- **Text formats**: Plain text, JSON Lines (JSONL)

Returns converted data with validation report and conversion statistics.

## Supported Formats

| Format | Extensions | MIME Type | Best For |
|--------|-----------|-----------|----------|
| JSON | .json | application/json | APIs, nested data |
| YAML | .yaml, .yml | application/yaml | Config, readability |
| XML | .xml | application/xml | Hierarchical, SOAP |
| CSV | .csv | text/csv | Spreadsheets, tables |
| TSV | .tsv | text/tab-separated | Tab-delimited data |
| TOML | .toml | application/toml | Configuration files |
| Markdown | .md | text/markdown | Tables, documentation |
| JSONL | .jsonl, .ndjson | application/x-ndjson | Streaming, logs |
| Plain Text | .txt | text/plain | Simple structured text |

## How to Use This Skill

### Input
```
{
  "action": "convert",
  "sourceData": "...",                   // Data to convert (string or path)
  "sourceFormat": "json",                // auto|json|yaml|xml|csv|tsv|toml|jsonl|markdown|text
  "targetFormat": "yaml",                // Target format
  "encoding": "utf-8",                   // Character encoding
  "options": {
    "indent": 2,                         // Indentation level
    "strict": false,                     // Strict validation
    "preserveComments": true             // Keep comments if possible
  }
}
```

### Output

Returns conversion report:
```
{
  "status": "success",  // success|error|warning
  "sourceFormat": "json",
  "targetFormat": "yaml",
  "encoding": "utf-8",
  "conversion": {
    "success": true,
    "warnings": [],
    "output": "key: value\narray:\n  - item1\n  - item2\n",
    "outputSize": "145 bytes",
    "conversionTime": "0.02s"
  },
  "validation": {
    "status": "valid",
    "issues": [],
    "dataIntegrity": "100%",
    "recordsProcessed": 42,
    "recordsPreserved": 42
  },
  "metadata": {
    "sourceLineCount": 12,
    "targetLineCount": 8,
    "dataType": "object",
    "topLevelKeys": ["key", "array"]
  }
}
```

## Conversion Matrix

### JSON ↔ Other Formats

**JSON → YAML**
- Prettier, human-readable
- Preserves nesting and types
- Good for config files

**JSON → XML**
- Converts objects to elements
- Arrays become repeated elements
- May require schema for clarity

**JSON → CSV**
- Flattens nested structures
- Each object becomes a row
- Headers from top-level keys
- Warning: loses hierarchy

**JSON → Markdown**
- Creates formatted tables (for arrays of objects)
- Creates key-value lists
- Good for documentation

### CSV ↔ JSON

**CSV → JSON**
- Headers become keys
- Each row becomes an object
- Creates array of objects
- Handles quoted values with commas

**CSV → Markdown**
- Creates Markdown table format
- Preserves column alignment
- Good for documentation

### YAML ↔ JSON

**YAML → JSON**
- Straightforward conversion
- Preserves structure
- Compact representation

### Text ↔ Structured

**Plain Text → CSV**
- Parses columns by delimiters
- Auto-detects CSV/TSV format
- Handles quoted fields

**Plain Text → JSON**
- Requires key:value pairs
- Supports nested structures
- Auto-detects indentation

## Protocol

1. **Receive source data** (inline or file path)
2. **Detect source format** (auto-detect or specified)
3. **Parse source data** validating structure
4. **Transform to target format**:
   - Apply format-specific rules
   - Handle type conversions
   - Preserve data integrity
5. **Validate output** for correctness
6. **Return conversion result** with metadata
7. **Do NOT modify original** data (agent's responsibility)

## Constraints

This skill **does not**:
- Modify source data
- Rewrite or restructure converted data
- Make decisions about data organization
- Handle extremely large files (>100MB in memory)
- Create entirely new data
- Perform complex business logic transformations

## Example Invocations

### Convert JSON to YAML

**Agent**: "Convert this JSON config to YAML"

```
[invoke format-converter]
input: {
  "action": "convert",
  "sourceData": "{\"app\": {\"name\": \"MyApp\", \"version\": \"1.0\"}}",
  "sourceFormat": "json",
  "targetFormat": "yaml"
}

Output:
{
  "status": "success",
  "sourceFormat": "json",
  "targetFormat": "yaml",
  "conversion": {
    "success": true,
    "output": "app:\n  name: MyApp\n  version: '1.0'\n"
  },
  "validation": {
    "status": "valid",
    "dataIntegrity": "100%"
  }
}
```

### Convert CSV to JSON

```
[invoke format-converter]
input: {
  "action": "convert",
  "sourceData": "name,age,city\nAlice,30,NYC\nBob,25,LA",
  "sourceFormat": "csv",
  "targetFormat": "json"
}

Output:
{
  "status": "success",
  "conversion": {
    "success": true,
    "output": "[{\"name\":\"Alice\",\"age\":\"30\",\"city\":\"NYC\"},{\"name\":\"Bob\",\"age\":\"25\",\"city\":\"LA\"}]"
  },
  "metadata": {
    "recordsProcessed": 2,
    "recordsPreserved": 2
  }
}
```

## Format-Specific Options

### JSON
- `indent`: Number of spaces for indentation (default: 2)
- `compact`: Remove unnecessary whitespace (default: false)
- `sortKeys`: Sort object keys alphabetically (default: false)

### YAML
- `indent`: Indentation level (default: 2)
- `lineWidth`: Line width for wrapping (default: 80)
- `preserveQuotes`: Keep quoted strings (default: false)

### CSV
- `delimiter`: Field delimiter (auto-detect or `,` `;` `\t`)
- `quoteChar`: Quote character (default: `"`)
- `header`: Include header row (default: true)

### XML
- `indent`: Indentation level (default: 2)
- `declaration`: Include XML declaration (default: true)
- `rootElement`: Name for root element when needed (default: `root`)

## Error Cases

| Scenario | Response |
|----------|----------|
| Invalid source format | `"Unknown source format: [format]. Supported: json, yaml, xml, csv, tsv, toml, jsonl, markdown, text"` |
| Invalid target format | `"Unknown target format: [format]. Supported: [list]"` |
| Malformed source data | `"Parse error at line [N]: [error details]"` |
| Unsupported conversion | `"Conversion not supported: [source] → [target]"` |
| Data loss warning | `"Warning: Nested structure will be flattened in CSV format"` |
| Encoding error | `"Encoding error: Cannot encode as [encoding]. Available: [list]"` |
| File too large | `"File too large: [size]. Maximum supported: 100MB"` |

## Data Integrity

The skill validates:
- All records preserved (record count before/after)
- Data types maintained where possible
- String escaping handled correctly
- Special characters preserved
- Nesting/hierarchy maintained (when target format supports it)

Returns:
- `dataIntegrity`: Percentage (0-100%)
- `recordsProcessed`: Count of input records
- `recordsPreserved`: Count of output records
- `warnings`: Any data loss or conversion limitations

## Integration Notes

- **Used by agents**: data-format-converter, api-developer, documentation-generator
- **Returns structured data**: Converted content + validation report
- **Format-aware**: Handles format-specific quirks
- **Lossless when possible**: Warns about lossy conversions
- **No side effects**: Read-only, no file modifications
- **Encoding-aware**: Handles UTF-8 and other encodings
