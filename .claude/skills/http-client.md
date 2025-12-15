# HTTP Client

Execute HTTP requests with structured output for REST API testing and integration.

## Capability

This skill executes HTTP requests (GET, POST, PUT, DELETE, PATCH, etc.) with authentication, headers, and payload handling. It returns structured results with status codes, headers, response bodies, and timing metadata.

## Supported Operations

### HTTP Methods
- **GET** - Retrieve resources
- **POST** - Create resources
- **PUT** - Update/replace resources
- **PATCH** - Partial update resources
- **DELETE** - Delete resources
- **HEAD** - Retrieve headers only
- **OPTIONS** - Query supported methods

### Authentication
- **none** - No authentication
- **basic** - HTTP Basic Auth
- **bearer** - Bearer token (JWT, OAuth2)
- **api-key** - API key (header or query parameter)
- **oauth1** - OAuth 1.0a
- **oauth2** - OAuth 2.0 (with token refresh)
- **digest** - HTTP Digest Auth
- **custom** - Custom authentication headers

### Content Types
- **JSON** - application/json
- **XML** - application/xml, text/xml
- **Form** - application/x-www-form-urlencoded
- **Multipart** - multipart/form-data (file uploads)
- **Plain text** - text/plain
- **Binary** - application/octet-stream

## Usage Protocol

Agents invoke this skill by specifying request parameters:

```json
{
  "action": "request",
  "method": "POST",
  "url": "https://api.example.com/v1/users",
  "headers": {
    "Content-Type": "application/json",
    "User-Agent": "MyApp/1.0"
  },
  "auth": {
    "type": "bearer",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  },
  "body": {
    "name": "John Doe",
    "email": "john@example.com"
  },
  "timeout": 30
}
```

### Parameters

- **action** (required): Always `"request"`
- **method** (required): HTTP method (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS)
- **url** (required): Full URL including protocol and path
- **headers** (optional): Request headers object
- **auth** (optional): Authentication configuration
- **body** (optional): Request body (string, object, or binary data)
- **queryParams** (optional): URL query parameters
- **timeout** (optional): Timeout in seconds (default: 30s)
- **followRedirects** (optional): Follow HTTP redirects (default: true)
- **validateSSL** (optional): Validate SSL certificates (default: true)

## Request Configurations

