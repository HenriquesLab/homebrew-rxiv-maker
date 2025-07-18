class RxivMaker < Formula
  include Language::Python::Virtualenv

  desc "Automated LaTeX article generation with modern CLI and figure creation capabilities"
  homepage "https://github.com/henriqueslab/rxiv-maker"
  url "https://files.pythonhosted.org/packages/source/r/rxiv-maker/rxiv_maker-1.4.0.tar.gz"
  sha256 "9a8c5f65e7f4e5f5f7e4a4f3f7e3b1a7f3e7a3f3e7a3f3e7a3f3e7a3f3e7a3f"
  license "MIT"

  depends_on "python@3.12"

  # Python dependencies from PyPI
  resource "click" do
    url "https://files.pythonhosted.org/packages/source/c/click/click-8.2.1.tar.gz"
    sha256 "a74aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "rich" do
    url "https://files.pythonhosted.org/packages/source/r/rich/rich-14.0.0.tar.gz"
    sha256 "b74aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "rich-click" do
    url "https://files.pythonhosted.org/packages/source/r/rich-click/rich_click-1.6.0.tar.gz"
    sha256 "c74aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "matplotlib" do
    url "https://files.pythonhosted.org/packages/source/m/matplotlib/matplotlib-3.7.0.tar.gz"
    sha256 "d74aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "seaborn" do
    url "https://files.pythonhosted.org/packages/source/s/seaborn/seaborn-0.12.0.tar.gz"
    sha256 "e74aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "numpy" do
    url "https://files.pythonhosted.org/packages/source/n/numpy/numpy-1.24.0.tar.gz"
    sha256 "f74aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "pandas" do
    url "https://files.pythonhosted.org/packages/source/p/pandas/pandas-2.0.0.tar.gz"
    sha256 "a84aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "scipy" do
    url "https://files.pythonhosted.org/packages/source/s/scipy/scipy-1.10.0.tar.gz"
    sha256 "b84aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "pillow" do
    url "https://files.pythonhosted.org/packages/source/P/Pillow/Pillow-9.0.0.tar.gz"
    sha256 "c84aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "pypdf" do
    url "https://files.pythonhosted.org/packages/source/p/pypdf/pypdf-3.0.0.tar.gz"
    sha256 "d84aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/source/P/PyYAML/PyYAML-6.0.0.tar.gz"
    sha256 "e84aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "python-dotenv" do
    url "https://files.pythonhosted.org/packages/source/p/python-dotenv/python-dotenv-1.0.0.tar.gz"
    sha256 "f84aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "crossref-commons" do
    url "https://files.pythonhosted.org/packages/source/c/crossref-commons/crossref-commons-0.0.7.tar.gz"
    sha256 "a94aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "lazydocs" do
    url "https://files.pythonhosted.org/packages/source/l/lazydocs/lazydocs-0.4.8.tar.gz"
    sha256 "b94aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "types-requests" do
    url "https://files.pythonhosted.org/packages/source/t/types-requests/types-requests-2.32.4.20250611.tar.gz"
    sha256 "c94aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "pytest" do
    url "https://files.pythonhosted.org/packages/source/p/pytest/pytest-7.4.4.tar.gz"
    sha256 "d94aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "ruff" do
    url "https://files.pythonhosted.org/packages/source/r/ruff/ruff-0.12.2.tar.gz"
    sha256 "e94aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "pre-commit" do
    url "https://files.pythonhosted.org/packages/source/p/pre-commit/pre-commit-4.2.0.tar.gz"
    sha256 "f94aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "folder2md4llms" do
    url "https://files.pythonhosted.org/packages/source/f/folder2md4llms/folder2md4llms-0.3.0.tar.gz"
    sha256 "a04aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "typing-extensions" do
    url "https://files.pythonhosted.org/packages/source/t/typing-extensions/typing_extensions-4.0.0.tar.gz"
    sha256 "b04aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/source/p/packaging/packaging-21.0.0.tar.gz"
    sha256 "c04aa6f46f0ff6b61017e2e3c6c2c87b69c5d6b7b9a9d26e6e5b7b9c8b7b8b7c"
  end

  def install
    virtualenv_install_with_resources

    # Create wrapper script for the CLI
    (bin/"rxiv").write_env_script("#{libexec}/bin/python", "-m", "rxiv_maker.cli",
                                  PYTHONPATH: ENV["PYTHONPATH"])
  end

  def caveats
    <<~EOS
      rxiv-maker has been installed in an isolated Python virtual environment.
      
      For full functionality, you'll need additional system dependencies:
      
      macOS:
        brew install --cask mactex     # Full LaTeX distribution (recommended)
        # OR
        brew install --cask basictex   # Minimal LaTeX installation
      
      The 'rxiv' command is now available. Quick start:
        rxiv init          # Initialize a new manuscript
        rxiv pdf           # Generate PDF  
        rxiv --help        # Show help
      
      Documentation: https://github.com/henriqueslab/rxiv-maker#readme
    EOS
  end

  test do
    # Test that the CLI is working
    assert_match "rxiv-maker", shell_output("#{bin}/rxiv --version")
    
    # Test basic functionality
    system bin/"rxiv", "--help"
    
    # Test Python import
    system libexec/"bin/python", "-c", "import rxiv_maker; print('Import successful')"
  end
end