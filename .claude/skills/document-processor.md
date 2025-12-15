# Document Processor

Execute document processing operations including LaTeX compilation, BibTeX processing, and format conversion.

## Capability

This skill executes document processing commands for LaTeX compilation, bibliography generation, and format conversion between PDF, PostScript, Markdown, HTML, and other formats. It returns structured results with compilation output, errors, and generated artifacts.

## Supported Operations

### LaTeX Compilation
- **pdflatex** - Compile LaTeX to PDF
- **xelatex** - Compile with XeTeX (Unicode support)
- **lualatex** - Compile with LuaTeX
- **latex** - Compile to DVI

### Bibliography Processing
- **bibtex** - Process BibTeX bibliographies
- **biber** - Modern bibliography processor (for biblatex)

### Document Conversion
- **pandoc** - Universal document converter
- **ps2pdf** - PostScript to PDF
- **pdf2ps** - PDF to PostScript
- **pdftotext** - Extract text from PDF
- **pdftk** - PDF manipulation (merge, split, rotate)

### Document Utilities
- **texcount** - Count words in LaTeX documents
- **chktex** - LaTeX syntax checker
- **lacheck** - LaTeX error checker

## Usage Protocol

Agents invoke this skill by specifying operation parameters:

```json
{
  "action": "compile",
  "engine": "pdflatex",
  "document": "paper.tex",
  "workingDir": "/path/to/project",
  "outputFormat": "pdf",
  "passes": 2
}
```

### Parameters

- **action** (required): Operation to execute
- **engine** (required): Compilation engine or tool
- **document** (required): Input document file
- **workingDir** (optional): Working directory (default: current)
- **outputFormat** (optional): Output format (default: pdf)
- **passes** (optional): Number of compilation passes (default: 1)
- **timeout** (optional): Timeout in seconds (default: 120s)

## LaTeX Compilation

### Compile PDF with pdflatex

```json
{
  "action": "compile",
  "engine": "pdflatex",
  "document": "paper.tex",
  "workingDir": "latex-project/",
  "passes": 1,
  "options": {
    "interaction": "nonstopmode",
    "outputDirectory": "build/",
    "synctex": true
  }
}
```

### Compile with Bibliography (Full Workflow)

```json
{
  "action": "compile-with-bib",
  "engine": "pdflatex",
  "bibEngine": "bibtex",
  "document": "paper.tex",
  "bibliography": "references.bib",
  "workingDir": "latex-project/",
  "citationStyle": "ieee"
}
```

This executes:
1. pdflatex (first pass)
2. bibtex (process bibliography)
3. pdflatex (second pass)
4. pdflatex (third pass)

### XeLaTeX Compilation (Unicode Support)

```json
{
  "action": "compile",
  "engine": "xelatex",
  "document": "paper.tex",
  "workingDir": "latex-project/",
  "options": {
    "interaction": "nonstopmode",
    "outputDirectory": "build/"
  }
}
```

### LuaLaTeX Compilation

```json
{
  "action": "compile",
  "engine": "lualatex",
  "document": "thesis.tex",
  "workingDir": "thesis/",
  "passes": 2
}
```

## BibTeX Processing

### Process BibTeX Bibliography

```json
{
  "action": "process-bib",
  "engine": "bibtex",
  "document": "paper",
  "workingDir": "latex-project/"
}
```

### Process with Biber (biblatex)

```json
{
  "action": "process-bib",
  "engine": "biber",
  "document": "paper",
  "workingDir": "latex-project/",
  "options": {
    "debug": false
  }
}
```

### Validate BibTeX File

```json
{
  "action": "validate-bib",
  "bibliography": "references.bib",
  "workingDir": "latex-project/"
}
```

## Document Conversion

### PDF to Text

```json
{
  "action": "convert",
  "engine": "pdftotext",
  "input": "paper.pdf",
  "output": "paper.txt",
  "options": {
    "layout": true,
    "encoding": "UTF-8"
  }
}
```

### PostScript to PDF

```json
{
  "action": "convert",
  "engine": "ps2pdf",
  "input": "document.ps",
  "output": "document.pdf"
}
```

### Pandoc Conversions

#### LaTeX to Markdown

```json
{
  "action": "convert",
  "engine": "pandoc",
  "input": "paper.tex",
  "output": "paper.md",
  "inputFormat": "latex",
  "outputFormat": "markdown",
  "options": {
    "standalone": true,
    "extractMedia": "media/"
  }
}
```

#### Markdown to PDF

```json
{
  "action": "convert",
  "engine": "pandoc",
  "input": "README.md",
  "output": "README.pdf",
  "inputFormat": "markdown",
  "outputFormat": "pdf",
  "options": {
    "pdfEngine": "xelatex",
    "template": "eisvogel"
  }
}
```

#### LaTeX to HTML

```json
{
  "action": "convert",
  "engine": "pandoc",
  "input": "paper.tex",
  "output": "paper.html",
  "inputFormat": "latex",
  "outputFormat": "html",
  "options": {
    "standalone": true,
    "mathJax": true,
    "css": "style.css"
  }
}
```

