# Test Fixtures for Homebrew Validation

This directory contains test manuscript fixtures used by the GitHub Actions workflow to validate rxiv-maker Homebrew installation functionality.

## Directory Structure

```
test-fixtures/
├── basic-manuscript/          # Minimal test manuscript
│   ├── 00_CONFIG.yml         # Basic configuration
│   ├── 01_MAIN.md           # Simple content
│   └── 03_REFERENCES.bib    # Test references
├── figures-manuscript/        # Manuscript with figures (future)
└── complex-manuscript/        # Advanced features test (future)
```

## Fixture Types

### Basic Manuscript

**Purpose**: Validates core functionality with minimal dependencies
**Processing time**: ~30-60 seconds  
**Features tested**:
- ✓ YAML configuration parsing
- ✓ Markdown to LaTeX conversion
- ✓ Basic formatting (headers, lists, emphasis)
- ✓ Simple citations and bibliography
- ✓ PDF compilation
- ✓ Cross-platform compatibility

**Usage in CI**:
```bash
# Copy fixture to test directory
cp -r .github/test-fixtures/basic-manuscript test-manuscript

# Generate PDF
rxiv pdf test-manuscript
```

### Figures Manuscript (Future)

**Purpose**: Test figure generation and processing
**Features to test**:
- Python script execution for figures
- R script execution for plots  
- Image embedding and sizing
- Figure referencing system
- Multi-format output support

### Complex Manuscript (Future)

**Purpose**: Test advanced features and edge cases
**Features to test**:
- Mathematical expressions (complex LaTeX)
- Tables with advanced formatting
- Multiple bibliography styles
- Supplementary materials
- ArXiv submission preparation
- Track changes functionality

## Design Principles

### Minimal Dependencies
- No external data files required
- No network access needed
- Fast processing for CI efficiency
- Self-contained test cases

### Cross-Platform Compatibility  
- Uses only standard rxiv-maker features
- Avoids OS-specific paths or commands
- Works with default LaTeX installations
- Compatible with CI environments

### Comprehensive Coverage
- Tests critical user workflows
- Validates installation completeness
- Exercises error handling paths
- Provides clear success/failure indicators

## Usage Guidelines

### For Workflow Development
1. Copy desired fixture to temporary directory
2. Run rxiv-maker commands on the fixture
3. Validate expected outputs are generated
4. Clean up temporary files

### For Manual Testing
```bash
# Test basic functionality
cd .github/test-fixtures/basic-manuscript
rxiv pdf .

# Should generate PDF successfully
ls *.pdf
```

### Adding New Fixtures

When adding new test fixtures:

1. **Create descriptive directory structure**
2. **Include README explaining purpose**  
3. **Keep processing time reasonable (<2 minutes)**
4. **Test on multiple platforms**
5. **Document expected outputs**
6. **Update this README**

## Expected Outputs

### Basic Manuscript Success Indicators
- ✓ PDF file generated (>10KB size)
- ✓ No fatal LaTeX errors in logs
- ✓ All sections rendered correctly
- ✓ Bibliography processed successfully
- ✓ Exit code 0 from rxiv pdf command

### Failure Indicators
- ❌ No PDF output generated
- ❌ LaTeX compilation errors
- ❌ Missing dependencies reported
- ❌ CLI command timeouts
- ❌ Non-zero exit codes

## Maintenance

These fixtures should be:
- **Updated** when rxiv-maker features change
- **Tested** before major releases
- **Simplified** if CI performance degrades
- **Expanded** to cover new functionality

For questions or improvements, see the main repository issues.