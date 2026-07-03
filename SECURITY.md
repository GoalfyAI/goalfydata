# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly.

**Do NOT create a public GitHub Issue for security vulnerabilities.**

Please email: **goalfydata@goalfyai.com**

Include the following information:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide a detailed response within 5 business days.

## Supported Versions

| Version | Supported |
|---------|-----------|
| v1.0.x  | Yes       |

## Security Practices

- All credentials encrypted at rest (AES-256) and in transit (TLS 1.3)
- User scripts run in isolated sandboxes with no host access
- API Keys can be rotated or revoked at any time
- Sensitive data is never logged in execution logs