#### DOCX to LaTeX

```json
{
  "action": "convert",
  "engine": "pandoc",
  "input": "manuscript.docx",
  "output": "manuscript.tex",
  "inputFormat": "docx",
  "outputFormat": "latex"
}
```

## Document Utilities

### Word Count (texcount)

```json
{
  "action": "wordcount",
  "document": "paper.tex",
  "workingDir": "latex-project/",
  "options": {
    "includeBibliography": false,
    "includeHeaders": true
  }
}
```

### LaTeX Syntax Check

```json
{
  "action": "check-syntax",
  "engine": "chktex",
  "document": "paper.tex",
  "workingDir": "latex-project/"
}
```

### PDF Manipulation

#### Merge PDFs

```json
{
  "action": "pdf-merge",
  "inputs": ["part1.pdf", "part2.pdf", "part3.pdf"],
  "output": "combined.pdf"
}
```

#### Split PDF

```json
{
  "action": "pdf-split",
  "input": "document.pdf",
  "pages": "1-10",
  "output": "excerpt.pdf"
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "compile",
    "engine": "pdflatex",
    "document": "paper.tex",
    "exitCode": 0,
    "duration": "3.2s",
    "status": "success",
    "artifacts": {
      "pdf": "build/paper.pdf",
      "log": "build/paper.log",
      "aux": "build/paper.aux"
    },
    "metadata": {
      "pages": 12,
      "warnings": 3,
      "errors": 0,
      "fileSize": "245KB"
    }
  }
}
```

### Successful LaTeX Compilation

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "action": "compile",
    "engine": "pdflatex",
    "document": "paper.tex",
    "workingDir": "latex-project/",
    "exitCode": 0,
    "duration": "3.2s",
    "status": "success",
    "stdout": "This is pdfTeX, Version 3.141592653...",
    "artifacts": {
      "pdf": "build/paper.pdf",
      "log": "build/paper.log",
      "aux": "build/paper.aux",
      "synctex": "build/paper.synctex.gz"
    },
    "metadata": {
      "pages": 12,
      "warnings": 3,
      "errors": 0,
      "overfullBoxes": 2,
      "underfullBoxes": 1,
      "fileSize": "245KB",
      "compilationPasses": 1
    }
  }
}
```

### Full Compilation with Bibliography

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:31:00Z",
    "action": "compile-with-bib",
    "engine": "pdflatex",
    "bibEngine": "bibtex",
    "document": "paper.tex",
    "exitCode": 0,
    "duration": "9.8s",
    "status": "success",
    "artifacts": {
      "pdf": "paper.pdf",
      "log": "paper.log",
      "aux": "paper.aux",
      "bbl": "paper.bbl",
      "blg": "paper.blg"
    },
    "metadata": {
      "pages": 15,
      "citations": 42,
      "bibliographyEntries": 38,
      "warnings": 5,
      "errors": 0,
      "fileSize": "312KB",
      "passes": {
        "pdflatex1": "success",
        "bibtex": "success",
        "pdflatex2": "success",
        "pdflatex3": "success"
      }
    }
  }
}
```

### Document Conversion Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:32:00Z",
    "action": "convert",
    "engine": "pandoc",
    "input": "paper.tex",
    "output": "paper.md",
    "inputFormat": "latex",
    "outputFormat": "markdown",
    "exitCode": 0,
    "duration": "1.5s",
    "status": "success",
    "artifacts": {
      "output": "paper.md",
      "media": "media/"
    },
    "metadata": {
      "inputSize": "45KB",
      "outputSize": "38KB",
      "imagesExtracted": 5
    }
  }
}
```

### Word Count Result

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:33:00Z",
    "action": "wordcount",
    "document": "paper.tex",
    "exitCode": 0,
    "duration": "0.3s",
    "status": "success",
    "metadata": {
      "wordsInText": 4523,
      "wordsInHeaders": 89,
      "wordsInCaptions": 156,
      "totalWords": 4768,
      "mathInlines": 234,
      "mathDisplays": 67,
      "floats": 12,
      "tables": 3,
      "figures": 9
    }
  }
}
```

## Compilation Errors

