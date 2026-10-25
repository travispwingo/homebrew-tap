class Plain < Formula
  include Language::Python::Virtualenv

  desc "Programming language written in everyday English"
  homepage "https://plain-lang.dev"
  url "https://files.pythonhosted.org/packages/d6/33/895046559754deed05154f9a711a4afdd6ab2b0090d129250ba4461277b7/plainlang-0.1.0.tar.gz"
  sha256 "87a0974614e17a7eda8473dcbe7eba25fd37bc633a3c625347564190e0133f4e"
  license "MIT"
  head "https://github.com/travispwingo/plain-lang.git", branch: "main"

  bottle do
    root_url "https://github.com/travispwingo/homebrew-tap/releases/download/plain-0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:  "c737fafe4f74efc883f5c2c38ab35e6b66d4280d582f09ee91f4cd3cd847b15a"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "076bac5018be1d94824ba47419566cccebe989b788b00ea02adf1cebf329a88b"
  end

  depends_on "python@3.15"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/plain --version")

    (testpath/"hello.plain").write <<~PLAIN
      show "Hello there!"
      set total to 2 plus 3
      show "2 plus 3 is {total}."
    PLAIN
    assert_equal "Hello there!\n2 plus 3 is 5.\n", shell_output("#{bin}/plain run hello.plain")

    (testpath/"broken.plain").write <<~PLAIN
      show "Hello there!
    PLAIN
    assert_match "broken.plain, line 1:", shell_output("#{bin}/plain check broken.plain 2>&1", 1)
  end
end
