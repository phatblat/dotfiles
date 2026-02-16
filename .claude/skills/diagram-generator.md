# Diagram Generator

Generate, validate, and render diagrams using Mermaid, PlantUML, GraphViz, and other diagram-as-code tools.

## Capability

This skill generates diagram syntax, validates correctness, and renders diagrams to various output formats (SVG, PNG, PDF). It returns structured results with generated syntax, validation status, and rendered artifacts.

## Supported Diagram Tools

### Mermaid
- **Flowcharts** - Process flows and decision trees
- **Sequence Diagrams** - Interaction sequences
- **Class Diagrams** - Object-oriented structures
- **State Diagrams** - State machines
- **Entity Relationship** - Database schemas
- **User Journey** - User experience flows
- **Gantt Charts** - Project timelines
- **Pie Charts** - Data visualization
- **Git Graphs** - Version control flows
- **C4 Diagrams** - Architecture diagrams
- **Mindmaps** - Hierarchical structures
- **Timeline** - Chronological events

### PlantUML
- **Class Diagrams** - UML class structures
- **Sequence Diagrams** - Message flows
- **Use Case Diagrams** - System interactions
- **Activity Diagrams** - Workflows
- **Component Diagrams** - System components
- **Deployment Diagrams** - Infrastructure
- **State Diagrams** - State machines
- **Object Diagrams** - Object instances

### GraphViz (DOT)
- **Directed Graphs** - Hierarchical structures
- **Undirected Graphs** - Network relationships
- **Flow Graphs** - Control flow
- **Dependency Graphs** - Package dependencies

### D2
- **Architecture Diagrams** - System architecture
- **Network Diagrams** - Infrastructure
- **Flowcharts** - Process flows

## Usage Protocol

Agents invoke this skill by specifying diagram parameters:

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "flowchart",
  "syntax": "graph TD\n  A[Start] --> B{Decision}\n  B -->|Yes| C[Process]\n  B -->|No| D[End]\n  C --> D",
  "outputFormat": "svg",
  "validate": true,
  "render": true
}
```

### Parameters

- **action** (required): `"generate"`, `"validate"`, or `"render"`
- **tool** (required): `"mermaid"`, `"plantuml"`, `"graphviz"`, or `"d2"`
- **diagramType** (required): Specific diagram type for the tool
- **syntax** (required): Diagram source code
- **outputFormat** (optional): `"svg"`, `"png"`, `"pdf"` (default: "svg")
- **validate** (optional): Validate syntax before rendering (default: true)
- **render** (optional): Render to output format (default: true)
- **theme** (optional): Diagram theme/style
- **outputPath** (optional): Where to save rendered diagram

## Diagram Configurations

### Mermaid Flowchart

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "flowchart",
  "syntax": "graph TD\n  Start[Start Process] --> Auth{Authentication}\n  Auth -->|Success| Dashboard[Show Dashboard]\n  Auth -->|Failure| Error[Show Error]\n  Dashboard --> End[End]\n  Error --> End",
  "outputFormat": "svg",
  "theme": "default",
  "outputPath": "diagrams/auth-flow.svg"
}
```

### Mermaid Sequence Diagram

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "sequence",
  "syntax": "sequenceDiagram\n  participant U as User\n  participant A as API\n  participant D as Database\n  U->>A: POST /login\n  A->>D: Query user\n  D-->>A: User data\n  A-->>U: JWT token",
  "outputFormat": "png",
  "theme": "dark"
}
```

### Mermaid Class Diagram

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "class",
  "syntax": "classDiagram\n  class Animal {\n    +String name\n    +int age\n    +makeSound()\n  }\n  class Dog {\n    +String breed\n    +bark()\n  }\n  Animal <|-- Dog",
  "outputFormat": "svg"
}
```

