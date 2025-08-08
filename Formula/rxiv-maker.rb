class RxivMaker < Formula
  desc "Automated LaTeX article generation with modern CLI and figure creation"
  homepage "https://github.com/HenriquesLab/rxiv-maker"
  url "https://files.pythonhosted.org/packages/a4/10/2a1f179173afe992af974c11177d52bf6aacfee65966ef01ba37a8dd8801/rxiv_maker-1.4.21.tar.gz"
  sha256 "7a0660bdb85a4c8753e99b51ab48fd7f2b4318d5ef2b4efb55b419077f80e4ca"
  license "MIT"

  depends_on "python"
  depends_on "pipx"
  depends_on "texlive"
  depends_on "node"

  def install
    # Set pipx environment to install in formula's prefix
    ENV["PIPX_HOME"] = libexec/"pipx"
    ENV["PIPX_BIN_DIR"] = bin
    
    # Install package via pipx using PyPI
    system "pipx", "install", "rxiv-maker==#{version}", "--pip-args=--no-cache-dir"
  end

  def uninstall
    # Remove rxiv-maker from pipx before Homebrew cleans up
    system "pipx", "uninstall", "rxiv-maker", "--verbose" if which("pipx")
  rescue StandardError
    # Ignore errors if pipx or package not found
    nil
  end

  def caveats
    <<~EOS
      rxiv-maker has been installed with all dependencies in an isolated virtual environment.

      The modern 'rxiv' CLI is now available. Quick start:
        rxiv check-installation        # Verify installation
        rxiv init MY_PAPER/           # Initialize a new manuscript
        rxiv pdf MY_PAPER/            # Generate PDF
        rxiv --help                   # Show all commands

      Advanced features:
        rxiv figures --force          # Regenerate all figures
        rxiv bibliography add DOI     # Add citation by DOI
        rxiv arxiv MY_PAPER/         # Prepare arXiv submission
        rxiv track-changes v1.0.0     # Track changes vs git tag

      Enable auto-completion:
        rxiv completion zsh           # Install for zsh
        rxiv completion bash          # Install for bash
        rxiv completion fish          # Install for fish

      Documentation: https://github.com/henriqueslab/rxiv-maker#readme
      VS Code Extension: https://github.com/HenriquesLab/vscode-rxiv-maker
    EOS
  end

  test do
    # Test that the CLI is working
    assert_match "version", shell_output("#{bin}/rxiv --version")

    # Test basic functionality
    system bin/"rxiv", "--help"

    # Test Python module import
    system libexec/"bin/python", "-c", "import rxiv_maker; print('Import successful')"
  end
end
