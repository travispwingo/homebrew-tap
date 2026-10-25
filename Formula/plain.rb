class Plain < Formula
  include Language::Python::Virtualenv

  desc "Programming language written in everyday English"
  homepage "https://plain-lang.dev"
  url "https://files.pythonhosted.org/packages/d6/33/895046559754deed05154f9a711a4afdd6ab2b0090d129250ba4461277b7/plainlang-0.1.0.tar.gz"
  sha256 "87a0974614e17a7eda8473dcbe7eba25fd37bc633a3c625347564190e0133f4e"
  license "MIT"
  head "https://github.com/travispwingo/plain-lang.git", branch: "main"

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