### LaTeX Compilation Error

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:34:00Z",
    "action": "compile",
    "engine": "pdflatex",
    "document": "paper.tex",
    "exitCode": 1,
    "duration": "1.2s",
    "status": "failed",
    "errors": [
      {
        "line": 45,
        "file": "paper.tex",
        "message": "Undefined control sequence \\mycustomcommand",
        "type": "error",
        "context": "...some text before \\mycustomcommand{arg} text after..."
      },
      {
        "line": 78,
        "file": "paper.tex",
        "message": "Missing $ inserted",
        "type": "error",
        "context": "The equation x^2 + y^2 should be in math mode"
      }
    ],
    "warnings": [
      {
        "line": 23,
        "message": "Overfull \\hbox (12.34pt too wide)",
        "type": "warning"
      }
    ]
  }
}
```

### BibTeX Error

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:35:00Z",
    "action": "process-bib",
    "engine": "bibtex",
    "document": "paper",
    "exitCode": 1,
    "duration": "0.5s",
    "status": "failed",
    "errors": [
      {
        "line": 156,
        "file": "references.bib",
        "message": "I was expecting a `,' or a `}'",
        "entry": "smith2023",
        "field": "author"
      }
    ]
  }
}
```

## Error Handling

Returns structured error information for:

- **LaTeX errors**: Undefined commands, missing packages, syntax errors
- **BibTeX errors**: Malformed entries, missing fields, duplicate keys
- **File errors**: Missing input files, permission issues
- **Conversion errors**: Unsupported formats, invalid input
- **Missing tools**: LaTeX distribution not installed

Example error response:

```json
{
  "error": {
    "type": "latex-error",
    "engine": "pdflatex",
    "document": "paper.tex",
    "message": "Undefined control sequence \\mycustomcommand",
    "line": 45,
    "file": "paper.tex",
    "context": "\\mycustomcommand{argument}",
    "solution": "Define the command with \\newcommand{\\mycustomcommand}[1]{...} or check for typos"
  }
}
```

### Missing Package

```json
{
  "error": {
    "type": "missing-package",
    "engine": "pdflatex",
    "document": "paper.tex",
    "message": "File `algorithm.sty' not found",
    "package": "algorithm",
    "solution": "Install package: tlmgr install algorithms (TeX Live) or mpm --install=algorithms (MiKTeX)"
  }
}
```

### Tool Not Found

```json
{
  "error": {
    "type": "tool-not-found",
    "tool": "pdflatex",
    "message": "pdflatex command not found",
    "exitCode": 127,
    "solution": "Install TeX distribution: apt install texlive-full (Ubuntu) or brew install --cask mactex (macOS)"
  }
}
```

### Conversion Not Supported

```json
{
  "error": {
    "type": "unsupported-conversion",
    "engine": "pandoc",
    "inputFormat": "xyz",
    "outputFormat": "pdf",
    "message": "Unknown reader: xyz",
    "solution": "Supported input formats: markdown, latex, html, docx, epub, rst. See: pandoc --list-input-formats"
  }
}
```

## LaTeX Distribution Support

### TeX Live (Linux/macOS)
- Full distribution: `texlive-full`
- Basic distribution: `texlive-base`
- Package manager: `tlmgr`

### MiKTeX (Windows/macOS/Linux)
- Auto-install missing packages
- Package manager: `mpm`

### MacTeX (macOS)
- Full TeX Live distribution for Mac
- Includes GUI tools (TeXShop, BibDesk)

## Tool Requirements

### Core Tools
- **pdflatex**: TeX Live, MiKTeX, MacTeX
- **bibtex**: Included with LaTeX distributions
- **pandoc**: `brew install pandoc` / `apt install pandoc`

### Optional Tools
- **xelatex**: TeX Live, MiKTeX
- **lualatex**: TeX Live, MiKTeX
- **biber**: `tlmgr install biber` / `mpm --install=biber`
- **chktex**: `tlmgr install chktex`
- **texcount**: Included in TeX Live
- **pdftk**: `brew install pdftk-java` / `apt install pdftk`
- **poppler-utils**: For pdftotext (`apt install poppler-utils`)

## Constraints

This skill does NOT:
- Review academic papers for quality or rigor
- Evaluate evidence or methodology
- Check citation accuracy or relevance
- Write LaTeX content or BibTeX entries
- Design document layouts or templates
- Make editorial decisions about content
- Verify mathematical correctness
- Assess research contributions
- Format according to journal requirements (just executes compilation)
- Search academic databases for papers

## Common LaTeX Workflows

### Compile Simple Document

```json
{
  "action": "compile",
  "engine": "pdflatex",
  "document": "article.tex",
  "passes": 1
}
```

### Full Compilation with References

```json
{
  "action": "compile-with-bib",
  "engine": "pdflatex",
  "bibEngine": "bibtex",
  "document": "paper.tex",
  "bibliography": "references.bib"
}
```

### Convert LaTeX to Markdown

```json
{
  "action": "convert",
  "engine": "pandoc",
  "input": "paper.tex",
  "output": "paper.md",
  "inputFormat": "latex",
  "outputFormat": "markdown"
}
```

### Extract Text from PDF

```json
{
  "action": "convert",
  "engine": "pdftotext",
  "input": "paper.pdf",
  "output": "paper.txt",
  "options": {
    "layout": true
  }
}
```

### Count Words in LaTeX Document

```json
{
  "action": "wordcount",
  "document": "thesis.tex",
  "options": {
    "includeHeaders": true,
    "includeBibliography": false
  }
}
```

### Check LaTeX Syntax

```json
{
  "action": "check-syntax",
  "engine": "chktex",
  "document": "paper.tex"
}
```
