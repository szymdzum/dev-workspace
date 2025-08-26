# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

Please report security vulnerabilities by emailing the maintainer. Do not create public issues for security concerns.

## Security Measures

### Branch Protection
- Main branch is protected with required status checks
- Pull requests require at least 1 review
- Stale reviews are dismissed on new commits

### Automated Security
- Dependency vulnerability scanning
- Secret detection in CI/CD
- Security audit on every PR

### Access Control
- Personal access tokens are used for automation
- No secrets are committed to the repository
- Environment variables used for sensitive data

### Dependencies
- Regular dependency updates via Dependabot
- Security audit checks on install
- Minimal dependency footprint

## Best Practices

### For Contributors
- Never commit API keys, tokens, or passwords
- Use environment variables for sensitive configuration
- Keep dependencies up to date
- Follow secure coding practices

### For Maintainers
- Review all PRs for security implications
- Monitor security advisories for dependencies
- Keep CI/CD secrets secure
- Regular security audits