### GET Request with Query Parameters

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.example.com/v1/users",
  "queryParams": {
    "page": 2,
    "limit": 50,
    "sort": "created_at"
  },
  "auth": {
    "type": "api-key",
    "key": "your-api-key",
    "location": "header",
    "name": "X-API-Key"
  },
  "timeout": 30
}
```

### POST Request with JSON Body

```json
{
  "action": "request",
  "method": "POST",
  "url": "https://api.example.com/v1/posts",
  "headers": {
    "Content-Type": "application/json"
  },
  "auth": {
    "type": "bearer",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  },
  "body": {
    "title": "New Post",
    "content": "This is the content",
    "tags": ["tech", "api"]
  }
}
```

### PUT Request with Basic Auth

```json
{
  "action": "request",
  "method": "PUT",
  "url": "https://api.example.com/v1/users/123",
  "auth": {
    "type": "basic",
    "username": "admin",
    "password": "secret123"
  },
  "body": {
    "name": "Updated Name",
    "email": "newemail@example.com"
  }
}
```

### File Upload (Multipart)

```json
{
  "action": "request",
  "method": "POST",
  "url": "https://api.example.com/v1/upload",
  "headers": {
    "Content-Type": "multipart/form-data"
  },
  "body": {
    "file": {
      "path": "/path/to/image.png",
      "filename": "profile.png",
      "contentType": "image/png"
    },
    "description": "Profile picture"
  },
  "auth": {
    "type": "bearer",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

### DELETE Request

```json
{
  "action": "request",
  "method": "DELETE",
  "url": "https://api.example.com/v1/posts/456",
  "auth": {
    "type": "bearer",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

### Custom Headers

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.example.com/v1/data",
  "headers": {
    "Accept": "application/json",
    "Accept-Language": "en-US",
    "User-Agent": "MyApp/2.0",
    "X-Custom-Header": "custom-value",
    "X-Request-ID": "req-12345"
  },
  "auth": {
    "type": "api-key",
    "key": "your-api-key",
    "location": "query",
    "name": "api_key"
  }
}
```

## Authentication Types

### Bearer Token (JWT, OAuth2)

```json
{
  "auth": {
    "type": "bearer",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### Basic Authentication

```json
{
  "auth": {
    "type": "basic",
    "username": "user@example.com",
    "password": "securePassword123"
  }
}
```

### API Key (Header)

```json
{
  "auth": {
    "type": "api-key",
    "key": "sk_live_abc123xyz789",
    "location": "header",
    "name": "X-API-Key"
  }
}
```

### API Key (Query Parameter)

```json
{
  "auth": {
    "type": "api-key",
    "key": "abc123xyz789",
    "location": "query",
    "name": "api_key"
  }
}
```

### OAuth 2.0 with Token Refresh

```json
{
  "auth": {
    "type": "oauth2",
    "accessToken": "ya29.a0AfH6SMBx...",
    "refreshToken": "1//0gL3xQ9Z...",
    "tokenEndpoint": "https://oauth2.googleapis.com/token",
    "clientId": "your-client-id",
    "clientSecret": "your-client-secret"
  }
}
```

### Custom Authentication

```json
{
  "auth": {
    "type": "custom",
    "headers": {
      "X-Auth-Token": "custom-token-value",
      "X-User-ID": "12345"
    }
  }
}
```

## Output Format

Returns structured JSON execution report:

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "method": "GET",
    "url": "https://api.example.com/v1/users",
    "statusCode": 200,
    "statusText": "OK",
    "duration": "245ms",
    "success": true,
    "headers": {
      "content-type": "application/json",
      "content-length": "1234",
      "x-ratelimit-limit": "100",
      "x-ratelimit-remaining": "95"
    },
    "body": {
      "users": [
        {"id": 1, "name": "Alice"},
        {"id": 2, "name": "Bob"}
      ]
    },
    "metadata": {
      "redirects": 0,
      "tlsVersion": "TLS 1.3",
      "certificateValid": true,
      "bodySize": 1234,
      "requestSize": 156
    }
  }
}
```

### Successful GET Request

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:30:00Z",
    "method": "GET",
    "url": "https://api.github.com/repos/octocat/Hello-World",
    "statusCode": 200,
    "statusText": "OK",
    "duration": "342ms",
    "success": true,
    "headers": {
      "content-type": "application/json; charset=utf-8",
      "content-length": "5432",
      "x-ratelimit-limit": "60",
      "x-ratelimit-remaining": "59",
      "x-ratelimit-reset": "1702561800",
      "cache-control": "public, max-age=60",
      "etag": "\"abc123def456\""
    },
    "body": {
      "id": 1296269,
      "name": "Hello-World",
      "full_name": "octocat/Hello-World",
      "owner": {
        "login": "octocat",
        "id": 1
      },
      "stargazers_count": 80,
      "watchers_count": 80
    },
    "metadata": {
      "redirects": 0,
      "tlsVersion": "TLS 1.3",
      "certificateValid": true,
      "bodySize": 5432,
      "requestSize": 187
    }
  }
}
```

### Successful POST Request

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:31:00Z",
    "method": "POST",
    "url": "https://api.example.com/v1/users",
    "statusCode": 201,
    "statusText": "Created",
    "duration": "523ms",
    "success": true,
    "headers": {
      "content-type": "application/json",
      "location": "https://api.example.com/v1/users/789",
      "x-request-id": "req-abc-123"
    },
    "body": {
      "id": 789,
      "name": "John Doe",
      "email": "john@example.com",
      "created_at": "2025-12-14T14:31:00Z"
    },
    "metadata": {
      "redirects": 0,
      "bodySize": 156,
      "requestSize": 98
    }
  }
}
```

### Rate Limit Response

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:32:00Z",
    "method": "GET",
    "url": "https://api.example.com/v1/data",
    "statusCode": 429,
    "statusText": "Too Many Requests",
    "duration": "125ms",
    "success": false,
    "headers": {
      "content-type": "application/json",
      "x-ratelimit-limit": "100",
      "x-ratelimit-remaining": "0",
      "x-ratelimit-reset": "1702561920",
      "retry-after": "60"
    },
    "body": {
      "error": "Rate limit exceeded",
      "message": "You have exceeded the rate limit. Try again in 60 seconds."
    },
    "metadata": {
      "retryAfter": 60,
      "rateLimitReset": "2025-12-14T14:32:00Z"
    }
  }
}
```

### Redirect Response

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:33:00Z",
    "method": "GET",
    "url": "https://api.example.com/v1/legacy-endpoint",
    "statusCode": 200,
    "statusText": "OK",
    "duration": "456ms",
    "success": true,
    "headers": {
      "content-type": "application/json"
    },
    "body": {"data": "response"},
    "metadata": {
      "redirects": 2,
      "redirectChain": [
        "https://api.example.com/v1/legacy-endpoint",
        "https://api.example.com/v2/new-endpoint",
        "https://api.example.com/v2/new-endpoint-final"
      ],
      "finalUrl": "https://api.example.com/v2/new-endpoint-final"
    }
  }
}
```

### File Upload Response

```json
{
  "executionReport": {
    "timestamp": "2025-12-14T14:34:00Z",
    "method": "POST",
    "url": "https://api.example.com/v1/upload",
    "statusCode": 200,
    "statusText": "OK",
    "duration": "2.3s",
    "success": true,
    "headers": {
      "content-type": "application/json"
    },
    "body": {
      "file_id": "file_abc123",
      "filename": "profile.png",
      "size": 245678,
      "url": "https://cdn.example.com/uploads/file_abc123.png"
    },
    "metadata": {
      "uploadSize": 245678,
      "uploadSpeed": "106 KB/s"
    }
  }
}
```

## Error Handling

Returns structured error information for:

- **Network errors**: Connection refused, timeout, DNS failure
- **HTTP errors**: 4xx client errors, 5xx server errors
- **SSL/TLS errors**: Certificate validation failures
- **Authentication errors**: Invalid credentials, expired tokens
- **Rate limiting**: Too many requests
- **Malformed responses**: Invalid JSON, unexpected content type

Example error response:

```json
{
  "error": {
    "type": "http-error",
    "statusCode": 401,
    "statusText": "Unauthorized",
    "message": "Authentication failed: Invalid or expired token",
    "url": "https://api.example.com/v1/protected",
    "method": "GET",
    "headers": {
      "www-authenticate": "Bearer realm=\"API\", error=\"invalid_token\"",
      "content-type": "application/json"
    },
    "body": {
      "error": "invalid_token",
      "error_description": "The access token expired"
    },
    "duration": "234ms",
    "solution": "Refresh access token or re-authenticate"
  }
}
```

### Connection Timeout

```json
{
  "error": {
    "type": "timeout",
    "message": "Connection timeout after 30 seconds",
    "url": "https://api.slow-service.com/v1/data",
    "method": "GET",
    "timeout": 30,
    "solution": "Increase timeout or check network connectivity"
  }
}
```

### SSL Certificate Error

```json
{
  "error": {
    "type": "ssl-error",
    "message": "SSL certificate verification failed",
    "url": "https://api.example.com/v1/data",
    "method": "GET",
    "details": "certificate has expired",
    "solution": "Update SSL certificate or set validateSSL: false (not recommended for production)"
  }
}
```

### DNS Resolution Failed

```json
{
  "error": {
    "type": "dns-error",
    "message": "Failed to resolve hostname",
    "url": "https://nonexistent-api.invalid/v1/data",
    "method": "GET",
    "details": "Name or service not known",
    "solution": "Verify URL is correct and domain exists"
  }
}
```

### Malformed JSON Response

```json
{
  "error": {
    "type": "parse-error",
    "message": "Failed to parse JSON response",
    "url": "https://api.example.com/v1/data",
    "method": "GET",
    "statusCode": 200,
    "rawBody": "{invalid json content",
    "details": "Unexpected token 'i' at position 1",
    "solution": "Contact API provider about malformed response"
  }
}
```

