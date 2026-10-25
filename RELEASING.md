# Releasing Plain

How a new version of Plain gets to PyPI (`plainlang`) and to this tap (`brew install travispwingo/tap/plain`).

The tap's workflows are the ones `brew tap-new` generates, with one change: `autobump.yml` also has a **Run workflow** button.

| Workflow | File | What it does |
| --- | --- | --- |
| brew test-bot | `.github/workflows/tests.yml` | On every pull request: builds, tests and bottles the formula on macOS 26 (Apple silicon) and Linux. On pushes to `main`: style and audit only. |
| brew pr-pull | `.github/workflows/publish.yml` | You start it by hand with a pull request number. It uploads that PR's bottles to a GitHub release in this repo, adds the `bottle do` block, pushes to `main` and closes the PR. |
| brew bump | `.github/workflows/autobump.yml` | Every day at 04:55 UTC (or when you press **Run workflow**): checks PyPI and opens a pull request when a newer `plainlang` is there. |

None of these needs a secret. They use the token GitHub gives every workflow run.

## Once: create the tap repository

1. Create an empty public repository named `homebrew-tap` under `travispwingo`. Don't add a README or license from GitHub's form.
2. In that repository, open **Settings > Actions > General > Workflow permissions** and tick **Allow GitHub Actions to create and approve pull requests**. The bump workflow can't open its pull requests without it.
3. Don't protect `main` with rules that stop GitHub Actions from pushing. The pr-pull workflow pushes the bottle commit straight to `main`.
4. Push everything in this folder except the formula. The formula goes in through a pull request in the first release below, so it gets built and tested before anyone can install it:

   ```sh
   cd path/to/homebrew-tap
   git init -b main
   git add README.md RELEASING.md .github
   git commit -m "Create travispwingo/tap tap"
   git remote add origin https://github.com/travispwingo/homebrew-tap.git
   git push -u origin main
   ```

## First release: 0.1.0

`pyproject.toml` and `src/plainlang/__init__.py` already say `0.1.0`.

1. **Tag and publish to PyPI.** In `plain-lang`, with `main` pushed and CI green:

   ```sh
   git tag -a v0.1.0 -m "Plain 0.1.0"
   git push origin v0.1.0
   ```

   The tag starts `.github/workflows/release.yml`, which builds the sdist and wheel and publishes them through trusted publishing. If you gave the `release` environment required reviewers, approve the run in the Actions tab.

2. **Wait for PyPI.** When https://pypi.org/project/plainlang/0.1.0/ loads, get the sdist's real URL and checksum:

   ```sh
   curl -fsSL https://pypi.org/pypi/plainlang/0.1.0/json | python3 -c 'import json, sys; s = next(u for u in json.load(sys.stdin)["urls"] if u["packagetype"] == "sdist"); print(s["url"]); print(s["digests"]["sha256"])'
   ```

   The first line looks like `https://files.pythonhosted.org/packages/ab/cd/<60 more hex digits>/plainlang-0.1.0.tar.gz`. Homebrew wants this full URL. Its audit rejects the short `/packages/source/p/plainlang/...` redirect form.

3. **Fill in the formula.** In `Formula/plain.rb`, put the first line in `url` and the second in `sha256`, and delete the `# PLACEHOLDER` comment above them. To double-check the checksum: `curl -fsSL "<url>" | shasum -a 256`.

4. **Open the pull request:**

   ```sh
   git switch -c plain-0.1.0
   git add Formula/plain.rb
   git commit -m "plain 0.1.0 (new formula)"
   git push -u origin plain-0.1.0
   gh pr create --fill
   ```

   **brew test-bot** runs on macOS and Linux. It installs the formula from source, runs its `test do` block (`plain --version` shows the version, a small program prints exactly `Hello there!` and `2 plus 3 is 5.`, and `plain check` on a broken file exits 1 and names the line) and saves bottles.

5. **Publish.** When both checks are green, go to **Actions > brew pr-pull > Run workflow**. Enter the pull request number and, for safety, the PR's head commit SHA (the last commit on its **Commits** tab, or `gh pr view <number> --json headRefOid --jq .headRefOid`). The workflow publishes bottles to a release named `plain-0.1.0`, adds the `bottle do` block, pushes to `main` and closes the PR.

   Don't press **Merge**. Publishing through brew pr-pull is what adds the bottles.

6. **Try it** on your Mac:

   ```sh
   brew install travispwingo/tap/plain
   plain --version
   brew test plain
   ```

## Every later release

The example is 0.1.1.

1. **Bump the version** in both places, in `plain-lang`:
   - `pyproject.toml`: `version = "0.1.1"`
   - `src/plainlang/__init__.py`: `__version__ = "0.1.1"`

   ```sh
   grep -n '^version\|__version__' pyproject.toml src/plainlang/__init__.py
   PYTHONPATH=src python3 -m unittest discover -s tests -t .
   git commit -am "Plain 0.1.1"
   git push
   ```

   Wait for CI to pass. A push to `main` also deploys plain-lang.dev.

2. **Tag:**

   ```sh
   git tag -a v0.1.1 -m "Plain 0.1.1"
   git push origin v0.1.1
   ```

   PyPI never accepts the same version twice. If you tagged without bumping, the upload fails. Delete the tag, bump the version and tag again.

