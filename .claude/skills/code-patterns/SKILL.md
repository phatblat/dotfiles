---
name: code-patterns
description: |-
  Reference patterns for REST APIs, pytest/vitest testing, Docker multi-stage builds, GitHub Actions CI/CD,
  PostgreSQL, TypeScript generics, Python async, and React Server Components.
  MUST BE USED when user asks about: "API design", "how to test", "Dockerfile", "CI/CD pipeline",
  "database schema", "TypeScript types", "async/await", "React hooks", "Next.js", "FastAPI",
  "testing pattern", "mock", "fixture", "docker compose", "github actions", "workflow yaml",
  "postgres query", "SQL pattern", "migration", "generic type", "server component",
  "use client", "use server", "middleware pattern", "error handling pattern", "retry logic".
  Includes code examples and validation commands.
  NOT for running tests (use smart-test-runner), security patterns (use security-audit),
  or git operations (use commit-message).
allowed-tools:
  - mcp__context7__resolve-library-id
  - mcp__context7__get-library-docs
  - Read
---

# Code Patterns Reference

This skill contains comprehensive patterns for modern development. Reference files are organized by topic.

## Quick Reference

| Topic | Key Patterns | When to Use |
|-------|--------------|-------------|
| API Design | REST, GraphQL, OpenAPI | Designing/implementing APIs |
| Testing | pytest, vitest, mocking | Writing tests |
| Docker | Multi-stage, Compose | Containerizing apps |
| CI/CD | GitHub Actions, pipelines | Setting up automation |
| Database | PostgreSQL, migrations | Database design |
| TypeScript | Types, generics, patterns | TS development |
| Python | async, patterns, uv | Python development |
| React/Next.js | Server Components, hooks | Frontend development |

## Reference Files

- `api.md` - REST, GraphQL, authentication, pagination
- `testing.md` - pytest, vitest, mocking, coverage
- `docker.md` - Dockerfiles, Compose, production
- `ci-cd.md` - GitHub Actions, deployment
- `database.md` - PostgreSQL, migrations, queries
- `typescript.md` - Types, generics, advanced patterns
- `python.md` - async, patterns, best practices
- `react.md` - Server Components, hooks, Next.js

---

## API Design Quick Reference

### REST Endpoints
```
GET    /resources         List
GET    /resources/{id}    Get one
POST   /resources         Create
PUT    /resources/{id}    Replace
PATCH  /resources/{id}    Update
DELETE /resources/{id}    Delete
```

### HTTP Status Codes
| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Unprocessable |
| 429 | Rate Limited |
| 500 | Server Error |

---

## Testing Quick Reference

### pytest
```python
@pytest.fixture
def client():
    return TestClient(app)

def test_endpoint(client):
    response = client.get("/api/users")
    assert response.status_code == 200
```

### vitest
```typescript
import { describe, it, expect, vi } from 'vitest';

describe('Component', () => {
  it('should work', () => {
    expect(true).toBe(true);
  });
});
```

---

## Docker Quick Reference

### Multi-Stage Build
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
COPY --from=builder /app/dist ./dist
USER node
CMD ["node", "dist/index.js"]
```

### Compose
```yaml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy
  db:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD", "pg_isready"]
```

---

## CI/CD Quick Reference

### GitHub Actions
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npm test
```

---

## TypeScript Quick Reference

### Utility Types
```typescript
Partial<T>      // All properties optional
Required<T>     // All properties required
Pick<T, K>      // Select properties
Omit<T, K>      // Exclude properties
Record<K, V>    // Object with key type K, value type V
```

### Generics
```typescript
function first<T>(arr: T[]): T | undefined {
  return arr[0];
}
```

---

## Python Quick Reference

### Async
```python
async def fetch_data():
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()
```

### Type Hints
```python
def process(items: list[str]) -> dict[str, int]:
    return {item: len(item) for item in items}
```

---

## React/Next.js Quick Reference

### Server Component (default)
```tsx
// app/page.tsx
async function Page() {
  const data = await fetch('...');
  return <div>{data}</div>;
}
```

### Client Component
```tsx
'use client';
import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```
