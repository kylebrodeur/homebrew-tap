class WslOptimize < Formula
  desc "Memory and disk hygiene for a WSL2 box running many AI coding agents"
  homepage "https://github.com/kylebrodeur/wsl-optimize"
  url "https://github.com/kylebrodeur/wsl-optimize/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "d6624fcb8bcc11fedb3aea110522a9ec0a87426a81444e56f1bb10039900366c"
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
    # --help must be fast and hermetic; it used to fall through to the full
    # report (which shells out to PowerShell) and hang the test.
    assert_match "wslreport", shell_output("#{bin}/wslreport --help")
    # shell_output raises unless the exit status matches, so this call IS the
    # assertion that an unknown option exits 2.
    assert_match "unknown option", shell_output("#{bin}/wslreport --bogus 2>&1", 2)
    # The doctor's exit status reflects the HOST's posture, not the install:
    # it exits 0 on a fully-configured machine and non-zero when host checks
    # fail. Asserting a specific status would make `brew test` pass or fail
    # depending on whose machine it runs on. `|| true` normalises it so the
    # assertion is about the tool RUNNING and emitting its summary.
    assert_match(/wsl-optimize: \d+ passed/, shell_output("#{bin}/wsl-optimize-doctor 2>&1 || true"))
    # worktree-audit must resolve the shared library from the Cellar, not only
    # from a repo checkout — an unresolved library made it silently classify
    # nothing during development.
    assert_match "worktree-audit", shell_output("#{bin}/worktree-audit --help 2>&1 || true")
  end
end
