# Slack Searcher Skill

Search and retrieve messages, files, and conversations from Slack workspaces.

## Capability

Searches Slack to find:
- Messages by keywords, users, channels, date ranges
- Files by type, filename, or content
- Threads and conversation details
- User information and channel metadata
- Message reactions and thread replies

Returns matched messages with metadata, context, and related thread information.

## How to Use This Skill

### Input
```
{
  "action": "search",
  "query": "deployment",                          // Search term or phrase
  "searchIn": "messages|files|threads|all",       // Where to search (default: all)
  "filters": {
    "channel": "engineering",                     // Optional: specific channel
    "from": "alice@example.com",                  // Optional: message author
    "before": "2025-12-14",                       // Optional: date range (YYYY-MM-DD)
    "after": "2025-12-01",
    "has": "attachments|reactions|replies"       // Optional: filter by content type
  },
  "limit": 20,                                    // Max results (default: 10)
  "includeThreads": true,                         // Include full thread replies
  "sortBy": "relevance|date"                      // Sort order (default: relevance)
}
```

### Output

Returns search results document:
```
{
  "status": "success",  // success|error|not-found
  "query": "deployment",
  "searchIn": "all",
  "resultsFound": 5,
  "results": [
    {
      "messageId": "1702560000.000100",
      "timestamp": "2025-12-10T14:00:00Z",
      "channel": {
        "id": "C1234567890",
        "name": "engineering",
        "isPrivate": false
      },
      "user": {
        "id": "U1234567890",
        "name": "alice",
        "email": "alice@example.com"
      },
      "text": "Ready to deploy v2.0 to production",
      "reactions": ["rocket", "tada"],
      "attachments": [
        {
          "id": "F1234567890",
          "name": "deployment-plan.pdf",
          "type": "pdf",
          "url": "https://slack.com/files/..."
        }
      ],
      "thread": {
        "replyCount": 3,
        "lastReplyTime": "2025-12-10T15:30:00Z",
        "replies": [
          {
            "messageId": "1702563600.000101",
            "timestamp": "2025-12-10T15:00:00Z",
            "user": "bob",
            "text": "All tests passing!"
          }
        ]
      },
      "permalink": "https://workspace.slack.com/archives/C1234567890/p1702560000000100"
    }
  ],
  "pagination": {
    "total": 15,
    "returned": 5,
    "hasMore": true
  },
  "searchTime": "0.4s"
}
```

## Search Categories

### messages
Search message text and content (includes message body, not file contents)

### files
Search files by filename or metadata (not file content unless explicitly indexed)

### threads
Search for threaded conversations (parent message + replies)

### all
Comprehensive search across messages, files, and threads (default)

## Filters

| Filter | Options | Example |
|--------|---------|---------|
| channel | Channel name or ID | `"engineering"`, `"C1234567890"` |
| from | Username or email | `"alice"`, `"alice@example.com"` |
| before | Date in YYYY-MM-DD | `"2025-12-14"` |
| after | Date in YYYY-MM-DD | `"2025-12-01"` |
| has | `attachments`, `reactions`, `replies` | Filter by content type |

## Protocol

1. **Receive search criteria** (query, filters, options)
2. **Query Slack API** with specified filters
3. **Retrieve matching messages/files** with metadata
4. **Fetch thread replies** if requested
5. **Return structured results** with content and context
6. **Do NOT interpret** results (agent's responsibility)

## Constraints

This skill **does not**:
- Create, edit, or delete messages
- Post reactions or replies
- Change channel settings or membership
- Access channels user doesn't have permission for
- Search file content (metadata only, unless indexed)
- Export or archive conversations
- Manage integrations or workflows

## Example Invocations

### Search for Recent Decisions
```
[invoke slack-searcher]
input: {
  "action": "search",
  "query": "decision",
  "searchIn": "messages",
  "filters": {
    "after": "2025-12-01"
  },
  "limit": 5
}

Output:
{
  "status": "success",
  "resultsFound": 3,
  "results": [
    {
      "channel": "engineering",
      "user": "alice",
      "text": "We've decided to migrate to Rust for the core",
      "timestamp": "2025-12-10T10:00:00Z"
    }
  ]
}
```

### Find Messages from Specific User
```
[invoke slack-searcher]
input: {
  "action": "search",
  "query": "deployment",
  "filters": {
    "from": "alice",
    "channel": "engineering"
  },
  "includeThreads": true
}

Output:
{
  "status": "success",
  "resultsFound": 2,
  "results": [...]
}
```

### Search for Files
```
[invoke slack-searcher]
input: {
  "action": "search",
  "query": "diagram",
  "searchIn": "files",
  "filters": {
    "has": "attachments"
  }
}

Output:
{
  "status": "success",
  "resultsFound": 4,
  "results": [
    {
      "messageId": "...",
      "channel": "design",
      "text": "Here's the architecture diagram",
      "attachments": [
        {
          "name": "architecture-diagram.png",
          "type": "png"
        }
      ]
    }
  ]
}
```

### Find Threaded Discussions
```
[invoke slack-searcher]
input: {
  "action": "search",
  "query": "API design",
  "searchIn": "threads",
  "filters": {
    "has": "replies"
  },
  "includeThreads": true,
  "limit": 3
}

Output:
{
  "status": "success",
  "resultsFound": 1,
  "results": [
    {
      "text": "New API endpoint design proposal",
      "thread": {
        "replyCount": 5,
        "replies": [
          {"user": "bob", "text": "Good approach, but..."},
          {"user": "charlie", "text": "I agree..."}
        ]
      }
    }
  ]
}
```

## Error Cases

| Scenario | Response |
|----------|----------|
| No results found | `"No messages found matching: [query]. Try alternative terms or broaden filters."` |
| Invalid channel | `"Channel '[name]' not found. Check channel name and permissions."` |
| Access denied | `"You do not have permission to access this channel or workspace."` |
| Authentication failed | `"Slack authentication failed. Check SLACK_BOT_TOKEN."` |
| Invalid filter | `"Invalid filter: [filter]. Supported: channel, from, before, after, has"` |
| Slack API error | `"Slack API error: [error message]"` |
| Invalid date format | `"Invalid date format: [date]. Use YYYY-MM-DD."` |

## Privacy & Security

The skill respects:
- **Channel access controls** — Only searches channels user has access to
- **Message visibility** — Respects per-message permission settings
- **Private conversations** — Cannot search DMs without permission
- **Rate limits** — Implements appropriate delays to avoid throttling
- **Data confidentiality** — Returns only requested information

## Metadata Included

Search results contain:
- **Message Content**: Text, reactions, attachments
- **Context**: Channel, user, timestamp, thread info
- **Thread Details**: Reply count, replies (when requested)
- **File Metadata**: Filename, type, URL
- **Permalinks**: Direct link to message in Slack

## Integration Notes

- **Used by agents**: slack-expert, team-analyst, knowledge-base-assistant
- **Returns structured data**: Messages with metadata and context
- **Always fresh**: Never caches results - always queries current data
- **Permission-aware**: Respects user's channel access and permissions
- **Thread-aware**: Can retrieve full threaded conversations
- **No modification**: Read-only skill - never changes Slack data
- **Rate-limited**: Respects Slack API rate limits
- **Filter-rich**: Supports multiple simultaneous filters
