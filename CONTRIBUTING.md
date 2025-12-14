# Contributing to ScreenshotPlus

Thank you for your interest in contributing to ScreenshotPlus! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone. Be kind, constructive, and professional in all interactions.

## How to Contribute

### Reporting Bugs

Before submitting a bug report:

1. **Search existing issues** to avoid duplicates
2. **Use the latest version** to check if the bug has been fixed
3. **Collect information** about the issue (macOS version, steps to reproduce, expected vs actual behavior)

When creating a bug report, please include:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- macOS version and system information
- Screenshots or screen recordings if applicable
- Any relevant log output

### Suggesting Features

Feature requests are welcome! Please:

1. **Search existing issues** to see if it's already been suggested
2. **Open an issue** with the `enhancement` label
3. **Describe the feature** clearly and explain why it would be useful
4. **Consider the scope** - does it fit the project's goals?

### Pull Requests

#### Before You Start

1. **Open an issue first** to discuss the change you want to make
2. **Wait for approval** before starting significant work
3. **Check the issue isn't already being worked on**

#### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/screenshot-plus.git
   cd screenshot-plus
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+ or Swift 5.9+ toolchain

#### Building and Testing

```bash
cd ScreenshotPlus
swift build
swift test
```

#### Submitting Your Pull Request

1. **Ensure all tests pass** before submitting
2. **Update documentation** if you're changing functionality
3. **Write clear commit messages** that describe what changed and why
4. **Keep PRs focused** - one feature or fix per PR
5. **Reference the related issue** in your PR description (e.g., "Fixes #123")

#### PR Requirements

- [ ] Code builds without errors
- [ ] All tests pass
- [ ] New features include tests
- [ ] Code follows the existing style
- [ ] Documentation is updated if needed
- [ ] Commit messages are clear and descriptive

### Commit Message Guidelines

Use clear, descriptive commit messages:

```
type: short description

Longer explanation if needed. Wrap at 72 characters.
Explain what and why, not how.

Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, no code change
- `refactor`: Code restructuring without changing behavior
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Keep functions focused and small
- Add comments for complex logic
- Use SwiftUI best practices

## Review Process

1. A maintainer will review your PR
2. They may request changes or ask questions
3. Once approved, a maintainer will merge your PR
4. Your contribution will be included in the next release

## Getting Help

- Open a [Discussion](https://github.com/YOUR_USERNAME/screenshot-plus/discussions) for questions
- Check existing issues and discussions first
- Be patient - maintainers are volunteers

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to ScreenshotPlus!