### Mermaid Entity Relationship Diagram

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "er",
  "syntax": "erDiagram\n  CUSTOMER ||--o{ ORDER : places\n  ORDER ||--|{ LINE-ITEM : contains\n  CUSTOMER {\n    string name\n    string email\n  }\n  ORDER {\n    int orderNumber\n    date orderDate\n  }",
  "outputFormat": "svg"
}
```

### PlantUML Class Diagram

```json
{
  "action": "generate",
  "tool": "plantuml",
  "diagramType": "class",
  "syntax": "@startuml\nclass Vehicle {\n  -String model\n  +start()\n  +stop()\n}\nclass Car extends Vehicle {\n  -int doors\n}\nclass Motorcycle extends Vehicle {\n  -boolean hasSidecar\n}\n@enduml",
  "outputFormat": "png"
}
```

### PlantUML Sequence Diagram

```json
{
  "action": "generate",
  "tool": "plantuml",
  "diagramType": "sequence",
  "syntax": "@startuml\nactor User\nparticipant \"Web Server\" as WS\ndatabase \"Database\" as DB\nUser -> WS: HTTP Request\nWS -> DB: SQL Query\nDB --> WS: Result Set\nWS --> User: HTTP Response\n@enduml",
  "outputFormat": "svg"
}
```

### GraphViz Directed Graph

```json
{
  "action": "generate",
  "tool": "graphviz",
  "diagramType": "digraph",
  "syntax": "digraph G {\n  rankdir=TB;\n  node [shape=box];\n  A -> B;\n  A -> C;\n  B -> D;\n  C -> D;\n}",
  "outputFormat": "svg"
}
```

### D2 Architecture Diagram

```json
{
  "action": "generate",
  "tool": "d2",
  "diagramType": "architecture",
  "syntax": "users: Users {\n  shape: person\n}\napi: API Server {\n  shape: rectangle\n}\ndb: Database {\n  shape: cylinder\n}\nusers -> api: HTTPS\napi -> db: SQL",
  "outputFormat": "svg"
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "tool": "mermaid",
    "diagramType": "flowchart",
    "action": "generate",
    "validation": {
      "valid": true,
      "errors": [],
      "warnings": []
    },
    "rendering": {
      "success": true,
      "outputFormat": "svg",
      "outputPath": "diagrams/auth-flow.svg",
      "fileSize": "12.3KB"
    },
    "syntax": "graph TD\n  Start[Start Process] --> Auth{Authentication}\n  ...",
    "duration": "1.2s",
    "status": "success"
  }
}
```

### Successful Generation and Rendering

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "tool": "mermaid",
    "diagramType": "sequence",
    "action": "generate",
    "validation": {
      "valid": true,
      "syntaxVersion": "10.6.1",
      "nodeCount": 4,
      "edgeCount": 4,
      "errors": [],
      "warnings": []
    },
    "rendering": {
      "success": true,
      "outputFormat": "svg",
      "outputPath": "diagrams/sequence.svg",
      "fileSize": "15.7KB",
      "dimensions": {"width": 800, "height": 600},
      "renderTime": "0.8s"
    },
    "syntax": "sequenceDiagram\n  participant U as User\n  ...",
    "duration": "1.2s",
    "status": "success"
  }
}
```

### Validation Only (No Rendering)

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:31:00Z",
    "tool": "plantuml",
    "diagramType": "class",
    "action": "validate",
    "validation": {
      "valid": true,
      "syntaxVersion": "1.2023.13",
      "classCount": 5,
      "relationshipCount": 4,
      "errors": [],
      "warnings": [
        {
          "line": 12,
          "message": "Consider using composition instead of aggregation",
          "severity": "info"
        }
      ]
    },
    "rendering": {
      "success": false,
      "reason": "Rendering disabled (validate only)"
    },
    "syntax": "@startuml\nclass Vehicle...",
    "duration": "0.3s",
    "status": "success"
  }
}
```

### Syntax Error

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:32:00Z",
    "tool": "mermaid",
    "diagramType": "flowchart",
    "action": "generate",
    "validation": {
      "valid": false,
      "errors": [
        {
          "line": 3,
          "column": 15,
          "message": "Unexpected token: expected '-->' or '---' but found '==>'",
          "code": "SYNTAX_ERROR"
        }
      ],
      "warnings": []
    },
    "rendering": {
      "success": false,
      "reason": "Validation failed"
    },
    "syntax": "graph TD\n  A --> B\n  B ==> C",
    "duration": "0.2s",
    "status": "validation_failed"
  }
}
```

