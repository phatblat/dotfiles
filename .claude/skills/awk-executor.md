# AWK Executor

Execute AWK scripts and one-liners with structured output for data processing tasks.

## Capability

This skill executes AWK programs for pattern matching, text extraction, field processing, and data transformation. It returns structured results with exit codes, output, and execution metadata.

## Supported Operations

### AWK Execution Modes
- **one-liner** - Execute single-line AWK expressions
- **script** - Execute multi-line AWK programs
- **file** - Execute AWK script from file
- **pipeline** - Execute with preprocessing/postprocessing commands

### Input Sources
- **file** - Process one or more files
- **stdin** - Process piped input
- **inline** - Process inline data

### AWK Variants
- **awk** - macOS BSD awk (default on macOS)
- **gawk** - GNU awk (available via Homebrew on macOS, default on Linux)
- **auto** - Auto-detect based on platform and feature requirements

## Usage Protocol

Agents invoke this skill by specifying execution parameters:

```json
{
  "action": "execute",
  "mode": "one-liner",
  "script": "{ print $1, $3 }",
  "inputFiles": ["data.log"],
  "variant": "auto",
  "options": {
    "fieldSeparator": " ",
    "recordSeparator": "\n",
    "variables": {"threshold": "100"}
  }
}
```

### Parameters

- **action** (required): Always `"execute"`
- **mode** (required): `"one-liner"`, `"script"`, or `"file"`
- **script** (required for one-liner/script): AWK program code
- **scriptPath** (required for file mode): Path to AWK script file
- **inputFiles** (optional): Array of input files (omit for stdin)
- **variant** (optional): `"awk"`, `"gawk"`, or `"auto"` (default: "auto")
- **options** (optional): Execution options (see below)
- **timeout** (optional): Timeout in seconds (default: 60s)

### Options Object

```json
{
  "fieldSeparator": " ",           // -F flag (field separator)
  "recordSeparator": "\n",         // -v RS= (record separator)
  "outputFieldSeparator": " ",     // -v OFS= (output field separator)
  "outputRecordSeparator": "\n",   // -v ORS= (output record separator)
  "variables": {                   // -v key=value variables
    "threshold": "100",
    "prefix": "LOG"
  },
  "useRegexFS": false,             // Whether field separator is regex
  "ignoreCase": false,             // -v IGNORECASE=1
  "preProcess": "sort -k1",        // Command to run before AWK
  "postProcess": "uniq -c"         // Command to run after AWK
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "mode": "one-liner",
    "variant": "gawk",
    "inputFiles": ["server.log"],
    "exitCode": 0,
    "duration": "0.3s",
    "status": "success",
    "stdout": "192.168.1.1 GET\n192.168.1.2 POST\n",
    "stderr": "",
    "metadata": {
      "linesProcessed": 1247,
      "linesOutput": 89,
      "scriptLength": 23
    }
  }
}
```

### Successful Execution

```json
{
  "executionReport": {
    "mode": "one-liner",
    "variant": "gawk",
    "inputFiles": ["access.log"],
    "exitCode": 0,
    "duration": "0.8s",
    "status": "success",
    "stdout": "192.168.1.1 45\n192.168.1.2 23\n192.168.1.3 67\n",
    "stderr": "",
    "metadata": {
      "linesProcessed": 5423,
      "linesOutput": 3,
      "inputFileSize": "2.3MB"
    }
  }
}
```

### Execution with Pipeline

```json
{
  "executionReport": {
    "mode": "script",
    "variant": "awk",
    "pipeline": "sort -k1 | awk '...' | uniq -c",
    "exitCode": 0,
    "duration": "1.2s",
    "status": "success",
    "stdout": "   15 ERROR\n    3 FATAL\n  120 WARN\n",
    "metadata": {
      "preProcessed": true,
      "postProcessed": true,
      "linesProcessed": 138,
      "linesOutput": 3
    }
  }
}
```

## Common AWK Patterns

### Log Analysis - Extract Fields

```json
{
  "action": "execute",
  "mode": "one-liner",
  "script": "$3 == \"ERROR\" { print $1, $2, $5 }",
  "inputFiles": ["server.log"],
  "options": {
    "fieldSeparator": " "
  }
}
```

### CSV Processing - Sum Column

```json
{
  "action": "execute",
  "mode": "one-liner",
  "script": "{ sum += $4 } END { print sum }",
  "inputFiles": ["sales.csv"],
  "options": {
    "fieldSeparator": ","
  }
}
```

### Pattern Matching - Extract Between Markers

```json
{
  "action": "execute",
  "mode": "one-liner",
  "script": "/START/,/END/ { print }",
  "inputFiles": ["transactions.log"]
}
```

### Aggregation - Count by Field

```json
{
  "action": "execute",
  "mode": "one-liner",
  "script": "{ count[$2]++ } END { for (key in count) print key, count[key] }",
  "inputFiles": ["events.log"],
  "options": {
    "postProcess": "sort -k2 -nr"
  }
}
```

### Multi-Line Script - Complex Processing

