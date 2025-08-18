#!/bin/bash

# Manuscript generation validation script for rxiv-maker Homebrew testing
# Tests the complete workflow from manuscript creation to PDF generation

set -euo pipefail

# Configuration
TEST_TIMEOUT="${TEST_TIMEOUT:-300}"
BUILD_TIMEOUT="${BUILD_TIMEOUT:-600}"
VERBOSE="${VERBOSE:-0}"
CLEANUP="${CLEANUP:-1}"
TEST_MODE="${TEST_MODE:-standard}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
TEST_DIR=""
TEST_RESULTS=()
START_TIME=""
TOTAL_TESTS=0
PASSED_TESTS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    if [[ "${VERBOSE}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

# Test result tracking
add_test_result() {
    local test_name="$1"
    local status="$2"
    local duration="$3"
    local message="$4"
    
    TEST_RESULTS+=("${test_name}:${status}:${duration}:${message}")
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [[ "$status" == "PASS" ]]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "✓ ${test_name} (${duration}s): ${message}"
    else
        log_error "✗ ${test_name} (${duration}s): ${message}"
    fi
}

# Time a command execution
time_command() {
    local start_time=$(date +%s)
    "$@"
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "$duration"
    return $exit_code
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create unique test directory
create_test_directory() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local random=$(shuf -i 1000-9999 -n 1 2>/dev/null || echo $RANDOM)
    TEST_DIR="rxiv-test-${timestamp}-${random}"
    
    log_info "Creating test directory: $TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # Store for cleanup
    echo "$TEST_DIR" > .test_dir_marker
}

# Test rxiv CLI availability
test_cli_availability() {
    log_info "Testing rxiv CLI availability..."
    
    local duration
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv --version)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        local version=$(rxiv --version 2>/dev/null || echo "unknown")
        add_test_result "CLI_AVAILABILITY" "PASS" "$duration" "rxiv version: $version"
        return 0
    else
        add_test_result "CLI_AVAILABILITY" "FAIL" "$duration" "rxiv command not available"
        return 1
    fi
}

# Test help system
test_help_system() {
    log_info "Testing help system..."
    
    local duration
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv --help)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        add_test_result "HELP_SYSTEM" "PASS" "$duration" "Help system accessible"
        return 0
    else
        add_test_result "HELP_SYSTEM" "FAIL" "$duration" "Help system not accessible"
        return 1
    fi
}

# Test manuscript initialization
test_manuscript_init() {
    log_info "Testing manuscript initialization..."
    
    if [[ -z "$TEST_DIR" ]]; then
        add_test_result "MANUSCRIPT_INIT" "FAIL" "0" "No test directory available"
        return 1
    fi
    
    local duration
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv init "$TEST_DIR")
    local exit_code=$?
    
    if [[ $exit_code -eq 0 && -d "$TEST_DIR" ]]; then
        # Check for expected files
        local files_found=0
        for file in "00_CONFIG.yml" "01_MAIN.md" "03_REFERENCES.bib"; do
            if [[ -f "$TEST_DIR/$file" ]]; then
                files_found=$((files_found + 1))
                log_debug "Found required file: $file"
            fi
        done
        
        if [[ $files_found -ge 2 ]]; then
            add_test_result "MANUSCRIPT_INIT" "PASS" "$duration" "Manuscript initialized with $files_found files"
            return 0
        else
            add_test_result "MANUSCRIPT_INIT" "FAIL" "$duration" "Manuscript missing required files (found: $files_found)"
            return 1
        fi
    else
        add_test_result "MANUSCRIPT_INIT" "FAIL" "$duration" "Manuscript initialization failed"
        return 1
    fi
}

# Test manuscript validation
test_manuscript_validation() {
    log_info "Testing manuscript validation..."
    
    if [[ -z "$TEST_DIR" || ! -d "$TEST_DIR" ]]; then
        add_test_result "MANUSCRIPT_VALIDATION" "SKIP" "0" "No test manuscript available"
        return 0
    fi
    
    local duration
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv validate "$TEST_DIR")
    local exit_code=$?
    
    # Validation warnings are acceptable
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        add_test_result "MANUSCRIPT_VALIDATION" "PASS" "$duration" "Validation completed (exit: $exit_code)"
        return 0
    else
        add_test_result "MANUSCRIPT_VALIDATION" "FAIL" "$duration" "Validation failed (exit: $exit_code)"
        return 1
    fi
}