## Validation Features

### Mermaid Validation
- Syntax correctness (keywords, operators, structure)
- Node ID uniqueness and consistency
- Valid edge definitions
- Proper diagram type syntax
- Theme compatibility
- Version compatibility

### PlantUML Validation
- Valid @startuml/@enduml blocks
- Correct participant/class definitions
- Valid relationship syntax
- Proper arrow notation
- Stereotype usage

### GraphViz Validation
- Valid DOT syntax
- Node and edge definitions
- Attribute syntax
- Subgraph structure
- Rank constraints

## Rendering Options

### Output Formats

**SVG** (default):
- Scalable vector graphics
- Best for web embedding
- Editable in design tools
- Smallest file size for simple diagrams

**PNG**:
- Raster image format
- Good for documentation
- Configurable resolution (DPI)
- Universal compatibility

**PDF**:
- Print-ready format
- Vector graphics with text
- Best for documentation
- Archival quality

### Themes

**Mermaid Themes**:
- `default` - Standard theme
- `dark` - Dark mode
- `forest` - Green tones
- `neutral` - Gray tones
- `base` - Minimal styling

**Custom Styling**:
```json
{
  "theme": "custom",
  "themeVariables": {
    "primaryColor": "#ff6b6b",
    "primaryTextColor": "#fff",
    "primaryBorderColor": "#ff6b6b",
    "lineColor": "#333",
    "fontSize": "16px"
  }
}
```

## Advanced Features

### Multi-Diagram Batch Processing

```json
{
  "action": "generate",
  "batch": true,
  "diagrams": [
    {
      "tool": "mermaid",
      "diagramType": "flowchart",
      "syntax": "graph TD...",
      "outputPath": "diagrams/flow1.svg"
    },
    {
      "tool": "mermaid",
      "diagramType": "sequence",
      "syntax": "sequenceDiagram...",
      "outputPath": "diagrams/seq1.svg"
    }
  ]
}
```

### Diagram Optimization

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "flowchart",
  "syntax": "graph TD...",
  "optimize": {
    "simplifyPaths": true,
    "removeOrphans": true,
    "consolidateDuplicates": true
  }
}
```

### Export Metadata

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "class",
  "syntax": "classDiagram...",
  "exportMetadata": true
}
```

Returns additional metadata:
```json
{
  "metadata": {
    "classes": ["Animal", "Dog", "Cat"],
    "relationships": [
      {"type": "inheritance", "from": "Dog", "to": "Animal"},
      {"type": "inheritance", "from": "Cat", "to": "Animal"}
    ],
    "methods": ["makeSound", "bark", "meow"],
    "properties": ["name", "age", "breed"]
  }
}
```

## Tool Requirements

### Mermaid
- **mermaid-cli** (mmdc): `npm install -g @mermaid-js/mermaid-cli`
- Or use Puppeteer-based rendering
- Supports headless browser rendering

### PlantUML
- **plantuml.jar**: Download from plantuml.com
- Requires Java Runtime Environment (JRE 8+)
- Or use online PlantUML server

### GraphViz
- **dot**: `brew install graphviz` (macOS) / `apt install graphviz` (Linux)
- Pre-installed on most Linux distributions

### D2
- **d2**: `brew install d2` (macOS) / Download from d2lang.com
- Modern architecture diagramming tool

## Constraints

This skill does NOT:
- Analyze code or requirements to determine diagram content
- Choose diagram types or design diagram structure
- Make layout or styling decisions beyond provided configuration
- Interpret business logic or system architecture
- Generate diagram syntax from descriptions (calling agent provides syntax)
- Recommend diagram improvements or alternatives
- Explain diagram concepts or UML principles
- Auto-generate diagrams from source code
- Perform semantic analysis of diagrams

