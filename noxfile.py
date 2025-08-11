"""Nox configuration for testing Homebrew formula with Podman."""

import os
import nox


@nox.session(name="test-linux")
def test_linux(session):
    """Test Homebrew formula installation on Linux using Podman."""
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


@nox.session(name="test-local")
def test_local(session):
    """Test Homebrew formula locally on current system."""
    session.log("Testing Homebrew formula locally...")
    
    # Run local brew test
    session.run(
        "brew", "test", "rxiv-maker",
        external=True
    )
    
    session.log("Testing rxiv-maker CLI functionality...")
    session.run("rxiv", "--version", external=True)
    session.run("rxiv", "--help", external=True)


@nox.session(name="validate-formula") 
def validate_formula(session):
    """Validate Homebrew formula syntax and style."""
    session.log("Validating formula syntax...")
    
    # First install the formula to make it available for audit
    session.run(
        "brew", "install", "--build-from-source", "./Formula/rxiv-maker.rb",
        external=True
    )
    
    try:
        session.run(
            "brew", "audit", "--strict", "rxiv-maker",
            external=True
        )
        
        session.run(
            "brew", "style", "Formula/rxiv-maker.rb", 
            external=True
        )
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
    session.run("brew", "uninstall", "rxiv-maker", external=True)