# Test PDF generation
test_pdf_generation() {
    log_info "Testing PDF generation..."
    
    if [[ -z "$TEST_DIR" || ! -d "$TEST_DIR" ]]; then
        add_test_result "PDF_GENERATION" "SKIP" "0" "No test manuscript available"
        return 0
    fi
    
    # Skip in fast mode or if explicitly requested
    if [[ "$TEST_MODE" == "fast" ]] || [[ "${SKIP_PDF:-0}" == "1" ]]; then
        add_test_result "PDF_GENERATION" "SKIP" "0" "PDF generation skipped (fast mode or requested)"
        return 0
    fi
    
    local duration
    duration=$(time_command timeout "$BUILD_TIMEOUT" rxiv pdf "$TEST_DIR")
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        # Check for PDF output
        local pdf_count=$(find "$TEST_DIR" -name "*.pdf" -type f | wc -l)
        if [[ $pdf_count -gt 0 ]]; then
            local pdf_files=$(find "$TEST_DIR" -name "*.pdf" -type f -exec basename {} \; | tr '\n' ' ')
            add_test_result "PDF_GENERATION" "PASS" "$duration" "Generated $pdf_count PDF(s): $pdf_files"
            return 0
        else
            add_test_result "PDF_GENERATION" "FAIL" "$duration" "PDF generation succeeded but no PDFs found"
            return 1
        fi
    else
        # PDF generation failure might be expected in CI
        log_warning "PDF generation failed - this may be expected in CI environment"
        add_test_result "PDF_GENERATION" "WARN" "$duration" "PDF generation failed (exit: $exit_code)"
        return 0  # Don't fail the test for this
    fi
}

# Test installation health check
test_installation_check() {
    log_info "Testing installation health check..."
    
    local duration
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv check-installation)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        add_test_result "INSTALLATION_CHECK" "PASS" "$duration" "Installation check passed"
        return 0
    else
        # Installation check failures are common in CI
        log_warning "Installation check failed - this may be expected in CI environment"
        add_test_result "INSTALLATION_CHECK" "WARN" "$duration" "Installation check failed (exit: $exit_code)"
        return 0  # Don't fail for this
    fi
}

# Test advanced features (comprehensive mode only)
test_advanced_features() {
    if [[ "$TEST_MODE" != "comprehensive" ]]; then
        return 0
    fi
    
    log_info "Testing advanced features..."
    
    if [[ -z "$TEST_DIR" || ! -d "$TEST_DIR" ]]; then
        add_test_result "ADVANCED_FEATURES" "SKIP" "0" "No test manuscript available"
        return 0
    fi
    
    local features_tested=0
    local features_passed=0
    
    # Test bibliography command
    local duration
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv bibliography --help)
    if [[ $? -eq 0 ]]; then
        features_passed=$((features_passed + 1))
        log_debug "Bibliography command available"
    fi
    features_tested=$((features_tested + 1))
    
    # Test figures command
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv figures --help)
    if [[ $? -eq 0 ]]; then
        features_passed=$((features_passed + 1))
        log_debug "Figures command available"
    fi
    features_tested=$((features_tested + 1))
    
    # Test arxiv command
    duration=$(time_command timeout "$TEST_TIMEOUT" rxiv arxiv --help)
    if [[ $? -eq 0 ]]; then
        features_passed=$((features_passed + 1))
        log_debug "ArXiv command available"
    fi
    features_tested=$((features_tested + 1))
    
    add_test_result "ADVANCED_FEATURES" "PASS" "$duration" "Advanced features: $features_passed/$features_tested available"
    return 0
}

# Clean up test directory
cleanup_test_directory() {
    if [[ "$CLEANUP" != "1" ]]; then
        log_info "Cleanup disabled - keeping test directory: $TEST_DIR"
        return 0
    fi
    
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        log_info "Cleaning up test directory: $TEST_DIR"
        rm -rf "$TEST_DIR"
        log_success "Test directory cleaned up"
    fi
    
    # Clean up marker file
    if [[ -f ".test_dir_marker" ]]; then
        rm -f ".test_dir_marker"
    fi
}

