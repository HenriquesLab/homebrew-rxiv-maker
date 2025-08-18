#!/bin/bash

# Performance metrics collection script for rxiv-maker Homebrew testing
# Collects system resource usage, timing data, and installation metrics

set -euo pipefail

# Configuration
METRICS_FILE="${METRICS_FILE:-performance-metrics.json}"
VERBOSE="${VERBOSE:-0}"
COLLECT_SYSTEM="${COLLECT_SYSTEM:-1}"
COLLECT_HOMEBREW="${COLLECT_HOMEBREW:-1}"
COLLECT_RXIV="${COLLECT_RXIV:-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[METRICS]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[METRICS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[METRICS]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[METRICS]${NC} $1" >&2
}

log_debug() {
    if [[ "${VERBOSE}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%dT%H:%M:%S%z'
}

# Get human readable timestamp
get_readable_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Initialize JSON metrics file
init_metrics_file() {
    local timestamp=$(get_timestamp)
    
    cat > "$METRICS_FILE" << EOF
{
  "metadata": {
    "collection_timestamp": "$timestamp",
    "collection_date": "$(get_readable_timestamp)",
    "hostname": "$(hostname 2>/dev/null || echo 'unknown')",
    "user": "$(whoami 2>/dev/null || echo 'unknown')",
    "platform": "$(uname -s 2>/dev/null || echo 'unknown')",
    "architecture": "$(uname -m 2>/dev/null || echo 'unknown')",
    "kernel": "$(uname -r 2>/dev/null || echo 'unknown')",
    "script_version": "1.0.0"
  },
  "system": {},
  "homebrew": {},
  "rxiv": {},
  "performance": {},
  "environment": {}
}
EOF
    
    log_debug "Initialized metrics file: $METRICS_FILE"
}

# Update JSON field using a simple approach (no jq dependency)
update_json_field() {
    local field="$1"
    local value="$2"
    local temp_file
    temp_file=$(mktemp)
    
    # Simple JSON field update - works for our structured data
    python3 -c "
import json
import sys

try:
    with open('$METRICS_FILE', 'r') as f:
        data = json.load(f)
    
    # Split field path and set nested value
    keys = '$field'.split('.')
    current = data
    for key in keys[:-1]:
        if key not in current:
            current[key] = {}
        current = current[key]
    
    # Handle different value types
    if '$value'.startswith('{') or '$value'.startswith('['):
        current[keys[-1]] = json.loads('$value')
    elif '$value'.lower() in ['true', 'false']:
        current[keys[-1]] = '$value'.lower() == 'true'
    elif '$value'.isdigit():
        current[keys[-1]] = int('$value')
    else:
        try:
            current[keys[-1]] = float('$value')
        except ValueError:
            current[keys[-1]] = '$value'
    
    with open('$METRICS_FILE', 'w') as f:
        json.dump(data, f, indent=2)

except Exception as e:
    print(f'Error updating JSON: {e}', file=sys.stderr)
    sys.exit(1)
" || {
        log_error "Failed to update JSON field: $field"
        return 1
    }
    
    log_debug "Updated field: $field = $value"
}

# Collect system information
collect_system_metrics() {
    if [[ "$COLLECT_SYSTEM" != "1" ]]; then
        return 0
    fi
    
    log_info "Collecting system metrics..."
    
    # CPU information
    local cpu_cores
    if command_exists nproc; then
        cpu_cores=$(nproc)
    elif [[ -f /proc/cpuinfo ]]; then
        cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    elif command_exists sysctl; then
        cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
    else
        cpu_cores="unknown"
    fi
    update_json_field "system.cpu_cores" "$cpu_cores"
    
    # CPU architecture details
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model
        cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs || echo "unknown")
        update_json_field "system.cpu_model" "$cpu_model"
    fi
    
    # Memory information
    local memory_total memory_available memory_used
    if command_exists free; then
        memory_total=$(free -b | awk '/^Mem:/ {print $2}')
        memory_available=$(free -b | awk '/^Mem:/ {print $7}')
        memory_used=$(free -b | awk '/^Mem:/ {print $3}')
    elif command_exists vm_stat && command_exists sysctl; then
        # macOS
        local page_size=$(vm_stat | grep "page size" | awk '{print $8}' | sed 's/\.//')
        local pages_total=$(sysctl -n hw.memsize)
        local pages_free=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
        memory_total="$pages_total"
        memory_available=$((pages_free * page_size))
        memory_used=$((memory_total - memory_available))
    else
        memory_total="unknown"
        memory_available="unknown"
        memory_used="unknown"
    fi
    
    update_json_field "system.memory_total_bytes" "$memory_total"
    update_json_field "system.memory_available_bytes" "$memory_available"
    update_json_field "system.memory_used_bytes" "$memory_used"
    
    # Disk space information
    local disk_total disk_available disk_used
    if command_exists df; then
        local disk_info
        disk_info=$(df -B1 . | tail -1)
        disk_total=$(echo "$disk_info" | awk '{print $2}')
        disk_used=$(echo "$disk_info" | awk '{print $3}')
        disk_available=$(echo "$disk_info" | awk '{print $4}')
    else
        disk_total="unknown"
        disk_used="unknown"
        disk_available="unknown"
    fi
    
    update_json_field "system.disk_total_bytes" "$disk_total"
    update_json_field "system.disk_used_bytes" "$disk_used"
    update_json_field "system.disk_available_bytes" "$disk_available"
    
    # Load average (if available)
    if command_exists uptime; then
        local load_avg
        load_avg=$(uptime | grep -oE 'load average[s]?: [0-9.]+, [0-9.]+, [0-9.]+' | awk -F': ' '{print $2}' || echo "unknown")
        update_json_field "system.load_average" "$load_avg"
    fi
    
    # OS version
    local os_version
    if [[ -f /etc/os-release ]]; then
        os_version=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    elif command_exists sw_vers; then
        os_version=$(sw_vers -productName)\ $(sw_vers -productVersion)
    else
        os_version="$(uname -s) $(uname -r)"
    fi
    update_json_field "system.os_version" "$os_version"
    
    log_success "System metrics collected"
}

# Collect Homebrew-specific metrics
collect_homebrew_metrics() {
    if [[ "$COLLECT_HOMEBREW" != "1" ]]; then
        return 0
    fi
    
    log_info "Collecting Homebrew metrics..."
    
    if ! command_exists brew; then
        log_warning "Homebrew not found - skipping Homebrew metrics"
        update_json_field "homebrew.available" "false"
        return 0
    fi
    
    update_json_field "homebrew.available" "true"
    
    # Homebrew version
    local brew_version
    brew_version=$(brew --version | head -1 | awk '{print $2}' 2>/dev/null || echo "unknown")
    update_json_field "homebrew.version" "$brew_version"
    
    # Homebrew prefix
    local brew_prefix
    brew_prefix=$(brew --prefix 2>/dev/null || echo "unknown")
    update_json_field "homebrew.prefix" "$brew_prefix"
    
    # Homebrew repository
    local brew_repo
    brew_repo=$(brew --repository 2>/dev/null || echo "unknown")
    update_json_field "homebrew.repository" "$brew_repo"
    
    # Cache size
    local cache_size cache_path
    cache_path=$(brew --cache 2>/dev/null || echo "")
    if [[ -d "$cache_path" ]]; then
        if command_exists du; then
            cache_size=$(du -sb "$cache_path" 2>/dev/null | awk '{print $1}' || echo "0")
        else
            cache_size="unknown"
        fi
    else
        cache_size="0"
    fi
    update_json_field "homebrew.cache_size_bytes" "$cache_size"
    update_json_field "homebrew.cache_path" "$cache_path"
    
    # Number of installed formulae
    local formulae_count
    formulae_count=$(brew list --formula 2>/dev/null | wc -l | xargs || echo "0")
    update_json_field "homebrew.installed_formulae_count" "$formulae_count"
    
    # Check if rxiv-maker is installed
    local rxiv_installed rxiv_version
    if brew list henriqueslab/rxiv-maker/rxiv-maker &>/dev/null; then
        rxiv_installed="true"
        rxiv_version=$(brew list --versions henriqueslab/rxiv-maker/rxiv-maker 2>/dev/null | awk '{print $2}' || echo "unknown")
    else
        rxiv_installed="false"
        rxiv_version="not_installed"
    fi
    update_json_field "homebrew.rxiv_maker_installed" "$rxiv_installed"
    update_json_field "homebrew.rxiv_maker_version" "$rxiv_version"
    
    log_success "Homebrew metrics collected"
}

