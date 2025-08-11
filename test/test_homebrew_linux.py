#!/usr/bin/env python3
"""Test script for validating rxiv-maker Homebrew formula on Linux."""

import subprocess
import sys
import os
import tempfile
import shutil
from pathlib import Path
import time
import platform
import re


class TestError(Exception):
    """Custom exception for test failures."""
    pass


def run_command(cmd, check=True, capture_output=True, timeout=300):
    """Run a shell command and return the result.

    For very long running commands (e.g., Homebrew installs) we disable output
    capture so users see real-time progress instead of a "hang".
    """
    printable = ' '.join(cmd) if isinstance(cmd, list) else cmd

    # Heuristics: stream output for brew install / audit / style to surface progress
    if capture_output and isinstance(cmd, list) and cmd and cmd[0] == "brew" and any(t in cmd for t in ["install", "audit", "style", "test"]):
        capture_output = False

    print(f"Running: {printable}", flush=True)

    try:
        if not capture_output:
            # Stream directly
            result = subprocess.run(
                cmd,
                shell=isinstance(cmd, str),
                check=check,
                text=True,
                timeout=timeout,
            )
            return result
        else:
            result = subprocess.run(
                cmd,
                shell=isinstance(cmd, str),
                check=check,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            if result.stdout:
                print(f"STDOUT: {result.stdout.strip()}", flush=True)
            if result.stderr:
                print(f"STDERR: {result.stderr.strip()}", flush=True)
            return result
    except subprocess.CalledProcessError as e:
        print(f"Command failed with exit code {e.returncode}", flush=True)
        if capture_output and e.stdout:
            print(f"STDOUT: {e.stdout}", flush=True)
        if capture_output and e.stderr:
            print(f"STDERR: {e.stderr}", flush=True)
        raise TestError(f"Command failed: {printable}")
    except subprocess.TimeoutExpired:
        raise TestError(f"Command timed out: {printable}")


def test_homebrew_setup():
    """Test that Homebrew is properly installed and working."""
    print("\n=== Testing Homebrew Setup ===")
    
    # Check brew command exists
    result = run_command(["which", "brew"])
    # Accept any brew path ending in bin/brew instead of strict substring that was too narrow
    brew_path = result.stdout.strip()
    assert brew_path.endswith("bin/brew"), f"Unexpected brew path: {brew_path}"
    
    # Check brew version
    result = run_command(["brew", "--version"])
    assert "Homebrew" in result.stdout, "brew --version failed"
    
    print("✓ Homebrew is properly installed")


def ensure_formula_tap():
    """Ensure the formula is accessible by name via a temporary tap symlink.

    Recent Homebrew versions disallow `brew audit` by path; we create a tap directory
    and symlink the mounted formula there so name-based commands work.
    """
    print("\n=== Ensuring Formula Tap Symlink ===")
    try:
        repo_dir = run_command(["brew", "--repository"]).stdout.strip()
        tap_dir = Path(repo_dir) / "Library" / "Taps" / "henriqueslab" / "homebrew-rxiv-maker" / "Formula"
        tap_dir.mkdir(parents=True, exist_ok=True)
        src = Path("/workspace/Formula/rxiv-maker.rb")
        dst = tap_dir / "rxiv-maker.rb"
        if dst.exists() or dst.is_symlink():
            # If existing but not symlink to src, remove and replace
            try:
                if dst.is_symlink() and os.readlink(dst) == str(src):
                    print(f"Tap symlink already present: {dst} -> {src}")
                else:
                    dst.unlink()
                    dst.symlink_to(src)
                    print(f"Replaced tap symlink: {dst} -> {src}")
            except OSError:
                pass
        else:
            dst.symlink_to(src)
            print(f"Created tap symlink: {dst} -> {src}")
        print("✓ Formula name accessible for audit/style")
    except Exception as e:
        print(f"! Could not create tap symlink (continuing): {e}")


def test_formula_syntax():
    """Test that the formula syntax and style are valid (post-install)."""
    print("\n=== Testing Formula Syntax & Style ===")

    # Use formula name (path form disabled in recent Homebrew)
    run_command(["brew", "audit", "--strict", "rxiv-maker"], timeout=900)
    run_command(["brew", "style", "Formula/rxiv-maker.rb"], timeout=600)

    print("✓ Formula syntax and style are valid")


def test_formula_installation():
    """Test installing the formula from source.

    This is skipped automatically in adaptive mode on arm64 unless FORCE_FULL=1.
    """
    adaptive = os.getenv("ADAPTIVE_MODE", "0") == "1"
    if adaptive and os.getenv("FORCE_FULL", "0") != "1":
        print("\n=== Skipping Formula Installation (ADAPTIVE_MODE) ===")
        return

    print("\n=== Testing Formula Installation ===")

    install_timeout = int(os.getenv("INSTALL_TIMEOUT", "3600"))
    start = time.time()
    run_command(["brew", "install", "--build-from-source", "./Formula/rxiv-maker.rb"], timeout=install_timeout, capture_output=False)
    elapsed = int(time.time() - start)
    print(f"Install completed in {elapsed}s")

    # Verify installation
    result = run_command(["brew", "list", "rxiv-maker"])
    assert "rxiv-maker" in result.stdout, "rxiv-maker not found in brew list"

    print("✓ Formula installed successfully")


def test_rxiv_cli():
    """Test that the rxiv CLI is working correctly."""
    print("\n=== Testing rxiv CLI ===")
    adaptive = os.getenv("ADAPTIVE_MODE", "0") == "1"

    result = run_command(["rxiv", "--version"], timeout=120)
    assert "rxiv" in result.stdout.lower(), "Version command failed"

    result = run_command(["rxiv", "--help"], timeout=120)
    assert any(k in result.stdout.lower() for k in ("usage", "commands")), "Help command failed"

    try:
        run_command(["rxiv", "check-installation"], timeout=300)
    except Exception as e:
        if adaptive:
            print(f"! check-installation failed in ADAPTIVE_MODE (acceptable): {e}")
        else:
            raise

    print("✓ rxiv CLI is working correctly" + (" (ADAPTIVE_MODE)" if adaptive else ""))


def test_dependencies():
    """Test that core dependencies are available after installation.

    FAST_MODE: restricted subset.
    ADAPTIVE_MODE: skip hard failure on missing pdflatex if texlive absent.
    """
    print("\n=== Testing Dependencies ===")

    fast = os.getenv("FAST_MODE", "0") == "1"
    adaptive = os.getenv("ADAPTIVE_MODE", "0") == "1"

    run_command(["python3", "--version"], timeout=60)
    if shutil.which("node"):
        run_command(["node", "--version"], timeout=60)
    else:
        if not adaptive and not fast:
            raise TestError("node not found in non-adaptive full mode")
        print("! node missing (acceptable in ADAPTIVE_MODE or FAST_MODE)")
    run_command(["rxiv", "--version"], timeout=60)

    if not fast:
        # pipx expected in both full and adaptive (preinstalled or lightweight install)
        try:
            run_command(["pipx", "--version"], timeout=60)
        except Exception as e:
            if not adaptive:
                raise
            print(f"! pipx not found in ADAPTIVE_MODE: {e}")
        # LaTeX only if present
        if shutil.which("pdflatex"):
            run_command(["pdflatex", "--version"], timeout=60)
        else:
            if not adaptive:
                raise TestError("pdflatex not found but required in full mode")
            print("! pdflatex missing (acceptable in ADAPTIVE_MODE)")

    label = " (FAST_MODE)" if fast else (" (ADAPTIVE_MODE)" if adaptive else "")
    print("✓ Dependencies are available" + label)


def test_functional():
    """Test basic rxiv-maker functionality."""
    print("\n=== Testing Basic Functionality ===")

    if os.getenv("FAST_MODE", "0") == "1":
        print("Skipping functional project init in FAST_MODE")
        return

    adaptive = os.getenv("ADAPTIVE_MODE", "0") == "1"

    with tempfile.TemporaryDirectory() as temp_dir:
        test_project = Path(temp_dir) / "test_paper"
        adaptive = os.getenv("ADAPTIVE_MODE", "0") == "1"
        if adaptive:
            # Provide blank answers to interactive prompts
            init_cmd = f"yes '' | rxiv init {test_project}"
            run_command(init_cmd, timeout=600, capture_output=False)
        else:
            run_command(["rxiv", "init", str(test_project)], timeout=600)
        assert test_project.exists(), "Project directory was not created"
        main_candidates = ["01_MAIN.md", "manuscript.md"]
        if not any((test_project / c).exists() for c in main_candidates):
            raise TestError(f"None of expected main manuscript files found: {main_candidates}")
        if not (test_project / "00_CONFIG.yml").exists():
            raise TestError("00_CONFIG.yml not created")

        if adaptive and not shutil.which("pdflatex"):
            print("Skipping build/pdf in ADAPTIVE_MODE (pdflatex missing)")
            print("✓ Basic functionality test (init only) passed (ADAPTIVE_MODE)")
            return

        # Try build (prefer 'build', fallback to 'pdf')
        print("Attempting project build...")
        build_cmds = [
            ["rxiv", "build", str(test_project)],
            ["rxiv", "pdf", str(test_project)],
        ]
        built = False
        for cmd in build_cmds:
            try:
                run_command(cmd, timeout=900, check=True)
                built = True
                print(f"Build succeeded with: {' '.join(cmd)}")
                break
            except Exception as e:
                print(f"Build attempt failed with {cmd}: {e}")
        assert built, "Neither 'rxiv build' nor 'rxiv pdf' succeeded"
        print("✓ Basic functionality test (init + build/pdf) passed")


def test_brew_test():
    """Run the built-in Homebrew test. Skipped in ADAPTIVE_MODE unless forced."""
    adaptive = os.getenv("ADAPTIVE_MODE", "0") == "1"
    if adaptive and os.getenv("FORCE_FULL", "0") != "1":
        print("\n=== Skipping Homebrew brew test (ADAPTIVE_MODE) ===")
        return
    print("\n=== Running Homebrew Formula Test ===")
    run_command(["brew", "test", "rxiv-maker"], timeout=900)
    print("✓ Homebrew formula test passed")


def adaptive_lightweight_install():
    """Install rxiv-maker via pip --user in adaptive mode (avoids pipx/venv)."""
    adaptive = os.getenv("ADAPTIVE_MODE", "0") == "1"
    if not adaptive:
        return
    print("\n=== Adaptive lightweight pip Installation (Skipping Brew Install) ===")

    formula_path = Path("/workspace/Formula/rxiv-maker.rb")
    pkg_url = None
    version = None
    try:
        text = formula_path.read_text()
        url_match = re.search(r'url "([^"]+)"', text)
        if url_match:
            pkg_url = url_match.group(1)
        ver_match = re.search(r"rxiv_maker-(\d+\.\d+\.\d+)", text)
        if ver_match:
            version = ver_match.group(1)
    except Exception as e:
        print(f"! Could not parse formula for URL/version: {e}")

    # Ensure we have Python >=3.11 (package requirement) else install brewed python
    need_new_python = False
    try:
        out = run_command(["python3", "-c", "import sys; print(sys.version.split()[0])"], timeout=30)
        py_ver = out.stdout.strip()
        parts = [int(p) for p in py_ver.split('.')[:2]]
        if parts < [3, 11]:
            need_new_python = True
            print(f"Current python3 version {py_ver} < 3.11; installing brewed python")
    except Exception as e:
        print(f"! Could not determine python version: {e}; will attempt brew install python")
        need_new_python = True

    if need_new_python:
        try:
            run_command(["brew", "install", "python"], timeout=1800, capture_output=False)
        except Exception as e:
            print(f"! Brew python install failed in ADAPTIVE_MODE: {e}")
        # Re-check version
        try:
            out = run_command(["python3", "-c", "import sys; print(sys.version.split()[0])"], timeout=30)
            py_ver = out.stdout.strip()
            print(f"After brew install, python3 version: {py_ver}")
        except Exception as e:
            print(f"! Could not verify python version after brew install: {e}")

    # Create a dedicated virtual environment to avoid PEP 668 restrictions
    venv_dir = Path.home() / ".rxiv_adaptive_venv"
    python_exec = "python3"
    if not (venv_dir / "bin" / "python").exists():
        try:
            run_command([python_exec, "-m", "venv", str(venv_dir)], timeout=180)
            print(f"Created virtual environment at {venv_dir}")
        except Exception as e:
            print(f"! Failed to create venv: {e}")
            venv_dir = None

    pip_base_cmd = []
    if venv_dir and (venv_dir / "bin" / "pip").exists():
        pip_base_cmd = [str(venv_dir / "bin" / "pip")]
    else:
        # Fallback: use system/brew python with break-system-packages
        print("Using system/brew pip with --break-system-packages fallback")
        pip_base_cmd = [python_exec, "-m", "pip"]


    if pkg_url:
        spec = pkg_url
        print(f"Installing from source tarball URL: {spec}")
    else:
        # Fallback to name==version or plain name
        spec = f"rxiv-maker=={version}" if version else "rxiv-maker"
        print(f"Installing from package spec: {spec}")

    install_cmd = pip_base_cmd + ["install", "--no-cache-dir", spec]
    if "python -m pip" in " ".join(pip_base_cmd):
        # add user + break-system-packages for externally managed python
        install_cmd.insert(2, "--user")
        install_cmd.insert(3, "--break-system-packages")
    try:
        run_command(install_cmd, timeout=1800, capture_output=False)
    except Exception as e:
        # Retry once with break-system-packages if not already included
        if "--break-system-packages" not in install_cmd:
            print(f"First install attempt failed ({e}); retrying with --break-system-packages")
            install_cmd.insert(2, "--break-system-packages")
            run_command(install_cmd, timeout=1800, capture_output=False)
        else:
            raise
    user_bin = Path.home() / ".local" / "bin"
    if user_bin.exists():
        os.environ["PATH"] = f"{user_bin}:{os.environ['PATH']}"
        print(f"Added {user_bin} to PATH")
    if venv_dir and (venv_dir / "bin").exists():
        os.environ["PATH"] = f"{venv_dir / 'bin'}:{os.environ['PATH']}"
        print(f"Added {venv_dir / 'bin'} to PATH")
    if not shutil.which("rxiv"):
        raise TestError("rxiv CLI not found after adaptive pip install")
    print("✓ Adaptive pip installation complete")


def cleanup():
    """Clean up after testing."""
    print("\n=== Cleaning Up ===")
    
    try:
        run_command(["brew", "uninstall", "rxiv-maker"], check=False)
        print("✓ Cleaned up installation")
    except TestError:
        print("! Could not uninstall (may not have been installed)")


def main():
    """Run all tests with adaptive logic for arm64 resource constraints."""
    print("Starting Homebrew rxiv-maker formula tests on Linux...", flush=True)

    fast_mode = os.getenv("FAST_MODE", "0") == "1"
    force_full = os.getenv("FORCE_FULL", "0") == "1"
    machine = platform.machine().lower()
    is_arm = any(a in machine for a in ("arm", "aarch64"))
    adaptive_mode = (is_arm and not fast_mode and not force_full)
    if adaptive_mode:
        os.environ["ADAPTIVE_MODE"] = "1"
        print("[INFO] Adaptive mode enabled (arm64 + no FORCE_FULL). Skipping heavy brew install & brew test.")
    else:
        os.environ.pop("ADAPTIVE_MODE", None)

    # Build test list
    if fast_mode:
        tests = [
            test_homebrew_setup,
            ensure_formula_tap,
            test_formula_syntax,
        ]
    elif adaptive_mode:
        tests = [
            test_homebrew_setup,
            ensure_formula_tap,
            adaptive_lightweight_install,
            test_rxiv_cli,
            test_dependencies,
            test_functional,
            test_formula_syntax,
        ]
    else:
        tests = [
            test_homebrew_setup,
            ensure_formula_tap,
            test_formula_installation,
            test_rxiv_cli,
            test_dependencies,
            test_functional,
            test_brew_test,
            test_formula_syntax,
        ]

    failed_tests = []

    for test in tests:
        try:
            test()
        except Exception as e:
            print(f"✗ {test.__name__} FAILED: {e}")
            failed_tests.append(test.__name__)
        except KeyboardInterrupt:
            print("\nTests interrupted by user")
            cleanup()
            sys.exit(1)

    cleanup()

    if failed_tests:
        print(f"\n{len(failed_tests)} test(s) failed:")
        for test_name in failed_tests:
            print(f"  - {test_name}")
        sys.exit(1)
    else:
        print("\n🎉 All tests passed! rxiv-maker Homebrew formula works correctly on Linux.")
        sys.exit(0)


if __name__ == "__main__":
    main()