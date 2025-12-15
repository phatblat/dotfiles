# Linear Searcher Skill

Search and retrieve Linear issues with related resources and cross-platform relationships.

## Capability

Searches Linear project management system to find:
- Issues by various criteria (status, assignee, labels, projects, cycles)
- Issue relationships (parent/child, dependencies, links)
- Associated pull requests and commits
- Linked external resources (Zendesk tickets, logs, error reports)
- Project progress across sprints and milestones

Returns matched issues with metadata, statuses, and associated resources.

## How to Use This Skill

### Input
```
{
  "action": "search",
  "query": "authentication feature",                    // Search term or issue ID
  "searchBy": "content|assignee|label|status|cycle",   // Search category
  "filters": {
    "status": "In Progress",                            // Optional: issue state
    "assignee": "user@example.com",                     // Optional: assigned user
    "label": "bug|feature|enhancement",                 // Optional: labels
    "project": "SDK",                                   // Optional: project name
    "cycle": "Current",                                 // Optional: sprint/cycle
    "team": "Engineering"                               // Optional: team name
  },
  "includeLinks": true,                                 // Include linked resources
  "limit": 10                                           // Max results (default: 10)
}
```

### Output

Returns search results document:
```
{
  "status": "success",  // success|error|not-found
  "query": "authentication feature",
  "resultsFound": 3,
  "results": [
    {
      "id": "ENG-1234",
      "title": "Implement user authentication flow",
      "description": "Add OAuth2 support for all platforms",
      "state": "In Progress",
      "assignee": "alice@example.com",
      "priority": "High",
      "project": "SDK",
      "cycle": "Q4 Sprint 2",
      "labels": ["feature", "authentication", "priority-high"],
      "createdAt": "2025-12-01T10:00:00Z",
      "updatedAt": "2025-12-14T15:30:00Z",
      "linkedResources": {
        "pullRequests": [
          {
            "id": "getditto/ditto#5234",
            "title": "Add OAuth2 implementation",
            "url": "https://github.com/getditto/ditto/pull/5234",
            "status": "open"
          }
        ],
        "zendesk": [
          {
            "id": "ZEN-4567",
            "title": "Customer needs OAuth support",
            "url": "https://zendesk.getditto.com/tickets/4567"
          }
        ],
        "parentIssue": "ENG-1100",
        "childIssues": ["ENG-1235", "ENG-1236"]
      },
      "url": "https://linear.app/getditto/issue/ENG-1234"
    }
  ],
  "pagination": {
    "total": 5,
    "returned": 3,
    "hasMore": true
  },
  "searchTime": "0.2s"
}
```

## Search Categories

### content
Broad text search across issue titles and descriptions

### assignee
Find issues assigned to specific user (by name or email)

### label
Search for issues with specific labels (bug, feature, enhancement, etc.)

### status
Find issues by state (Backlog, In Progress, In Review, Done, Canceled)

### cycle
Find issues in specific sprint or cycle (Current, Q1, Sprint 1, etc.)

## Query Formats

| Format | Example | Searches |
|--------|---------|----------|
| Issue ID | `ENG-1234` | Direct issue lookup |
| User name | `alice` | Issues assigned to Alice |
| Label | `bug` | Issues with bug label |
| Team | `Engineering` | All issues in Engineering team |
| Status | `In Progress` | Issues currently in progress |

## Protocol

1. **Receive search criteria** (query, filters, options)
2. **Query Linear API** with specified filters
3. **Retrieve matching issues** with metadata and relationships
4. **Fetch linked resources** (PRs, tickets, child issues)
5. **Return structured results** with issue details and links
6. **Do NOT interpret** results (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or create issues
- Change issue status or assignments
- Create or update comments
- Generate reports or analytics
- Archive or delete issues
- Configure Linear workspace settings
- Handle sensitive workspace data beyond search results

## Example Invocations

### Search by Content
```
[invoke linear-searcher]
input: {
  "action": "search",
  "query": "authentication",
  "searchBy": "content",
  "limit": 5
}

Output:
{
  "status": "success",
  "resultsFound": 3,
  "results": [
    {
      "id": "ENG-1234",
      "title": "Implement user authentication flow",
      "state": "In Progress",
      "url": "https://linear.app/getditto/issue/ENG-1234"
    }
  ]
}
```

### Find Issues in Current Sprint
```
[invoke linear-searcher]
input: {
  "action": "search",
  "query": "*",
  "searchBy": "cycle",
  "filters": {
    "cycle": "Current",
    "status": "In Progress"
  }
}

Output:
{
  "status": "success",
  "resultsFound": 12,
  "results": [...]
}
```

### Search with Multiple Filters
```
[invoke linear-searcher]
input: {
  "action": "search",
  "query": "API",
  "searchBy": "label",
  "filters": {
    "label": "bug",
    "priority": "High",
    "project": "SDK"
  },
  "includeLinks": true
}

Output:
{
  "status": "success",
  "resultsFound": 2,
  "results": [
    {
      "id": "SDK-456",
      "title": "API response parsing error",
      "linkedResources": {
        "pullRequests": [...],
        "parentIssue": "SDK-450"
      }
    }
  ]
}
```

## Error Cases

| Scenario | Response |
|----------|----------|
| No results found | `"No issues found matching: [query]. Try alternative search terms or broader filters."` |
| Invalid search type | `"Unknown search category: [type]. Supported: content, assignee, label, status, cycle"` |
| Invalid issue ID | `"Issue [ID] not found. Check the ID format and project."` |
| Access denied | `"You do not have permission to access this workspace or issue."` |
| Linear API unavailable | `"Linear service unavailable. Try again later."` |
| Invalid filter | `"Unknown filter or value: [filter]. Check Linear project structure."` |

## Linked Resources

The skill can retrieve associated:
- **Pull Requests** — GitHub PRs linked in issue description or comments
- **Zendesk Tickets** — Support tickets linked to issues
- **Parent/Child Issues** — Hierarchical issue relationships
- **Blocked By/Blocks** — Issue dependencies
- **Related Issues** — Cross-referenced issues
- **Logs & Error Reports** — Debug information attached to issues
- **Commits** — Git commits mentioning the issue ID

## Integration Notes

- **Used by agents**: linear-expert, project-planner, implementor, tech-writer
- **Returns structured data**: Issues with metadata and relationships
- **Always fresh**: Never caches results - always queries current data
- **Relationship-aware**: Can follow parent/child and dependency links
- **Multi-resource**: Retrieves linked PRs, tickets, logs, and commits
- **No modification**: Read-only skill - never changes issue state
- **Workspace-aware**: Respects team and project structure
- **Filter-rich**: Supports multiple simultaneous filters
