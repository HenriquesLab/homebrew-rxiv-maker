#!/bin/bash
# validate-homebrew-integrity.sh - Homebrew repository integrity validation
# Prevents contamination from main rxiv-maker project or other package managers

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ERRORS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    ((ERRORS++))
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

# Validate this is a Homebrew repository
validate_homebrew_structure() {
    log_info "Validating Homebrew repository structure..."
    
    # Required files for Homebrew tap
    required_files=(
        "Formula/rxiv-maker.rb"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${REPO_ROOT}/${file}" ]]; then
            log_error "Missing required Homebrew file: ${file}"
        else
            log_success "Found required file: ${file}"
        fi
    done
    
    # Validate Formula structure
    if [[ -f "${REPO_ROOT}/Formula/rxiv-maker.rb" ]]; then
        if grep -q "class RxivMaker < Formula" "${REPO_ROOT}/Formula/rxiv-maker.rb"; then
            log_success "Formula has correct class structure"
        else
            log_error "Formula missing correct class structure"
        fi
        
        if grep -q "include Language::Python::Virtualenv" "${REPO_ROOT}/Formula/rxiv-maker.rb"; then
            log_success "Formula includes Python virtualenv support"
        else
            log_error "Formula missing Python virtualenv support"
        fi
    fi
}

# Check for contamination from main project
validate_no_main_project_contamination() {
    log_info "Checking for main project contamination..."
    
    # Files that should NOT exist in Homebrew repo
    forbidden_files=(
        "pyproject.toml"
        "Makefile"
        "setup.py"
        "setup.cfg"
        "requirements.txt"
        "requirements-dev.txt"
        "src/rxiv_maker"
    )
    
    for file in "${forbidden_files[@]}"; do
        if [[ -e "${REPO_ROOT}/${file}" ]]; then
            log_error "Found forbidden main project file: ${file}"
        fi
    done
    
    # Check for Python files (except in scripts directory)
    if find "${REPO_ROOT}" -name "*.py" -not -path "*/scripts/*" | grep -q .; then
        log_error "Found Python files outside scripts directory:"
        find "${REPO_ROOT}" -name "*.py" -not -path "*/scripts/*"
    fi
    
    # Check for YAML files that might be from main project
    yaml_files=("noxfile.py" "pyproject.toml" ".github/workflows/test.yml" ".github/workflows/build-pdf.yml")
    for file in "${yaml_files[@]}"; do
        if [[ -f "${REPO_ROOT}/${file}" ]]; then
            log_error "Found main project YAML file: ${file}"
        fi
    done
}

# Check for contamination from other package managers
validate_no_cross_contamination() {
    log_info "Checking for cross-contamination from other package managers..."
    
    # Scoop-specific files
    scoop_files=("bucket/" "*.json" "*.ps1" "Scoop-Bucket.Tests.ps1")
    for pattern in "${scoop_files[@]}"; do
        if find "${REPO_ROOT}" -name "$pattern" | grep -q .; then
            log_error "Found Scoop package manager files: $pattern"
        fi
    done
    
    # VSCode extension files
    vscode_files=("package.json" "src/extension.ts" "*.tmLanguage.json" ".vscodeignore")
    for pattern in "${vscode_files[@]}"; do
        if find "${REPO_ROOT}" -name "$pattern" | grep -q .; then
            log_error "Found VSCode extension files: $pattern"
        fi
    done
}

# Validate Formula content
validate_formula_content() {
    log_info "Validating Formula content..."
    
    local formula_file="${REPO_ROOT}/Formula/rxiv-maker.rb"
    
    if [[ -f "$formula_file" ]]; then
        # Check for required sections
        required_sections=("homepage" "url" "sha256" "depends_on" "def install" "def test")
        
        for section in "${required_sections[@]}"; do
            if grep -q "$section" "$formula_file"; then
                log_success "Formula contains required section: $section"
            else
                log_warning "Formula missing recommended section: $section"
            fi
        done
        
        # Validate Python dependency
        if grep -q 'depends_on "python@' "$formula_file"; then
            log_success "Formula has Python dependency"
        else
            log_error "Formula missing Python dependency"
        fi
        
        # Check for PyPI URL
        if grep -q "pypi.org" "$formula_file"; then
            log_success "Formula uses PyPI URL"
        else
            log_warning "Formula not using PyPI URL"
        fi
    fi
}

# Main execution
main() {
    cd "${REPO_ROOT}"
    
    log_info "Starting Homebrew repository integrity validation..."
    log_info "Repository root: ${REPO_ROOT}"
    
    validate_homebrew_structure
    validate_no_main_project_contamination
    validate_no_cross_contamination
    validate_formula_content
    
    echo
    if [[ $ERRORS -eq 0 ]]; then
        log_success "✅ All Homebrew repository validations passed successfully!"
        exit 0
    else
        log_error "❌ Found ${ERRORS} validation error(s). Repository integrity may be compromised."
        log_error "Please review the errors above and fix any issues before proceeding."
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi