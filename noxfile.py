"""Nox configuration for cross-platform testing of Homebrew formula.

Supports both Linux (via Podman containers) and macOS (native) testing.
"""

import os
import platform
import sys
import nox


def _command_exists(command):
    """Check if a command exists in the system PATH."""
    import shutil
    return shutil.which(command) is not None


@nox.session(name="test-linux")
def test_linux(session):
    """Test Homebrew formula installation on Linux using Podman."""
    # Check if Podman is available
    if not _command_exists("podman"):
        session.error("Podman is required for Linux testing but not found. Install Podman first.")
    
    session.log("Building Podman container for Linux testing...")
    
    # Build the container (optionally preinstall heavy deps)
    build_cmd = [
        "podman", "build",
        "-t", "homebrew-rxiv-maker-test",
        "-f", "test/Containerfile",
    ]
    if os.environ.get("PREINSTALL_DEPS") == "1":
        build_cmd += ["--build-arg", "PREINSTALL_DEPS=1"]
        if os.environ.get("PREINSTALL_SKIP_TEXLIVE") == "1":
            build_cmd += ["--build-arg", "PREINSTALL_SKIP_TEXLIVE=1"]
        session.log(
            "PREINSTALL_DEPS=1: caching Homebrew deps inside image"
            + (" (skipping texlive)" if os.environ.get("PREINSTALL_SKIP_TEXLIVE") == "1" else "")
        )
    build_cmd.append(".")
    session.run(*build_cmd, external=True)
    
    session.log("Running Homebrew formula test in Linux container...")
    
    # Run the test in the container
    # Use absolute path and handle SELinux context properly
    workspace_path = os.path.abspath(session.posargs[0] if session.posargs else '.')
    env_vars = []
    for var in ["FAST_MODE", "INSTALL_TIMEOUT", "PREINSTALL_DEPS", "PREINSTALL_SKIP_TEXLIVE"]:
        if var in os.environ:
            env_vars += ["-e", f"{var}={os.environ[var]}"]

    session.run(
        "podman", "run",
        "--rm",
        "--security-opt", "label=disable",
        "-v", f"{workspace_path}:/workspace:ro",
        *env_vars,
        "homebrew-rxiv-maker-test",
        external=True,
    )


@nox.session(name="test-linux-cleanup")
def test_linux_cleanup(session):
    """Clean up Podman containers and images from testing."""
    session.log("Cleaning up test containers and images...")
    
    # Remove test containers (ignore errors if none exist)
    session.run(
        "podman", "rm", "-f", "homebrew-rxiv-maker-test", 
        external=True,
        success_codes=[0, 1]  # Allow command to fail if container doesn't exist
    )
    
    # Remove test image (ignore errors if none exist)
    session.run(
        "podman", "rmi", "-f", "homebrew-rxiv-maker-test",
        external=True, 
        success_codes=[0, 1]  # Allow command to fail if image doesn't exist
    )
    
    # Prune unused images
    session.run(
        "podman", "image", "prune", "-f",
        external=True,
        success_codes=[0, 1]
    )


@nox.session(name="check-system")
def check_system(session):
    """Check system compatibility and prerequisites."""
    session.log("Checking system compatibility...")
    
    # System info
    session.log(f"Platform: {platform.system()} {platform.release()}")
    session.log(f"Architecture: {platform.machine()}")
    session.log(f"Python: {sys.version.split()[0]}")
    
    # Check required tools
    tools = {
        "brew": "Homebrew package manager",
        "git": "Git version control",
        "python3": "Python 3 interpreter"
    }
    
    missing_tools = []
    for tool, description in tools.items():
        if _command_exists(tool):
            session.log(f"✓ {tool}: {description}")
        else:
            session.log(f"✗ {tool}: {description} - NOT FOUND")
            missing_tools.append(tool)
    
    # Optional tools for full functionality
    optional_tools = {
        "podman": "Container runtime for Linux testing",
        "docker": "Alternative container runtime",
        "nox": "Testing automation"
    }
    
    for tool, description in optional_tools.items():
        if _command_exists(tool):
            session.log(f"✓ {tool}: {description} (optional)")
        else:
            session.log(f"- {tool}: {description} (optional, not found)")
    
    if missing_tools:
        session.error(f"Missing required tools: {', '.join(missing_tools)}")
    else:
        session.log("✓ All required tools are available")


@nox.session(name="test-local")
def test_local(session):
    """Test Homebrew formula locally on current system."""
    session.log(f"Testing Homebrew formula locally on {platform.system()}...")
    
    # Check prerequisites
    if not _command_exists("brew"):
        session.error("Homebrew is required but not found")
    
    # Platform-specific setup
    if platform.system() == "Darwin":
        session.log("Running on macOS - using native Homebrew")
    elif platform.system() == "Linux":
        session.log("Running on Linux - using Homebrew on Linux")
    else:
        session.warn(f"Untested platform: {platform.system()}")
    
    try:
        # Run local brew test
        session.run("brew", "test", "rxiv-maker", external=True)
        
        session.log("Testing rxiv-maker CLI functionality...")
        session.run("rxiv", "--version", external=True)
        session.run("rxiv", "--help", external=True)
        
    except Exception as e:
        session.error(f"Local testing failed: {e}")


@nox.session(name="validate-formula") 
def validate_formula(session):
    """Validate Homebrew formula syntax and style."""
    session.log(f"Validating formula syntax on {platform.system()}...")
    
    # Check prerequisites
    if not _command_exists("brew"):
        session.error("Homebrew is required for formula validation")
    
    # First validate syntax by attempting to install
    session.run(
        "brew", "install", "--build-from-source", "./Formula/rxiv-maker.rb",
        external=True
    )
    
    try:
        # Run audit - handle the case where audit by name is required
        session.log("Running brew audit...")
        session.run(
            "brew", "audit", "--strict", "rxiv-maker",
            external=True
        )
        
        # Style check can still work with path
        session.log("Running brew style...")
        session.run(
            "brew", "style", "Formula/rxiv-maker.rb", 
            external=True
        )
        
        session.log("✓ Formula validation passed")
        
    except Exception as e:
        session.error(f"Formula validation failed: {e}")
    finally:
        # Clean up
        session.run(
            "brew", "uninstall", "rxiv-maker",
            external=True,
            success_codes=[0, 1]
        )


@nox.session(name="install-test")
def install_test(session):
    """Install formula from source and test functionality."""
    session.log("Installing formula from source...")
    
    session.run(
        "brew", "install", "--build-from-source", "./Formula/rxiv-maker.rb",
        external=True
    )
    
    session.log("Testing installed formula...")
    session.run("brew", "test", "rxiv-maker", external=True)
    session.run("rxiv", "--version", external=True)
    session.run("rxiv", "check-installation", external=True)
    
    session.log("Cleaning up installation...")
    session.run("brew", "uninstall", "rxiv-maker", external=True, success_codes=[0, 1])


@nox.session(name="test-macos")
def test_macos(session):
    """Test Homebrew formula locally on macOS with comprehensive validation."""
    import platform
    
    if platform.system() != "Darwin":
        session.skip("macOS testing can only run on macOS")
    
    session.log("Testing Homebrew formula on macOS...")
    
    # Validate formula syntax and style first
    session.log("Validating formula syntax and style...")
    try:
        # Sync working copy formula into tap (so brew test picks up latest changes)
        try:
            session.log("Synchronizing formula into tap...")
            session.run(
                "bash", "-c",
                "cp ./Formula/rxiv-maker.rb $(brew --repo henriqueslab/rxiv-maker)/Formula/rxiv-maker.rb",
                external=True,
            )
        except Exception as e:
            session.log(f"Warning: formula sync failed: {e}")
        session.run("brew", "install", "--build-from-source", "./Formula/rxiv-maker.rb", external=True)
        session.run("brew", "audit", "--strict", "rxiv-maker", external=True)
        session.run("brew", "style", "Formula/rxiv-maker.rb", external=True)
        
        # Test functionality (skip 'brew test' due to sandbox termination issues)
        session.log("Testing rxiv-maker functionality...")
        session.log("Skipping 'brew test' (heavy runtime); performing direct CLI smoke tests instead...")
        session.run("rxiv", "--version", external=True)
        session.run("rxiv", "--help", external=True)
        session.run("rxiv", "check-installation", external=True)
        
        session.log("✓ macOS formula test passed")
    finally:
        # Always clean up
        session.log("Cleaning up macOS test installation...")
        session.run("brew", "uninstall", "rxiv-maker", external=True, success_codes=[0, 1])


@nox.session(name="performance-test")
def performance_test(session):
    """Benchmark formula installation performance."""
    import time
    
    session.log("Running performance benchmarks...")
    
    # Measure installation time
    start_time = time.time()
    session.run("brew", "install", "--build-from-source", "./Formula/rxiv-maker.rb", external=True)
    install_time = time.time() - start_time
    
    session.log(f"Installation completed in {install_time:.2f} seconds")
    
    # Test CLI responsiveness
    start_time = time.time()
    session.run("rxiv", "--version", external=True)
    version_time = time.time() - start_time
    
    start_time = time.time()
    session.run("rxiv", "--help", external=True)
    help_time = time.time() - start_time
    
    session.log(f"CLI version command: {version_time:.2f} seconds")
    session.log(f"CLI help command: {help_time:.2f} seconds")
    
    # Report performance summary
    session.log("=== Performance Summary ===")
    session.log(f"Total installation time: {install_time:.2f}s")
    session.log(f"CLI responsiveness: {max(version_time, help_time):.2f}s")
    
    # Cleanup
    session.log("Cleaning up performance test...")
    session.run("brew", "uninstall", "rxiv-maker", external=True, success_codes=[0, 1])