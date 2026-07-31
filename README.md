# kylebrodeur/homebrew-tap

Homebrew formulas for machine-hygiene tooling on boxes that run fleets of AI coding agents.

```bash
brew tap kylebrodeur/tap

brew install wsl-optimize    # WSL2 (via Linuxbrew)
brew install mac-optimize    # macOS
```

| Formula | Platform | What it does |
|---|---|---|
| [`wsl-optimize`](https://github.com/kylebrodeur/wsl-optimize) | WSL2 | Memory + disk hygiene. WSL2 has two silent killers: the OOM killer reaps session plumbing while *protecting* the memory hogs, and the `ext4.vhdx` only ever grows. |
| [`mac-optimize`](https://github.com/kylebrodeur/mac-optimize) | macOS | Disk hygiene. The Mac equivalent of that slow death is disk exhaustion across a dozen caches that each look reasonable. |

Both are pure bash with no runtime dependencies, share
[`agent-machine-lib`](https://github.com/kylebrodeur/agent-machine-lib), and ship
agent-agnostic [Agent Skills](https://agentskills.io).

Each formula is platform-guarded (`depends_on :linux` / `:macos`) so the wrong one
cannot be installed by accident.

**Scheduled automation is not managed by Homebrew** — the systemd timers and launchd
agents need per-user materialisation. `brew info` prints the exact commands, or run
`make install` from a clone to have it done for you.

## License

MIT © 2026 Kyle Brodeur

## Releasing

1. Tag and release the tool repo: `git tag -a vX.Y.Z && git push origin vX.Y.Z && gh release create vX.Y.Z`
2. Get the tarball checksum:
   `curl -fsSL https://github.com/kylebrodeur/<repo>/archive/refs/tags/vX.Y.Z.tar.gz | sha256sum`
3. Update `url` and `sha256` in the formula, commit, push.
4. **Refresh your local tap clone before testing** — this bit me:

```bash
brew tap kylebrodeur/tap          # does NOT fetch if the clone already exists
git -C "$(brew --repository)/Library/Taps/kylebrodeur/homebrew-tap" pull   # this does
brew reinstall kylebrodeur/tap/<formula>
brew test kylebrodeur/tap/<formula>
```

`brew tap` on an existing clone silently reuses it, so a `reinstall` right after
pushing a formula change will happily build the **old** version and look like it
worked. Verify with `brew list --versions <formula>`.