3. **Wait for PyPI.** This prints the newest version PyPI has:

   ```sh
   curl -fsSL https://pypi.org/pypi/plainlang/json | python3 -c 'import json, sys; print(json.load(sys.stdin)["info"]["version"])'
   ```

4. **Let the tap update itself.** You don't need a secret for this:
   - Homebrew holds back any release less than 1 day old (its "release cooldown"). After that, the next daily **brew bump** run opens a pull request named `plain 0.1.1` with the new PyPI URL and checksum. Expect it 1 to 2 days after the release. Once the day has passed, you can start it sooner with **Actions > brew bump > Run workflow**, or `gh workflow run autobump.yml -R travispwingo/homebrew-tap`.
   - GitHub doesn't start other workflows for a pull request that a workflow opened with its built-in token. So **brew test-bot** won't start on its own. Close the pull request and reopen it (or run `gh pr close <n> && gh pr reopen <n>`). Reopening it yourself starts the tests.
   - When the checks are green, run **Actions > brew pr-pull** with the PR number and head SHA, as in the first release. Don't press **Merge**: that would leave the old version's `bottle do` block in the formula, and installs would fail looking for bottles that don't exist.

5. **Check:** `brew update && brew upgrade plain && plain --version`.

### Doing the tap update by hand

Use this if the bump workflow fails, or if you don't want to wait for it.

```sh
git -C path/to/homebrew-tap switch main
git -C path/to/homebrew-tap pull
curl -fsSL https://pypi.org/pypi/plainlang/0.1.1/json | python3 -c 'import json, sys; s = next(u for u in json.load(sys.stdin)["urls"] if u["packagetype"] == "sdist"); print(s["url"]); print(s["digests"]["sha256"])'
```

Put the two lines in `url` and `sha256` in `Formula/plain.rb`. Leave the `bottle do` block alone, because brew pr-pull replaces it. Then:

```sh
cd path/to/homebrew-tap
git switch -c plain-0.1.1
git commit -am "plain 0.1.1"
git push -u origin plain-0.1.1
gh pr create --fill
```

You pushed this one yourself, so brew test-bot starts on its own. When it's green, run **brew pr-pull** as above.

`brew bump-formula-pr --version=0.1.1 --no-fork travispwingo/tap/plain` does the same edit and pull request in one command. It uses your `gh` login, and it installs `python@3.15` first if you don't have it. Within the first day after a release, it can fail because of the same 1-day cooldown.

### Trying unreleased changes

`brew install --HEAD travispwingo/tap/plain` builds from `main` of `plain-lang`. The `plain --version` check in `brew test` fails on a HEAD build, because Homebrew calls that version `HEAD-<commit>`. That's expected.

## Later: moving to homebrew-core

When Plain is in homebrew-core, the install command becomes `brew install plain`. Homebrew's acceptance rules, from `docs/Package-Acceptance-Policy.md` and the `brew audit --new` checks in Homebrew 7.0.6:

- **Age.** The GitHub repository must be at least 30 days old. `travispwingo/plain-lang` was created on 2026-10-23. The homepage domain must also be registered for at least 30 days, and plain-lang.dev was registered on 2026-10-23. So 2026-11-22 is the earliest date.
- **Notability.** The repository needs at least one of: 30 forks, 30 watchers or 75 stars. If you submit it yourself as the repository owner, the bar is 90 forks, 90 watchers or 225 stars. Today all three are 0.
- **A stable release** with a versioned, checksummed source. The PyPI sdist covers this.
- **Name.** `plain` must not match an existing core formula, alias or cask when you submit. Check with `brew info plain` and `brew search plain`. Reviewers may ask for a different name, because another project called Plain (a Python web framework) also has a `plain` command.
- **No `bottle do` block** in a new core formula. Homebrew's own CI adds bottles.

Steps, following `docs/How-To-Open-a-Homebrew-Pull-Request.md`:

1. Fork `Homebrew/homebrew-core` on GitHub.
2. Set up the local copy:

   ```sh
   brew tap --force homebrew/core
   cd "$(brew --repository homebrew/core)"
   git remote add travispwingo https://github.com/travispwingo/homebrew-core.git
   brew update
   git checkout -b plain origin/HEAD
   ```

3. Copy this tap's `Formula/plain.rb` to `Formula/p/plain.rb` (core sorts formulae into folders by first letter). Delete its `bottle do ... end` block. Make sure `depends_on` names the Python that core uses at that time, `python@3.x`.
4. Test it. Remove the tap's copy first, because two formulae named `plain` can't be installed at once:

   ```sh
   brew uninstall plain
   HOMEBREW_NO_INSTALL_FROM_API=1 brew install --build-from-source plain
   brew test plain
   brew audit --new --strict --online plain
   brew lgtm --online
   ```

5. Commit and open the pull request:

   ```sh
   git add Formula/p/plain.rb
   git commit -m "plain 0.1.1 (new formula)"
   git push --set-upstream travispwingo plain
   ```

   Open the PR against `Homebrew/homebrew-core` and complete its checklist. Homebrew's AI rules apply. Say in the PR that you used AI and which tool. Review everything yourself. Don't add AI trailers to commits. Answer reviewers yourself.

6. After it's merged, retire the tap's copy with a pull request in this repo. Delete `Formula/plain.rb`, and add a `tap_migrations.json` containing `{ "plain": "homebrew/core" }`, with the commit message `plain: migrate to homebrew/core`. People who installed from the tap then move to the core formula on `brew update`. Change the install page to `brew install plain`.
