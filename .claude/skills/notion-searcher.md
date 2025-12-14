# Notion Searcher Skill

Search and retrieve information from Notion workspaces, pages, and databases.

## Capability

Searches Notion workspace to find:
- Pages by title, content, or tags
- Database entries matching criteria
- Meeting notes and documentation
- Project information and planning documents
- Knowledge base content
- Teams, processes, and reference materials

Returns matched pages and database entries with content, metadata, and hierarchy information.

## How to Use This Skill

### Input
```
{
  "action": "search",
  "query": "Q4 planning",                          // What to search for
  "searchIn": "all|pages|databases|title|tags",   // Where to search
  "filters": {
    "workspace": "Engineering",                   // Optional: workspace name
    "database": "Projects",                       // Optional: database name
    "tag": "important",                           // Optional: filter by tags
    "status": "In Progress"                       // Optional: property value
  },
  "limit": 10,                                    // Max results
  "includeContent": true                          // Return page content
}
```

### Output

Returns search results document:
```
{
  "status": "success",  // success|error|not-found
  "query": "Q4 planning",
  "resultsFound": 2,
  "results": [
    {
      "id": "abc123def456",
      "title": "Q4 Planning Document",
      "type": "page",
      "url": "https://www.notion.so/Q4-Planning-abc123def456",
      "lastModified": "2025-12-14T10:30:00Z",
      "properties": {
        "status": "In Progress",
        "owner": "engineering-team",
        "tags": ["planning", "q4", "important"]
      },
      "hierarchy": {
        "parent": "2025 Planning",
        "children": ["Engineering Goals", "Timeline", "Milestones"]
      },
      "contentPreview": "# Q4 Planning\n\nThis document outlines our Q4 objectives...",
      "hasContent": true
    },
    {
      "id": "xyz789uvw012",
      "title": "Q4 Schedule",
      "type": "database_entry",
      "databaseName": "Projects",
      "url": "https://www.notion.so/xyz789uvw012",
      "properties": {
        "name": "Q4 Schedule",
        "dueDate": "2025-12-31",
        "status": "In Progress",
        "owner": "alice@example.com"
      }
    }
  ],
  "pagination": {
    "total": 5,
    "returned": 2,
    "hasMore": true
  },
  "searchTime": "0.3s"
}
```

## Search Types

### all
Search across all Notion content (pages, databases, content)

### pages
Search standalone pages only

### databases
Search database entries and database pages

### title
Search by page/database name only

### tags
Search pages with specific tags

### content
Full-text search across page content (slower but comprehensive)

## Protocol

1. **Receive search query** and optional filters
2. **Query Notion API** using MCP server
3. **Retrieve matching pages/entries** with metadata
4. **Get hierarchy information** (parents, children)
5. **Return structured results** with content previews
6. **Do NOT modify** pages (agent's responsibility)

## Constraints

This skill **does not**:
- Create new pages or databases
- Modify existing page content
- Update page properties or metadata
- Delete pages or entries
- Change workspace settings
- Configure databases
- Move or archive pages
- Generate reports from data

_Agent responsibility: interpreting results, creating/updating content when explicitly requested_

## Example Invocations

### Search for Meeting Notes
```
[invoke notion-searcher]
input: {
  "action": "search",
  "query": "SDK team meeting",
  "searchIn": "pages",
  "includeContent": true
}

Output:
{
  "status": "success",
  "resultsFound": 2,
  "results": [
    {
      "id": "meeting-12-10",
      "title": "SDK Team Meeting - Dec 10",
      "contentPreview": "Topics: FFI improvements, API design decisions...",
      "lastModified": "2025-12-10T14:00:00Z",
      "url": "https://www.notion.so/meeting-12-10"
    }
  ]
}
```

### Search Database by Tag
```
[invoke notion-searcher]
input: {
  "action": "search",
  "query": "important",
  "searchIn": "tags",
  "filters": {
    "database": "Projects"
  }
}

Output:
{
  "status": "success",
  "resultsFound": 8,
  "results": [...]
}
```

### Find Project Documentation
```
[invoke notion-searcher]
input: {
  "action": "search",
  "query": "API documentation",
  "searchIn": "pages",
  "filters": {
    "workspace": "Engineering",
    "tag": "api"
  },
  "includeContent": true,
  "limit": 5
}

Output:
{
  "status": "success",
  "resultsFound": 3,
  "results": [
    {
      "title": "REST API Reference",
      "type": "page",
      "contentPreview": "## Endpoints\n\n### GET /api/users...",
      "hierarchy": {
        "parent": "API Documentation",
        "children": ["Authentication", "Rate Limits"]
      }
    }
  ]
}
```

## Error Cases

| Scenario | Response |
|----------|----------|
| No results found | `"No pages found matching: [query]. Try alternative terms or broader search."` |
| Invalid search type | `"Unknown search type: [type]. Supported: all, pages, databases, title, tags, content"` |
| Workspace not found | `"Workspace '[name]' not found. Check workspace name and permissions."` |
| Database not found | `"Database '[name]' not found in workspace."` |
| Access denied | `"You do not have permission to access this workspace or page."` |
| Notion API unavailable | `"Notion service unavailable. Try again later."` |

## Content Structure

Returned pages can include:

- **Page Properties**: Title, status, tags, custom fields
- **Hierarchy**: Parent page, child pages, page relationships
- **Content Preview**: Excerpt of page markdown/text
- **Metadata**: Last modified, created date, owner
- **Database Info**: Database name, entry type, properties

## Integration Notes

- **Used by agents**: notion-expert, tech-writer, project-planner
- **Returns structured data**: Pages/databases with metadata and content
- **Always fresh**: Never caches results - always queries current data
- **Hierarchy-aware**: Understands page structure and relationships
- **Tag-aware**: Can filter and search by tags
- **Content-aware**: Can search page content (optional, slower)
- **No modification**: Read-only skill - never modifies workspace
- **Permission-aware**: Respects workspace and page access controls