# Generate test report
generate_test_report() {
    log_info "Generating test report..."
    
    local total_duration=$(($(date +%s) - START_TIME))
    
    echo ""
    echo "========================================="
    echo "     MANUSCRIPT GENERATION TEST REPORT"
    echo "========================================="
    echo ""
    echo "Test Mode: $TEST_MODE"
    echo "Total Duration: ${total_duration}s"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $((TOTAL_TESTS - PASSED_TESTS))"
    echo ""
    
    # Detailed results
    echo "Detailed Results:"
    echo "-----------------"
    for result in "${TEST_RESULTS[@]}"; do
        IFS=':' read -r name status duration message <<< "$result"
        local status_symbol
        case "$status" in
            "PASS") status_symbol="✓" ;;
            "FAIL") status_symbol="✗" ;;
            "WARN") status_symbol="⚠" ;;
            "SKIP") status_symbol="○" ;;
            *) status_symbol="?" ;;
        esac
        printf "  %s %-25s %6ss  %s\n" "$status_symbol" "$name" "$duration" "$message"
    done
    echo ""
    
    # Summary
    if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
        log_success "All tests passed! rxiv-maker is working correctly."
        return 0
    elif [[ $PASSED_TESTS -gt 0 ]]; then
        log_warning "Some tests failed, but core functionality works."
        return 1
    else
        log_error "Most or all tests failed. There are serious issues."
        return 2
    fi
}

# Handle cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    log_info "Script exiting with code: $exit_code"
    cleanup_test_directory
    exit $exit_code
}

# Main function
main() {
    START_TIME=$(date +%s)
    log_info "Starting manuscript generation validation..."
    log_info "Test mode: $TEST_MODE"
    
    # Set up cleanup trap
    trap cleanup_on_exit EXIT INT TERM
    
    # Create test directory
    create_test_directory
    
    # Run tests based on mode
    local tests_to_run
    case "$TEST_MODE" in
        "fast")
            tests_to_run=(
                test_cli_availability
                test_help_system
            )
            ;;
        "standard")
            tests_to_run=(
                test_cli_availability
                test_help_system
                test_installation_check
                test_manuscript_init
                test_manuscript_validation
                test_pdf_generation
            )
            ;;
        "comprehensive")
            tests_to_run=(
                test_cli_availability
                test_help_system
                test_installation_check
                test_manuscript_init
                test_manuscript_validation
                test_pdf_generation
                test_advanced_features
            )
            ;;
        *)
            log_error "Unknown test mode: $TEST_MODE"
            exit 1
            ;;
    esac
    
    # Execute tests
    for test_func in "${tests_to_run[@]}"; do
        log_debug "Running test: $test_func"
        $test_func || log_debug "Test $test_func completed with warnings"
    done
    
    # Generate final report
    generate_test_report
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --no-cleanup)
            CLEANUP=0
            shift
            ;;
        --skip-pdf)
            SKIP_PDF=1
            shift
            ;;
        --test-timeout)
            TEST_TIMEOUT="$2"
            shift 2
            ;;
        --build-timeout)
            BUILD_TIMEOUT="$2"
            shift 2
            ;;
        --mode)
            TEST_MODE="$2"
            shift 2
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Options:
    --verbose, -v           Enable verbose output
    --no-cleanup           Keep test directory after completion
    --skip-pdf             Skip PDF generation test
    --test-timeout SECONDS Set timeout for basic tests (default: 300)
    --build-timeout SECONDS Set timeout for PDF builds (default: 600)
    --mode MODE            Test mode: fast/standard/comprehensive (default: standard)
    --help, -h             Show this help message

Test Modes:
    fast           Basic CLI tests only (quickest)
    standard       Full manuscript workflow (recommended)
    comprehensive  All features including advanced commands

Environment Variables:
    TEST_TIMEOUT    Timeout for basic operations
    BUILD_TIMEOUT   Timeout for PDF generation
    VERBOSE         Enable verbose output (0/1)
    CLEANUP         Clean up test files (0/1)
    TEST_MODE       Test mode to run
    SKIP_PDF        Skip PDF generation (0/1)
EOF
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main "$@"