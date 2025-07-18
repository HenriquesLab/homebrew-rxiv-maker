class RxivMaker < Formula
  include Language::Python::Virtualenv

  desc "Automated LaTeX article generation with modern CLI and figure creation capabilities"
  homepage "https://github.com/henriqueslab/rxiv-maker"
  url "https://files.pythonhosted.org/packages/8e/e0/87fe31c8e57b8638077a945fb31dd3878201058b04f35a569ec5f2969e23/rxiv_maker-1.4.0.tar.gz"
  sha256 "15d9e9fbc1ad0ca42b6c64d487088fdaa0f365c3884781b918bf56af8787a2ed"
  license "MIT"

  depends_on "python@3.12"

  def install
    # Create virtual environment manually  
    system Formula["python@3.12"].opt_bin/"python3.12", "-m", "venv", libexec
    
    # Install the package with pip in the virtual environment
    system libexec/"bin/python", "-m", "pip", "install", buildpath
    
    # Create wrapper script for the CLI
    (bin/"rxiv").write_env_script(libexec/"bin/python", "-m", "rxiv_maker.cli")
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
    assert_match "version", shell_output("#{bin}/rxiv --version")
    
    # Test basic functionality
    system bin/"rxiv", "--help"
  end
end