### 500 Internal Server Error

```json
{
  "error": {
    "type": "http-error",
    "statusCode": 500,
    "statusText": "Internal Server Error",
    "message": "Server encountered an error processing the request",
    "url": "https://api.example.com/v1/process",
    "method": "POST",
    "body": {
      "error": "internal_error",
      "message": "An unexpected error occurred",
      "request_id": "req-xyz-789"
    },
    "duration": "5.2s",
    "solution": "Retry request or contact API support with request_id: req-xyz-789"
  }
}
```

## Advanced Features

### Retry Logic with Exponential Backoff

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.example.com/v1/data",
  "retry": {
    "enabled": true,
    "maxAttempts": 3,
    "backoffStrategy": "exponential",
    "initialDelay": 1000,
    "maxDelay": 10000,
    "retryOn": [408, 429, 500, 502, 503, 504]
  }
}
```

### Response Streaming

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.example.com/v1/large-file",
  "streaming": {
    "enabled": true,
    "chunkSize": 8192,
    "outputFile": "/tmp/download.bin"
  }
}
```

### Request Validation

```json
{
  "action": "request",
  "method": "POST",
  "url": "https://api.example.com/v1/users",
  "body": {"name": "John", "email": "john@example.com"},
  "validation": {
    "schema": {
      "type": "object",
      "properties": {
        "name": {"type": "string", "minLength": 1},
        "email": {"type": "string", "format": "email"}
      },
      "required": ["name", "email"]
    }
  }
}
```

### Proxy Support

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.example.com/v1/data",
  "proxy": {
    "host": "proxy.example.com",
    "port": 8080,
    "auth": {
      "username": "proxyuser",
      "password": "proxypass"
    }
  }
}
```

## Tool Requirements

### Core HTTP Libraries (auto-selected)
- **curl** - Command-line HTTP client (universal fallback)
- **Python requests** - For Python-based execution
- **Node.js fetch/axios** - For JavaScript-based execution

### Optional Tools
- **jq** - JSON parsing and formatting
- **httpie** - Human-friendly HTTP client
- **wget** - File downloading

## Constraints

This skill does NOT:
- Design API endpoints or REST architecture
- Generate client code in programming languages
- Analyze API specifications (OpenAPI/Swagger)
- Recommend authentication methods
- Provide API best practices guidance
- Debug application logic beyond HTTP layer
- Parse or validate complex response schemas (returns raw body)
- Implement custom business logic
- Store or manage API credentials
- Rate limit management decisions (reports limits, doesn't decide strategy)

## Security Considerations

### Credential Handling
- Credentials passed in requests are NOT logged
- API keys and tokens sanitized in output logs
- Supports environment variable substitution
- Warns about insecure practices (e.g., validateSSL: false)

### SSL/TLS
- Validates certificates by default
- Supports custom CA certificates
- Reports TLS version and cipher suite
- Warns about deprecated TLS versions

## Common HTTP Workflows

### Test REST API Endpoint

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.github.com/zen",
  "headers": {
    "Accept": "text/plain"
  }
}
```

### Create Resource with Authentication

```json
{
  "action": "request",
  "method": "POST",
  "url": "https://api.stripe.com/v1/customers",
  "auth": {
    "type": "bearer",
    "token": "sk_test_abc123"
  },
  "body": {
    "email": "customer@example.com",
    "name": "Test Customer"
  }
}
```

### Update Resource

```json
{
  "action": "request",
  "method": "PATCH",
  "url": "https://api.example.com/v1/users/123",
  "auth": {
    "type": "bearer",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  },
  "body": {
    "status": "active"
  }
}
```

### Check API Health

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.example.com/health",
  "timeout": 5
}
```

### Download File

```json
{
  "action": "request",
  "method": "GET",
  "url": "https://api.example.com/files/report.pdf",
  "auth": {
    "type": "api-key",
    "key": "your-api-key",
    "location": "header",
    "name": "X-API-Key"
  },
  "streaming": {
    "enabled": true,
    "outputFile": "/tmp/report.pdf"
  }
}
```