```json
{
  "action": "execute",
  "mode": "script",
  "script": "BEGIN { FS=\",\"; OFS=\"\\t\" }\nNR > 1 { \n  if ($4 > threshold) {\n    print $1, $2, $4\n  }\n}",
  "inputFiles": ["data.csv"],
  "options": {
    "variables": {"threshold": "1000"}
  }
}
```

### Using Script File

```json
{
  "action": "execute",
  "mode": "file",
  "scriptPath": "scripts/analyze-logs.awk",
  "inputFiles": ["app.log", "error.log"],
  "options": {
    "variables": {"date": "2025-12-14"}
  }
}
```

## Variant Selection

### Auto-Detection Logic

When `variant: "auto"`:

1. Check for GNU-specific features in script:
   - `BEGINFILE`, `ENDFILE`
   - `strftime()`, `systime()`
   - `gensub()`, `patsplit()`
   - `\s`, `\S`, `\w`, `\W` in regex

2. If GNU features detected:
   - macOS: Use `gawk` (must be installed via Homebrew)
   - Linux: Use `awk` (usually gawk symlink)

3. If no GNU features:
   - Use system default `awk`

### Manual Selection

Specify variant explicitly when:
- Script requires specific GNU awk features → `"variant": "gawk"`
- Script must be POSIX-compliant → `"variant": "awk"`
- Testing cross-platform behavior

## Tool Requirements

- **awk**: BSD awk (pre-installed on macOS)
- **gawk**: GNU awk (install via `brew install gawk` on macOS)
- **Input files**: Must exist and be readable
- **Script files** (file mode): Must exist and be readable

## Constraints

This skill does NOT:
- Design or write AWK scripts (caller provides script)
- Analyze or interpret AWK output (returns raw output)
- Optimize AWK programs
- Debug AWK syntax errors (returns error as-is)
- Modify input files
- Install AWK or gawk
- Choose between sed/grep/awk (caller decides)
- Parse structured formats (JSON, XML) without appropriate script
- Handle interactive input
- Generate reports or visualizations

## Error Handling

Returns structured error information for:

- **AWK syntax error**: Script parsing failure
- **File not found**: Input file or script file missing
- **Permission denied**: Cannot read input files
- **Timeout exceeded**: Processing took too long
- **gawk not found**: GNU awk required but not installed
- **Invalid field separator**: Regex syntax error in FS
- **Out of memory**: Large file processing failure

Example error response:

```json
{
  "error": {
    "type": "awk-syntax-error",
    "message": "awk: syntax error at source line 1",
    "exitCode": 2,
    "stderr": "awk: syntax error at source line 1\n awk: bailing out at source line 1",
    "script": "{ print $1 $2 }",
    "solution": "Missing comma or operator between fields. Try: { print $1, $2 }"
  }
}
```

### gawk Not Found

```json
{
  "error": {
    "type": "gawk-not-found",
    "message": "GNU awk required but not found",
    "exitCode": 127,
    "stderr": "command not found: gawk",
    "solution": "Install GNU awk: brew install gawk"
  }
}
```

### File Not Found

```json
{
  "error": {
    "type": "file-not-found",
    "message": "Input file does not exist: data.log",
    "exitCode": 1,
    "stderr": "awk: can't open file data.log",
    "solution": "Verify file path and ensure file exists"
  }
}
```

### Timeout Exceeded

```json
{
  "error": {
    "type": "timeout",
    "message": "AWK execution exceeded timeout of 60s",
    "exitCode": 124,
    "metadata": {
      "timeout": 60,
      "inputFileSize": "2.5GB"
    },
    "solution": "Increase timeout or optimize AWK script for large files"
  }
}
```

## Platform Considerations

### macOS vs Linux Differences

| Feature | macOS awk | GNU awk (gawk) |
|---------|-----------|----------------|
| `\s` regex | Not supported | Supported |
| `gensub()` | Not available | Available |
| `BEGINFILE` | Not available | Available |
| `strftime()` | Not available | Available |
| Performance | Slower on large files | Optimized |

### Portability Tips

For cross-platform scripts:
- Use `variant: "awk"` and avoid GNU extensions
- Test regex patterns on both platforms
- Use explicit character classes (`[[:space:]]` vs `\s`)
- Avoid GNU-specific functions

## Performance Optimization

### Large File Processing

For files > 100MB:
- Set higher timeout (5-10 minutes)
- Consider preprocessing with `grep` to filter
- Use `NR` limits to process subsets
- Monitor memory usage

### Example: Process First Million Lines

```json
{
  "action": "execute",
  "mode": "one-liner",
  "script": "NR <= 1000000 { process... }",
  "inputFiles": ["huge.log"],
  "timeout": 300
}
```

### Pipeline Optimization

Order matters for performance:
1. **grep** - Filter early to reduce data
2. **sort** - Sort if needed for AWK logic
3. **awk** - Main processing
4. **uniq/sort** - Final aggregation

```json
{
  "action": "execute",
  "mode": "one-liner",
  "script": "{ count[$2]++ } END { for (k in count) print k, count[k] }",
  "inputFiles": ["app.log"],
  "options": {
    "preProcess": "grep ERROR",
    "postProcess": "sort -k2 -nr | head -20"
  }
}
```
