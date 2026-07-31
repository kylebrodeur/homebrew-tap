class WslOptimize < Formula
  desc "Memory and disk hygiene for a WSL2 box running many AI coding agents"
  homepage "https://github.com/kylebrodeur/wsl-optimize"
  url "https://github.com/kylebrodeur/wsl-optimize/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "31af1d8a5de33cac68d5a6cc7fb60fa374096d2c0b244b29722b00db2e9da7bf"
  license "MIT"
  head "https://github.com/kylebrodeur/wsl-optimize.git", branch: "main"

  # WSL2-only. Guarded rather than silently installing tools that would report
  # nothing useful on a Mac or a bare Linux box.
  depends_on :linux

  def install
    libexec.install "lib/common.sh"
    bin.install Dir["bin/*"]
    # The tools probe $AM_LIB first, then repo-relative, then known libdirs.
    # Point them at the Cellar copy so they work from any cwd.
    # Point the library resolver at the Cellar copy. Only three of the tools
    # reference AM_LIB, and Homebrew's inreplace RAISES when the pattern is
    # absent — so guard on the file actually containing it.
    bin.each_child do |f|
      next unless f.file?
      next unless f.read.include?('"${AM_LIB:-}"')
      inreplace f, '"${AM_LIB:-}"', %Q("${AM_LIB:-#{libexec}/common.sh}")
    end
    pkgshare.install "systemd", "skills", "TESTING.md", "README.md"
  end

  def caveats
    <<~EOS
      wsl-optimize targets WSL2 with systemd enabled. Verify with:
        wsl-optimize-doctor

      Homebrew does not manage the systemd user timers. To enable the automated
      safe-tier reclaim and the memory watcher:
        mkdir -p ~/.config/systemd/user
        for u in #{pkgshare}/systemd/*; do
          sed -e "s|__HOME__|$HOME|g" -e "s|__PATH__|$PATH|g" "$u" > ~/.config/systemd/user/$(basename "$u")
        done
        systemctl --user daemon-reload
        systemctl --user enable memguard.timer wsl-reclaim.timer
        systemctl --user restart memguard.timer wsl-reclaim.timer

      Note: enable --now will NOT reload a changed unit. Always restart.

      Agent Skills (agent-agnostic) live in #{pkgshare}/skills, or install with:
        npx skills add kylebrodeur/wsl-optimize
    EOS
  end

  test do
    assert_match "wslreport", shell_output("#{bin}/wslreport --help 2>&1", 1) rescue nil
    # The doctor is read-only and exits non-zero when the host is unconfigured,
    # so assert it RUNS and produces its own summary line rather than asserting
    # success — a fresh CI box legitimately fails several host checks.
    assert_match(/wsl-optimize: \d+ passed/, shell_output("#{bin}/wsl-optimize-doctor 2>&1", 1))
  end
end
