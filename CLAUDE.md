# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Homebrew tap for `rxiv-maker`, an automated LaTeX article generation system. The repository contains a single Homebrew formula that packages the Python-based rxiv-maker tool for easy installation on macOS and Linux systems.

## Key Commands

### Formula Testing and Validation
```bash
# Test formula syntax and style
brew audit --strict rxiv-maker

# Test installation with verbose output
brew install --verbose --debug rxiv-maker

# Test from source (useful when developing)
brew install --build-from-source rxiv-maker

# Test uninstall
brew uninstall rxiv-maker
```

### Formula Development
```bash
# Calculate SHA256 for new versions
brew fetch --build-from-source rxiv-maker

# Edit formula
vim Formula/rxiv-maker.rb

# Test after changes
brew reinstall rxiv-maker
```

### End-to-End Testing
```bash
# After installing, test the actual tool
rxiv --version
rxiv --help
```

## Architecture

The formula (`Formula/rxiv-maker.rb`) uses Homebrew's Python virtualenv pattern to install rxiv-maker and all its dependencies in an isolated Python environment. This follows Python PEP 668 best practices and avoids conflicts with system Python packages.

### Key Components:
- **Formula Class**: Inherits from `Formula` and includes `Language::Python::Virtualenv`
- **Resource Declarations**: All Python dependencies are explicitly listed with URLs and SHA256 checksums
- **Installation Method**: Uses `virtualenv_install_with_resources` for clean dependency management
- **Test Method**: Validates CLI functionality and Python module import
- **Caveats**: Informs users about required system dependencies (LaTeX)

## Formula Update Process

When updating to a new rxiv-maker version:
1. Update the main `url` and `sha256` in the formula
2. Check PyPI for any new or updated dependencies
3. Update resource URLs and checksums for any changed dependencies
4. Test the updated formula thoroughly
5. The formula automatically tracks the official PyPI releases

## Dependencies

The formula depends on:
- `python@3.12` (system dependency)
- Multiple Python packages defined as resources (click, matplotlib, pandas, etc.)
- External system dependencies (LaTeX, git) mentioned in caveats but not enforced

## Testing Strategy

The formula includes comprehensive tests:
- CLI version check
- Help command functionality  
- Python module import verification
- Integration with Homebrew's test framework