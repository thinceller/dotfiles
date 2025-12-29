---
name: API Testing
description: This skill should be used when the user asks to "test an API", "write API tests", "mock API responses", "validate API endpoints", or needs guidance on REST API testing strategies.
---

# API Testing

This skill provides guidance for testing REST APIs effectively.

## Quick Start

Test a simple endpoint:
```bash
curl -X GET https://api.example.com/users \
  -H "Authorization: Bearer $TOKEN"
```

## Testing Workflow

1. **Identify endpoints** - List all endpoints to test
2. **Set up test environment** - Configure base URL, auth tokens
3. **Write test cases** - Cover success, error, edge cases
4. **Run tests** - Execute and collect results
5. **Validate responses** - Check status codes, body, headers

## Common Test Cases

### Success Cases

- Valid request returns expected data
- Pagination works correctly
- Filtering/sorting produces correct results

### Error Cases

- Invalid auth returns 401
- Missing required fields return 400
- Non-existent resource returns 404
- Rate limiting returns 429

### Edge Cases

- Empty results return empty array, not null
- Large payloads handled correctly
- Special characters in inputs escaped properly

## Response Validation

Check these elements:
- **Status code**: 200, 201, 400, 401, 404, 500
- **Response body**: JSON structure matches schema
- **Headers**: Content-Type, pagination headers
- **Timing**: Response within acceptable limits

## Additional Resources

For detailed testing patterns and advanced techniques:

- **`references/detailed-guide.md`** - Comprehensive testing patterns, authentication strategies, and mock server setup