# Collect rxiv-maker specific metrics
collect_rxiv_metrics() {
    if [[ "$COLLECT_RXIV" != "1" ]]; then
        return 0
    fi
    
    log_info "Collecting rxiv-maker metrics..."
    
    if ! command_exists rxiv; then
        log_warning "rxiv command not found - skipping rxiv metrics"
        update_json_field "rxiv.available" "false"
        return 0
    fi
    
    update_json_field "rxiv.available" "true"
    
    # rxiv version
    local rxiv_version
    rxiv_version=$(rxiv --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    update_json_field "rxiv.version" "$rxiv_version"
    
    # Check which rxiv
    local rxiv_path
    rxiv_path=$(which rxiv 2>/dev/null || echo "unknown")
    update_json_field "rxiv.executable_path" "$rxiv_path"
    
    # Test basic functionality timing
    local start_time end_time duration
    
    # Time version command
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    if timeout 30 rxiv --version &>/dev/null; then
        end_time=$(date +%s.%N 2>/dev/null || date +%s)
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        update_json_field "rxiv.version_command_duration" "$duration"
    else
        update_json_field "rxiv.version_command_duration" "timeout"
    fi
    
    # Time help command
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    if timeout 30 rxiv --help &>/dev/null; then
        end_time=$(date +%s.%N 2>/dev/null || date +%s)
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        update_json_field "rxiv.help_command_duration" "$duration"
    else
        update_json_field "rxiv.help_command_duration" "timeout"
    fi
    
    # Available commands
    local available_commands
    available_commands=$(rxiv --help 2>/dev/null | grep -E "^\s+[a-z-]+" | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' || echo "unknown")
    update_json_field "rxiv.available_commands" "$available_commands"
    
    # Check installation health (brief check)
    local health_check_result
    if timeout 60 rxiv check-installation --detailed &>/dev/null; then
        health_check_result="pass"
    else
        health_check_result="fail"
    fi
    update_json_field "rxiv.health_check_result" "$health_check_result"
    
    log_success "rxiv metrics collected"
}

# Collect performance timing data
collect_performance_metrics() {
    log_info "Collecting performance timing metrics..."
    
    # Test manuscript initialization timing
    local temp_dir
    temp_dir=$(mktemp -d)
    local start_time end_time duration
    
    if command_exists rxiv; then
        # Time manuscript initialization
        start_time=$(date +%s.%N 2>/dev/null || date +%s)
        if timeout 120 rxiv init "$temp_dir/test-perf" &>/dev/null; then
            end_time=$(date +%s.%N 2>/dev/null || date +%s)
            duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
            update_json_field "performance.manuscript_init_duration" "$duration"
        else
            update_json_field "performance.manuscript_init_duration" "timeout"
        fi
    fi
    
    # Clean up
    rm -rf "$temp_dir" 2>/dev/null || true
    
    # Memory usage patterns
    if command_exists free; then
        local memory_usage_percent
        memory_usage_percent=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
        update_json_field "performance.memory_usage_percent" "$memory_usage_percent"
    fi
    
    # Disk I/O timing (simple write test)
    local io_test_file
    io_test_file=$(mktemp)
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    dd if=/dev/zero of="$io_test_file" bs=1M count=10 &>/dev/null || true
    end_time=$(date +%s.%N 2>/dev/null || date +%s)
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    update_json_field "performance.disk_write_10mb_duration" "$duration"
    rm -f "$io_test_file" 2>/dev/null || true
    
    log_success "Performance metrics collected"
}

# Collect environment information
collect_environment_metrics() {
    log_info "Collecting environment metrics..."
    
    # PATH
    update_json_field "environment.path" "$PATH"
    
    # Shell
    update_json_field "environment.shell" "$SHELL"
    
    # Environment variables relevant to Homebrew
    update_json_field "environment.homebrew_prefix" "${HOMEBREW_PREFIX:-not_set}"
    update_json_field "environment.homebrew_no_auto_update" "${HOMEBREW_NO_AUTO_UPDATE:-not_set}"
    
    # Python version
    if command_exists python3; then
        local python_version
        python_version=$(python3 --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        update_json_field "environment.python_version" "$python_version"
    else
        update_json_field "environment.python_version" "not_available"
    fi
    
    # Node version
    if command_exists node; then
        local node_version
        node_version=$(node --version 2>/dev/null | sed 's/v//' || echo "unknown")
        update_json_field "environment.node_version" "$node_version"
    else
        update_json_field "environment.node_version" "not_available"
    fi
    
    # Git version
    if command_exists git; then
        local git_version
        git_version=$(git --version 2>/dev/null | awk '{print $3}' || echo "unknown")
        update_json_field "environment.git_version" "$git_version"
    else
        update_json_field "environment.git_version" "not_available"
    fi
    
    # CI environment detection
    local ci_environment="none"
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        ci_environment="github_actions"
        update_json_field "environment.github_runner_os" "${RUNNER_OS:-unknown}"
        update_json_field "environment.github_runner_arch" "${RUNNER_ARCH:-unknown}"
    elif [[ -n "${GITLAB_CI:-}" ]]; then
        ci_environment="gitlab_ci"
    elif [[ -n "${TRAVIS:-}" ]]; then
        ci_environment="travis"
    elif [[ -n "${CIRCLECI:-}" ]]; then
        ci_environment="circleci"
    fi
    update_json_field "environment.ci_environment" "$ci_environment"
    
    log_success "Environment metrics collected"
}

# Display metrics summary
display_metrics_summary() {
    if [[ ! -f "$METRICS_FILE" ]]; then
        log_error "Metrics file not found: $METRICS_FILE"
        return 1
    fi
    
    log_info "Metrics Summary:"
    echo "=================="
    
    # Extract key metrics using python
    python3 -c "
import json
try:
    with open('$METRICS_FILE', 'r') as f:
        data = json.load(f)
    
    print(f\"Collection Time: {data['metadata']['collection_date']}\")
    print(f\"Platform: {data['metadata']['platform']} {data['metadata']['architecture']}\")
    
    if 'system' in data:
        if 'cpu_cores' in data['system']:
            print(f\"CPU Cores: {data['system']['cpu_cores']}\")
        if 'memory_total_bytes' in data['system']:
            memory_gb = int(data['system']['memory_total_bytes']) / (1024**3)
            print(f\"Total Memory: {memory_gb:.1f} GB\")
    
    if 'homebrew' in data:
        if 'version' in data['homebrew']:
            print(f\"Homebrew Version: {data['homebrew']['version']}\")
        if 'rxiv_maker_installed' in data['homebrew']:
            status = 'Installed' if data['homebrew']['rxiv_maker_installed'] else 'Not Installed'
            print(f\"rxiv-maker Status: {status}\")
    
    if 'rxiv' in data:
        if 'version' in data['rxiv']:
            print(f\"rxiv Version: {data['rxiv']['version']}\")
        if 'health_check_result' in data['rxiv']:
            print(f\"Health Check: {data['rxiv']['health_check_result']}\")
    
    if 'performance' in data:
        if 'manuscript_init_duration' in data['performance']:
            duration = data['performance']['manuscript_init_duration']
            if duration != 'timeout':
                print(f\"Manuscript Init Time: {float(duration):.2f}s\")
    
except Exception as e:
    print(f'Error reading metrics: {e}')
" 2>/dev/null || log_warning "Could not display metrics summary"
    
    echo "=================="
    log_success "Metrics saved to: $METRICS_FILE"
}

# Main function
main() {
    log_info "Starting performance metrics collection..."
    
    # Initialize metrics file
    init_metrics_file
    
    # Collect different types of metrics
    collect_system_metrics
    collect_homebrew_metrics
    collect_rxiv_metrics
    collect_performance_metrics
    collect_environment_metrics
    
    # Display summary
    display_metrics_summary
    
    log_success "Performance metrics collection completed!"
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=1
            shift
            ;;
        --output|-o)
            METRICS_FILE="$2"
            shift 2
            ;;
        --no-system)
            COLLECT_SYSTEM=0
            shift
            ;;
        --no-homebrew)
            COLLECT_HOMEBREW=0
            shift
            ;;
        --no-rxiv)
            COLLECT_RXIV=0
            shift
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Options:
    --verbose, -v         Enable verbose output
    --output, -o FILE     Output metrics to FILE (default: performance-metrics.json)
    --no-system          Skip system metrics collection
    --no-homebrew        Skip Homebrew metrics collection
    --no-rxiv            Skip rxiv-maker metrics collection
    --help, -h           Show this help message

Environment Variables:
    METRICS_FILE         Output file for metrics (default: performance-metrics.json)
    VERBOSE              Enable verbose output (0/1)
    COLLECT_SYSTEM       Collect system metrics (0/1)
    COLLECT_HOMEBREW     Collect Homebrew metrics (0/1)
    COLLECT_RXIV         Collect rxiv-maker metrics (0/1)

Output:
    The script generates a JSON file with comprehensive metrics including:
    - System information (CPU, memory, disk)
    - Homebrew installation details
    - rxiv-maker functionality metrics
    - Performance timing data
    - Environment configuration
EOF
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Ensure we have required tools
if ! command_exists python3; then
    log_error "python3 is required but not found"
    exit 1
fi

# Run main function
main "$@"