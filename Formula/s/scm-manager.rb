class ScmManager < Formula
  desc "Manage Git, Mercurial, and Subversion repos over HTTP"
  homepage "https://www.scm-manager.org"
  url "https://packages.scm-manager.org/repository/releases/sonia/scm/packaging/unix/2.46.0/unix-2.46.0.tar.gz"
  sha256 "be3b48b3c76ce42881399d97e512a3002ea3fcb917cf321ccc1f29081057516d"
  license all_of: ["Apache-2.0", "MIT"]

  livecheck do
    url "https://scm-manager.org/download/"
    regex(/href=.*?unix[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, all: "f90ff95286b4e579530ae143df6cf02585e9f8ddc21c212a8c1bb276a13e33c6"
  end

  depends_on "jsvc"
  depends_on "openjdk"

  def install
    # Replace pre-built `jsvc` with formula to add Apple Silicon support
    inreplace "bin/scm-server", %r{ \$BASEDIR/libexec/jsvc-.*"}, " #{Formula["jsvc"].opt_bin}/jsvc\""
    rm Dir["libexec/jsvc-*"]
    libexec.install Dir["*"]

    env = Language::Java.overridable_java_home_env
    env["BASEDIR"] = libexec
    env["REPO"] = libexec/"lib"
    (bin/"scm-server").write_env_script libexec/"bin/scm-server", env
  end

  service do
    run [opt_bin/"scm-server"]
  end

  test do
    port = free_port
    cp_r (libexec/"conf").children, testpath
    inreplace testpath/"server-config.xml" do |s|
      s.gsub! %r{<SystemProperty .*/>/work}, testpath/"work"
      s.gsub! "default=\"8080\"", "default=\"#{port}\""
    end
    ENV["JETTY_BASE"] = testpath
    pid = fork { exec bin/"scm-server" }
    sleep 30
    assert_match "<title>SCM-Manager</title>", shell_output("curl http://localhost:#{port}/scm/")
  ensure
    Process.kill "TERM", pid
  end
end
