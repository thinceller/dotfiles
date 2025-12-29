# API Testing Detailed Guide

This reference provides comprehensive patterns for API testing.

## Contents

- [Authentication Strategies](#authentication-strategies)
- [Mock Server Setup](#mock-server-setup)
- [Test Organization](#test-organization)
- [Advanced Patterns](#advanced-patterns)

## Authentication Strategies

### Bearer Token

```bash
curl -H "Authorization: Bearer $TOKEN" \
  https://api.example.com/endpoint
```

### API Key

```bash
curl -H "X-API-Key: $API_KEY" \
  https://api.example.com/endpoint
```

### OAuth2 Flow

1. Obtain authorization code
2. Exchange for access token
3. Use token in requests
4. Refresh when expired

```bash
# Token refresh
curl -X POST https://auth.example.com/token \
  -d "grant_type=refresh_token" \
  -d "refresh_token=$REFRESH_TOKEN"
```

## Mock Server Setup

### Using json-server

```bash
# Install
npm install -g json-server

# Create db.json
echo '{"users": [{"id": 1, "name": "Test"}]}' > db.json

# Start server
json-server --watch db.json --port 3000
```

### Using Postman Mock

1. Create collection with example responses
2. Generate mock server
3. Use mock URL in tests

## Test Organization

### Directory Structure

```
tests/
├── api/
│   ├── users.test.js
│   ├── orders.test.js
│   └── auth.test.js
├── fixtures/
│   ├── users.json
│   └── orders.json
└── helpers/
    ├── auth.js
    └── assertions.js
```

### Test File Template

```javascript
describe('Users API', () => {
  describe('GET /users', () => {
    it('returns list of users', async () => {
      const response = await api.get('/users');
      expect(response.status).toBe(200);
      expect(response.data).toBeArray();
    });

    it('supports pagination', async () => {
      const response = await api.get('/users?page=1&limit=10');
      expect(response.data.length).toBeLessThanOrEqual(10);
    });
  });

  describe('POST /users', () => {
    it('creates new user', async () => {
      const response = await api.post('/users', {
        name: 'New User',
        email: 'new@example.com'
      });
      expect(response.status).toBe(201);
      expect(response.data.id).toBeDefined();
    });

    it('validates required fields', async () => {
      const response = await api.post('/users', {});
      expect(response.status).toBe(400);
    });
  });
});
```

## Advanced Patterns

### Contract Testing

Verify API adheres to OpenAPI specification:

```bash
# Using spectral
spectral lint openapi.yaml

# Using prism
prism mock openapi.yaml
```

### Load Testing

```bash
# Using k6
k6 run load-test.js

# Using Apache Bench
ab -n 1000 -c 10 https://api.example.com/endpoint
```

### Snapshot Testing

Compare API responses against saved snapshots:

```javascript
it('matches snapshot', async () => {
  const response = await api.get('/users/1');
  expect(response.data).toMatchSnapshot();
});
```

### Retry Strategies

Handle flaky tests with retries:

```javascript
const retry = async (fn, attempts = 3) => {
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === attempts - 1) throw e;
      await sleep(1000 * (i + 1));
    }
  }
};
```

## Error Handling Patterns

### Timeout Handling

```javascript
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 5000);

try {
  const response = await fetch(url, {
    signal: controller.signal
  });
} finally {
  clearTimeout(timeout);
}
```

### Rate Limit Handling

```javascript
const handleRateLimit = async (response) => {
  if (response.status === 429) {
    const retryAfter = response.headers.get('Retry-After') || 60;
    await sleep(retryAfter * 1000);
    return retry();
  }
  return response;
};
```