## Error Handling

Returns structured error information for:

- **Syntax errors**: Invalid diagram syntax
- **Tool not found**: Mermaid/PlantUML/GraphViz not installed
- **Rendering errors**: Failed to generate output image
- **Invalid diagram type**: Unsupported diagram type for tool
- **File write errors**: Cannot write to output path
- **Version incompatibility**: Diagram syntax requires newer tool version

Example error response:

```json
{
  "error": {
    "type": "syntax-error",
    "tool": "mermaid",
    "diagramType": "flowchart",
    "message": "Invalid flowchart syntax at line 3",
    "line": 3,
    "column": 12,
    "excerpt": "  B ==> C",
    "details": "Expected '-->' or '---' but found '==>'",
    "suggestion": "Change '==>' to '-->' for standard arrow or '===' for thick arrow",
    "documentation": "https://mermaid.js.org/syntax/flowchart.html#links"
  }
}
```

### Tool Not Installed

```json
{
  "error": {
    "type": "tool-not-found",
    "tool": "plantuml",
    "message": "PlantUML is not installed or not in PATH",
    "solution": "Install PlantUML: Download plantuml.jar from https://plantuml.com or use package manager",
    "requiredCommands": ["java", "plantuml.jar"]
  }
}
```

### Rendering Failed

```json
{
  "error": {
    "type": "rendering-error",
    "tool": "mermaid",
    "diagramType": "sequence",
    "message": "Failed to render diagram to SVG",
    "exitCode": 1,
    "stderr": "Error: Chromium not found. Install with: npx puppeteer install",
    "solution": "Install Puppeteer's Chromium: npx puppeteer install"
  }
}
```

### Invalid Output Format

```json
{
  "error": {
    "type": "invalid-format",
    "tool": "d2",
    "requestedFormat": "gif",
    "supportedFormats": ["svg", "png", "pdf"],
    "message": "Output format 'gif' is not supported by D2",
    "solution": "Use one of the supported formats: svg, png, pdf"
  }
}
```

## Performance Considerations

### Rendering Time
- Simple diagrams: < 1 second
- Complex diagrams (100+ nodes): 2-5 seconds
- Large diagrams (500+ nodes): 10-30 seconds

### Memory Usage
- Mermaid (Puppeteer): 100-500MB
- PlantUML: 200-800MB (Java heap)
- GraphViz: 50-200MB

### Optimization Tips
- Use SVG for smaller file sizes
- Batch process multiple diagrams
- Cache rendered outputs when possible
- Simplify complex diagrams for faster rendering

## Common Diagram Workflows

### Generate and Validate Flowchart

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "flowchart",
  "syntax": "graph TD\n  Start --> Process\n  Process --> Decision{OK?}\n  Decision -->|Yes| End\n  Decision -->|No| Process",
  "validate": true,
  "render": true,
  "outputFormat": "svg",
  "outputPath": "docs/process-flow.svg"
}
```

### Validate PlantUML Without Rendering

```json
{
  "action": "validate",
  "tool": "plantuml",
  "diagramType": "class",
  "syntax": "@startuml\nclass User\nclass Admin extends User\n@enduml"
}
```

### Render Multiple Themes

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "sequence",
  "syntax": "sequenceDiagram...",
  "batch": true,
  "variants": [
    {"theme": "default", "outputPath": "diagrams/seq-light.svg"},
    {"theme": "dark", "outputPath": "diagrams/seq-dark.svg"}
  ]
}
```

### Export High-Resolution PNG

```json
{
  "action": "generate",
  "tool": "mermaid",
  "diagramType": "class",
  "syntax": "classDiagram...",
  "outputFormat": "png",
  "renderOptions": {
    "width": 2400,
    "height": 1800,
    "scale": 3
  },
  "outputPath": "diagrams/class-diagram-hi-res.png"
}
```
