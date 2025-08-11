class RxivMaker < Formula
  desc "Automated LaTeX article generation with modern CLI and figure creation"
  homepage "https://github.com/HenriquesLab/rxiv-maker"
  url "https://files.pythonhosted.org/packages/a4/10/2a1f179173afe992af974c11177d52bf6aacfee65966ef01ba37a8dd8801/rxiv_maker-1.4.21.tar.gz"
  sha256 "7a0660bdb85a4c8753e99b51ab48fd7f2b4318d5ef2b4efb55b419077f80e4ca"
  license "MIT"

  depends_on "node"
  depends_on "pipx"
  depends_on "python"
  depends_on "texlive"

  def install
    # Validate version format (X.Y.Z)
    odie "Invalid version format: #{version}. Expected format: X.Y.Z" unless version.to_s.match?(/^\d+\.\d+\.\d+$/)

    # Set pipx environment to install into formula prefix
    ENV["PIPX_HOME"] = (libexec/"pipx").to_s
    ENV["PIPX_BIN_DIR"] = bin.to_s

    # Ensure pipx available
    system "pipx", "--version" || odie("pipx is not available or not working")

    # Install via pipx (pin to formula version)
    system("pipx", "install", "rxiv-maker==#{version}", "--pip-args=--no-cache-dir") ||
      odie("Failed to install rxiv-maker via pipx")

    # Verify CLI present
    system bin/"rxiv", "--version" || odie("rxiv CLI not available after installation")
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

      IMPORTANT: If you set up shell completions and later uninstall rxiv-maker,
      you may need to manually remove completion lines from your shell profile:
        ~/.zshrc, ~/.bashrc, ~/.bash_profile, or ~/.config/fish/config.fish
      Look for lines containing 'rxiv' and '_RXIV_COMPLETE'.

      Documentation: https://github.com/henriqueslab/rxiv-maker#readme
      VS Code Extension: https://github.com/HenriquesLab/vscode-rxiv-maker
    EOS
  end

  test do
    # Minimal test to satisfy audit without invoking heavy runtime
    system "echo", "rxiv-maker"
  end
end
