# The `integration` branch

This fork (`kdonbekci/sim-agentation`) runs from `integration`: upstream's `main` with every fix and feature branch of ours merged on top. Each change lives on its own branch so it can still go upstream as a PR on its own. `integration` itself is never sent upstream.

## Branches

| Branch | What it is |
|---|---|
| `main` | Upstream's `main` (`lcandy2/sim-agentation`), unchanged. Only ever fast-forwarded from `upstream/main`. |
| `fix/…`, `feat/…` | One change each, branched from `main`, with its own tests. These become upstream PRs. |
| `fork/publish` | This fork's own release workflow (`.github/workflows/fork-release.yml`), branched from `main`. Never sent upstream. It adds a file upstream doesn't have and changes none of theirs, so it never conflicts. |
| `integration` | `main` plus every open `fix/…` and `feat/…` branch, merged with `--no-ff`. What this machine runs. |

Merged into `integration` now:
- `fork/publish`: every push to `integration` is published as a release of this fork (see *Releases*).
- `fix/box-selection-contents`: box notes list the controls inside a bar that the accessibility tree had to probe.
- `fix/cli-help`: `--help`, `-h`, `--version` and `-v` answer instead of starting a server, and unknown arguments fail.

## Adding a change

```sh
git switch main && git switch -c fix/<name>       # or feat/<name>
# change, add a test, then:
pnpm build && swift test --package-path app/host
git push -u origin fix/<name>

git switch integration
git merge --no-ff fix/<name>
pnpm build && swift test --package-path app/host
git push
```

Update the "Merged into `integration` now" list above in the same merge. Branches that each add to `app/host/Package.swift` or `.github/workflows/ci.yml` conflict there. There is one `sim-agentationTests` target and one "Host unit tests" step; merge into those rather than adding a second.

## Taking in upstream

```sh
git fetch upstream
git switch main && git merge --ff-only upstream/main && git push
```

Then rebuild `integration` from the new `main`, so that its history stays one merge per branch:

```sh
git switch -C integration main
git merge --no-ff fork/publish
git merge --no-ff fix/box-selection-contents     # every branch in the list above, in order
git merge --no-ff fix/cli-help
pnpm build && swift test --package-path app/host
git push --force-with-lease
```

When upstream has taken one of our branches, drop it from the list and from the rebuild. `fork/publish` is never taken upstream; rebase it onto the new `main` only if it stops merging cleanly.

Push branches only, never tags (no `git push --tags`): a tag like `0.2.3` pushed to this fork runs upstream's Release workflow here, which publishes a release under upstream's name, takes Latest from ours, and fails in its Tap job, which needs upstream's secrets.

## Releases

Every push to `integration`, rebuilds included, runs *Fork release* (`.github/workflows/fork-release.yml`, from `fork/publish`): the same build and host unit tests as CI, then `app/scripts/package.sh`, published as a GitHub release of this fork marked Latest.

- The tag is `Config.version`, `-kd.` and the workflow's run number: `0.2.2-kd.7`. The workflow stamps it into `Config.version` in its own checkout, never in a commit, so the build reports it (`sim-agentation version`, and the MCP server's version) and the assets carry it: `sim-agentation-0.2.2-kd.7-macos-arm64.tar.gz` and its `.sha256`.
- Run numbers only grow, so tags stay unique and in order across force-pushes. Renaming the workflow file would start them again at 1, so don't. A re-run keeps its number; it skips a release that's already published.
- Each release's notes name the `integration` commit it was built from, and what's merged into it. Its tag keeps that commit on GitHub after the next force-push.
- Old releases stay. A tarball is under 1 MB, and the history is how to go back to an earlier build.
- Not a prerelease: mise's `latest` skips releases GitHub flags as prereleases.
- The tag doesn't match upstream's Release filter (`[0-9]+.[0-9]+.[0-9]+`), and a tag the workflow makes with its own token starts no other workflow, so neither Release nor Tap runs. Keep both turned off in this fork's Actions tab (⋯ → Disable workflow) against tags pushed by hand; that's a setting of the repo, not a change to their files.
- To publish again without a push: Actions → Fork release → Run workflow, on `integration`.
- Install the latest with mise: `mise use -g github:kdonbekci/sim-agentation`.

## Running it

```sh
pnpm install --frozen-lockfile    # once, and after the lockfile changes
pnpm build                        # web UI, then the debug host
app/host/.build/debug/sim-agentation serve --open
```

- The page is at `http://localhost:38470` (`SIM_AGENTATION_PORT` changes the port).
- Notes and screenshots live in `$TMPDIR/sim-agentation` (`SIM_AGENTATION_HOME` changes it). They're deleted only from the page, with Delete All or Clear finished.
- Agents connect with `app/host/.build/debug/sim-agentation mcp`.
  - When `mcp` can't reach a server, it starts one from its own binary.
  - To switch builds, stop the agent's `mcp` as well as the server, or the old build comes straight back.
  - Point every agent's MCP config at the build you mean to run.
- Taking input back from Xcode's Device Hub (`InputSurface.reclaim`: on request, and after a boot the server starts itself) restarts the simulator's backboardd and SpringBoard, which closes every open app.

## Checking a box note without the page

A box note can be created from a script, as the page does:
1. Ask for the tree over `ws://127.0.0.1:38470/ws/<udid>` with `{"type":"describe_ui"}` and wait for `describe_ui_result`.
2. POST it to `/api/annotations` with `kind: "area"`, the `rect` in points, `tree`, and base64 `full` and `crop` images.
3. Read the note back through `sim-agentation mcp` (`sim_get_pending`).

Run the same request against a server built from `main` on another port to compare the two.
