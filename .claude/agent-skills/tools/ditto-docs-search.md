# Ditto Docs Search Skill

Search Ditto SDK documentation and retrieve relevant API references, guides, and examples.

## Capability

Searches and retrieves information from Ditto documentation at https://docs.ditto.live with access to:
- SDK installation guides and quickstarts for all platforms
- API references (Swift, JavaScript, Rust, C++, Java, C#/.NET, Flutter, Kotlin)
- Ditto Query Language (DQL) documentation
- Tutorials, guides, and best practices
- Release notes and migration guides
- Quickstart applications at https://github.com/getditto/quickstart

Returns documentation pages with URLs, relevant code examples, and warnings about outdated or broken content.

## How to Use This Skill

### Input
```
{
  "action": "search",
  "query": "how to set up sync between devices",    // What to search for
  "searchType": "general|api|guide|example|dql",   // Search category
  "platform": "swift|js|rust|cpp|java|kotlin|flutter|dotnet",  // Optional
  "version": "latest|v4|v5-preview"                // SDK version (default: latest)
}
```

### Output

Returns search results document:
```
{
  "status": "success",  // success|error|not-found
  "query": "how to set up sync",
  "searchType": "general",
  "resultsFound": 3,
  "results": [
    {
      "title": "Managing Subscriptions",
      "url": "https://docs.ditto.live/sdk/latest/syncing-data/managing-subscriptions",
      "section": "Syncing Data",
      "relevance": "high",
      "excerpt": "Devices express sync preferences using subscription queries. Automatic synchronization...",
      "type": "guide"
    },
    {
      "title": "Quick Start: Swift",
      "url": "https://docs.ditto.live/sdk/latest/quickstarts/quickstart-swift",
      "section": "Getting Started",
      "relevance": "medium",
      "excerpt": "Platform-specific quickstart guides for rapid development...",
      "type": "quickstart",
      "hasCodeExample": true
    }
  ],
  "relatedTopics": [
    "Key Concepts: Syncing Data",
    "Configuring Collection Sync"
  ],
  "brokenLinks": [],
  "outdatedWarnings": [],
  "searchTime": "0.3s"
}
```

## Search Types

### general
Broad searches across all documentation

### api
Search API reference documentation for specific platforms
- Returns: method signatures, parameters, return types, examples
- Requires: platform parameter

### guide
Search tutorials, how-to guides, and explanations
- Returns: conceptual content, step-by-step guides, best practices

### example
Search for code examples and quickstart applications
- Returns: code snippets, example repositories, sample implementations

### dql
Search Ditto Query Language documentation
- Returns: DQL syntax, clauses, operators, examples

## Documentation Structure Reference

### Getting Started
- **Quickstart**: Platform-specific rapid development guides
- **What is Ditto?**: Core capabilities and concepts
- **Key Concepts**: Apps, collections, document model, syncing, authentication, mesh networking
- **Demo Apps**: Task List, Inventory, Chat, Point-of-Sale samples

### Build with the SDK
- **Installation Guides**: Platform-specific setup instructions
- **Accessing Data**: CRUD operations, transactions, attachments
- **Syncing Data**: Subscriptions, collection sync, device storage
- **Authentication**: Online/offline methods, authorization
- **Managing the Mesh**: Presence, network transports, connections
- **Deploying Your App**: Configuration, testing, observability, logging, performance

### Query Language (DQL)
- **Clauses**: SELECT, INSERT, UPDATE, DELETE, EVICT
- **Optional Clauses**: WHERE, ORDER BY, LIMIT, OFFSET
- **Types & Functions**: Data types and built-in functions
- **Reference**: Complete language reference

### Cloud Platform
- **Cloud Portal**: Account management, app creation, data browser, RBAC
- **HTTP Data API**: RESTful API for external systems
- **Data Integration**: CDC, MongoDB connector

## Protocol

1. **Receive search query** and optional parameters
2. **Search docs.ditto.live** using provided query and search type
3. **Retrieve matching pages** with URLs and excerpts
4. **Check for known issues** (broken links, outdated content)
5. **Return structured results** with relevance ranking
6. **Do NOT interpret** or filter results (agent's responsibility)

## Constraints

This skill **does not**:
- Modify or update documentation
- Generate new documentation
- Interpret or filter search results
- Provide Ditto support or troubleshooting (unless documented)
- Access private/internal documentation
- Cache results (always fresh search)
- Search Quickstart repositories (only docs.ditto.live)

## Example Invocation

**Agent**: "Search for DQL documentation about UPDATE queries"

```
[invoke ditto-docs-search]
input: {
  "action": "search",
  "query": "UPDATE query syntax",
  "searchType": "dql"
}

Output:
{
  "status": "success",
  "query": "UPDATE query syntax",
  "searchType": "dql",
  "resultsFound": 2,
  "results": [
    {
      "title": "UPDATE",
      "url": "https://docs.ditto.live/dql/clauses/update",
      "section": "DQL Clauses",
      "relevance": "high",
      "excerpt": "Modify existing documents. UPDATE your_collection_name SET field1 = value1 WHERE [condition]",
      "type": "api"
    },
    {
      "title": "Migration: Legacy Query Builder to DQL",
      "url": "https://docs.ditto.live/sdk/latest/migration-guides/legacy-to-dql",
      "section": "Migration Guides",
      "relevance": "medium",
      "excerpt": "Update operations: store.execute(\"UPDATE COLLECTION name SET field = :value WHERE _id = :id\", params)",
      "type": "guide"
    }
  ]
}
```

## Platform-Specific Guidance

When searching by platform, returns API reference for:
- **Swift**: https://software.ditto.live/cocoa/DittoSwift/latest/api-reference/
- **JavaScript**: https://software.ditto.live/js/Ditto/latest/api-reference/
- **Rust**: https://software.ditto.live/rust/Ditto/latest/docs/dittolive_ditto/
- **C++**: https://software.ditto.live/cpp/Ditto/latest/api-reference/
- **Java**: https://software.ditto.live/java/ditto-java/latest/api-reference/
- **C# (.NET)**: https://software.ditto.live/dotnet/Ditto/latest/api-reference/
- **Flutter**: https://pub.dev/documentation/ditto_live/latest/
- **Kotlin**: https://software.ditto.live/android/DittoAndroid/latest/api-reference/

## Error Cases

| Scenario | Response |
|----------|----------|
| No results found | `"No documentation found matching: [query]. Try alternative terms or broader search."` |
| Invalid search type | `"Unknown search type: [type]. Supported: general, api, guide, example, dql"` |
| Invalid platform | `"Unknown platform: [platform]. Supported: swift, js, rust, cpp, java, kotlin, flutter, dotnet"` |
| docs.ditto.live unavailable | `"Documentation service unavailable. Try again later or check status at docs.ditto.live"` |
| Broken link detected | Include in response: `"Warning: The page at [URL] returned 404 - content may have moved"` |
| Outdated content | Include in response: `"Note: This content is for SDK v[old]. Current version is v[new]"` |

## Integration Notes

- **Used by agents**: ditto-docs, ditto-sdk-expert, tech-writer, documentation-reviewer
- **Returns structured data**: Search results with URLs and metadata
- **Always fresh**: Never caches results - always queries current docs
- **Platform-aware**: Can filter results by SDK platform
- **Version-aware**: Supports multiple SDK versions (v4, v5-preview, latest)
- **No modification**: Read-only skill - never modifies documentation
- **Comprehensive**: Covers SDK docs, DQL, cloud platform, and migration guides
