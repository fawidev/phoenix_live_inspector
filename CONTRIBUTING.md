# Contributing to Phoenix LiveView Inspector

Thank you for your interest in contributing! 🎉

## Getting Started

1. **Fork the repository**
2. **Clone your fork**: `git clone https://github.com/YOUR_USERNAME/phoenix_live_inspector.git`
3. **Create a branch**: `git checkout -b feature/your-feature-name`

## Development Setup

```bash
# Install dependencies
mix deps.get

# Compile the project  
mix compile

# Run tests
mix test

# Generate documentation
mix docs
```

## Browser Extension Development

The browser extension is located in `browser_extension/`:

1. Load unpacked extension in Chrome
2. Make changes to JS/CSS/HTML files
3. Reload extension in Chrome
4. Test with Phoenix LiveView apps

## Code Guidelines

- **Format code**: Run `mix format` before committing
- **Add tests**: Include tests for new features
- **Document functions**: Add `@doc` annotations for public functions
- **Follow conventions**: Match existing code style

## Submitting Changes

1. **Run tests**: `mix test`
2. **Format code**: `mix format`
3. **Commit changes**: Use descriptive commit messages
4. **Push branch**: `git push origin feature/your-feature-name`
5. **Create Pull Request**: Include description of changes

## Reporting Issues

When reporting bugs, please include:

- **Elixir version**: `elixir --version`
- **Phoenix version**: Check your `mix.exs`
- **Browser version**: Chrome version
- **Steps to reproduce**: Detailed reproduction steps
- **Expected vs actual behavior**

## Feature Requests

For new features:

- **Check existing issues** to avoid duplicates
- **Describe the use case** and benefits
- **Provide examples** of how it would work

## Questions?

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and ideas

We appreciate all contributions! 🚀