# Homebrew Tap for rxiv-maker

A [Homebrew](https://brew.sh/) tap for installing [rxiv-maker](https://github.com/henriqueslab/rxiv-maker), an automated LaTeX article generation system with modern CLI and figure creation capabilities.

[![DOI](https://img.shields.io/badge/DOI-10.48550%2FarXiv.2508.00836-blue)](https://doi.org/10.48550/arXiv.2508.00836)
[![License](https://img.shields.io/github/license/henriqueslab/rxiv-maker?color=Green)](https://github.com/henriqueslab/rxiv-maker/blob/main/LICENSE)
[![Homebrew Validation](https://github.com/henriqueslab/homebrew-rxiv-maker/actions/workflows/validate-homebrew-installation.yml/badge.svg)](https://github.com/henriqueslab/homebrew-rxiv-maker/actions/workflows/validate-homebrew-installation.yml)

**Rxiv-Maker** transforms scientific writing from chaos to clarity by converting Markdown manuscripts into publication-ready PDFs with reproducible figures, professional typesetting, and zero LaTeX hassle.

## Installation

### Prerequisites
- macOS 10.15+ or Linux
- [Homebrew](https://brew.sh/) package manager

### Quick Install
```bash
# Add the tap (one-time setup)
brew tap henriqueslab/rxiv-maker

# Install rxiv-maker with all dependencies
brew install rxiv-maker

# Verify installation
rxiv check-installation

# Quick start with modern CLI
rxiv init MY_PAPER/           # Initialize new manuscript
rxiv pdf MY_PAPER/            # Generate PDF
```

**Note:** LaTeX (texlive) is automatically installed as a dependency - no additional setup required!

## Updating
```bash
# Update all packages
brew update && brew upgrade

# Update only rxiv-maker
brew upgrade rxiv-maker
```

## Uninstalling
```bash
# Remove rxiv-maker
brew uninstall rxiv-maker

# Remove the tap (optional)
brew untap henriqueslab/rxiv-maker
```

## Homebrew-Specific Troubleshooting

### PATH Issues
If `rxiv` command is not found:
```bash
# Check if Homebrew bin is in PATH
echo $PATH | grep $(brew --prefix)/bin

# Add to PATH if missing (zsh)
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Add to PATH if missing (bash)
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

### Permission Issues
If you encounter permission errors:
```bash
# Fix Homebrew permissions
sudo chown -R $(whoami) $(brew --prefix)/*
```

## 🧪 Automated Validation

This tap includes comprehensive GitHub Actions workflows that validate the Homebrew installation works correctly across platforms:

### Validation Workflows

**🔍 PR Validation (Fast)** - Runs on pull requests
- ✅ Formula syntax and style validation
- ✅ Quick installation test on Ubuntu
- ✅ Basic CLI functionality verification
- ⏱️ ~5-10 minutes for fast feedback

**🧪 Full Installation Validation** - Runs on main branch and schedule
- 🔄 **Cross-platform matrix**: macOS (latest, 12) + Linux (Ubuntu latest, 20.04)
- 🔧 **Complete workflow**: Installation → CLI test → Manuscript creation → PDF generation
- 📊 **Performance monitoring**: Installation time, resource usage, build metrics
- 📝 **Test modes**: Standard, fast, comprehensive, debug
- ⏱️ ~20-45 minutes for thorough validation

### Test Coverage

The validation workflows test:

**✅ Installation Process**
- Homebrew tap setup and formula installation
- Dependency resolution (Python, Node.js, LaTeX)
- CLI command availability and PATH setup
- Cross-platform compatibility

**✅ Core Functionality**  
- `rxiv init` - Manuscript initialization
- `rxiv pdf` - PDF generation workflow
- `rxiv check-installation` - System validation
- Help system and error handling

**✅ Integration Testing**
- Complete manuscript build pipeline
- Bibliography processing and citations
- LaTeX compilation and PDF output
- Performance benchmarking

### Viewing Test Results

- **Latest runs**: Check the [Actions tab](../../actions)
- **PR validation**: Results appear as PR checks and comments
- **Performance metrics**: Collected as workflow artifacts
- **Test coverage**: Basic → Standard → Comprehensive modes

### Contributing

When making changes to the formula:

1. **PR validation** runs automatically with fast feedback
2. **Fix any issues** reported by the validation workflow  
3. **Full validation** runs after merge to main
4. **Weekly schedule** catches any regressions

The workflows ensure reliable installation across all supported platforms.

## Complete Documentation

For comprehensive documentation, advanced features, and detailed usage instructions, visit the main project:

**📚 [Complete rxiv-maker Documentation](https://github.com/henriqueslab/rxiv-maker#readme)**

### Key Resources
- **[Installation Guide](https://github.com/henriqueslab/rxiv-maker/blob/main/docs/getting-started/installation.md)** - All installation methods
- **[User Guide](https://github.com/henriqueslab/rxiv-maker/blob/main/docs/getting-started/user_guide.md)** - Complete usage instructions
- **[VS Code Extension](https://github.com/HenriquesLab/vscode-rxiv-maker)** - Enhanced editing experience
- **[Google Colab](https://colab.research.google.com/github/HenriquesLab/rxiv-maker/blob/main/notebooks/rxiv_maker_colab.ipynb)** - Try without installation
- **[GitHub Issues](https://github.com/henriqueslab/rxiv-maker/issues)** - Support and bug reports
- **[GitHub Discussions](https://github.com/henriqueslab/rxiv-maker/discussions)** - Community support

### Alternative Installation Methods
- **Modern CLI**: `pip install rxiv-maker`
- **Docker**: Containerized execution with minimal dependencies
- **Google Colab**: Browser-based, zero installation
- **GitHub Actions**: Team collaboration and automation

## Citation

If you use Rxiv-Maker in your research, please cite our work:

**BibTeX:**
```bibtex
@misc{saraiva_2025_rxivmaker,
      title={Rxiv-Maker: an automated template engine for streamlined scientific publications}, 
      author={Bruno M. Saraiva and Guillaume Jaquemet and Ricardo Henriques},
      year={2025},
      eprint={2508.00836},
      archivePrefix={arXiv},
      primaryClass={cs.DL},
      url={https://arxiv.org/abs/2508.00836}, 
}
```

## License

This tap is licensed under the MIT License. See [LICENSE](LICENSE) for details.

The rxiv-maker software is separately licensed. See the [rxiv-maker repository](https://github.com/henriqueslab/rxiv-maker) for its license terms.