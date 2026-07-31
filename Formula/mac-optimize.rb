class MacOptimize < Formula
  desc "Disk and shell hygiene for a Mac running many AI coding agents"
  homepage "https://github.com/kylebrodeur/mac-optimize"
  url "https://github.com/kylebrodeur/mac-optimize/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "80640524c085a17d348559bf00bb907c390a09f296a8e82e6a7e620d415b93b3"
  license "MIT"
  head "https://github.com/kylebrodeur/mac-optimize.git", branch: "main"

  depends_on :macos

  def install
    libexec.install "lib/common.sh"
    bin.install Dir["bin/*"]
    # Point the library resolver at the Cellar copy. Only three of the tools
    # reference AM_LIB, and Homebrew's inreplace RAISES when the pattern is
    # absent — so guard on the file actually containing it.
    bin.each_child do |f|
      next unless f.file?
      next unless f.read.include?('"${AM_LIB:-}"')
      inreplace f, '"${AM_LIB:-}"', %Q("${AM_LIB:-#{libexec}/common.sh}")
    end
    pkgshare.install "launchd", "skills", "TESTING.md", "README.md"
  end

  def caveats
    <<~EOS
      Verify the install with:
        mac-optimize-doctor

      Homebrew does not manage launchd agents. To enable the disk watcher and the
      weekly reclaim, materialise the templates (they contain __HOME__/__PATH__
      placeholders) and bootstrap them:
        for p in #{pkgshare}/launchd/*.plist; do
          d=~/Library/LaunchAgents/$(basename "$p")
          sed -e "s|__HOME__|$HOME|g" -e "s|__PATH__|$PATH|g" "$p" > "$d"
          launchctl bootout gui/$(id -u)/$(basename "$p" .plist) 2>/dev/null || true
          launchctl bootstrap gui/$(id -u) "$d"
        done

      Agent Skills (agent-agnostic) live in #{pkgshare}/skills, or install with:
        npx skills add kylebrodeur/mac-optimize
    EOS
  end

  test do
    # The doctor's exit status reflects the HOST's posture, not the install: it
    # exits 0 on a fully-configured machine and non-zero when host checks fail.
    # Asserting a specific status would make `brew test` pass or fail depending
    # on whose machine it runs on. `|| true` normalises it, so the assertion is
    # about the tool RUNNING and emitting its own summary line.
    assert_match(/mac-optimize: \d+ passed/, shell_output("#{bin}/mac-optimize-doctor 2>&1 || true"))
    # worktree-audit must resolve the shared library from the Cellar, not only
    # from a repo checkout — an unresolved library made it silently classify
    # nothing on the WSL side.
    assert_match "worktree-audit", shell_output("#{bin}/worktree-audit --help 2>&1 || true")
  end
end
