# Omarchy upstream fix log

Keep this branch separate from upstream fix PRs. Read and append each run; never force-push it.

## 2026-10-13 — initial immediate run

Upstream: omacom/omarchy, default branch quattro, fetched at 492b8837deea69663c7a5418871f07ed075a9686. Fork: AnPod/omarchy. Actor: AnPod. Cloud checkout: /workspace/omarchy. Read latest AGENTS.md, default/agents/skills/omarchy/contributing.md, command-metadata and migration guides, and testing reference. No separate contribution file or PR template was found. No explicit AI disclosure rule was found in these sources; updated PR descriptions disclose Codex assistance.

Reviewed all 109 open PRs by AnPod and their discussions/reviews before selecting work. Screened 60 recently updated open issues. This is screening coverage, not a declaration that every issue was reproduced or fully checked for duplicates.

### Ranked work selected (existing PR feedback)

| Rank | Issue / PR | Difficulty | Rationale |
| --- | --- | --- | --- |
| 1 | #13301 / #13608 | Easy | Narrow migration-only tolerance already implemented; verify timeout is attempted once, completion marker, and recovery command. |
| 2 | #13355 / #13602 | Medium | Review-requested permission handling and documentation; temporary ESP fixtures can reproduce the regression and exercise update orchestration safely. |

### Work and branches

- #13608: https://github.com/omacom/omarchy/pull/13608 — fork branch cursor/fix-migration-bar-put-best-effort-e0d3; local isolated branch daily/review-13608 and /workspace/omarchy-13608. Feedback from jandrusk was already implemented at 4083550d: no retries on timeout and only migration placement is best-effort. Merged latest upstream without rewriting history, verified focused test, and prepared an accurate PR description. No new implementation of the same issue was started.
- #13602: https://github.com/omacom/omarchy/pull/13602 — fork branch cursor/fix-update-esp-free-space-e0d3; local isolated branch daily/review-13602 and /workspace/omarchy-13602. Merged latest upstream without rewriting history. Commit 5763db06 warns when ESP/EFI search permissions hide UKIs and corrects the documented reserve formula. Added real permission regression using the actual helper and unprivileged cloud user.
- Original /workspace/omarchy work branch and files preserved. Upstream baseline at /workspace/omarchy-baseline. Persistent log on fork branch omarchy-daily-log.

### Verification

- ESP: bash test/shell.d/update-disk-space-test.sh passed all 16 checks, including both unsearchable-parent cases; bash -n and git diff --check passed.
- Ran the new permission test against the pre-fix helper: exit 1 because inaccessible EFI was mistaken for no UKIs and the helper used the 400 MiB floor. Restored the fixed helper and confirmed the test passed.
- Elsewhen: bash test/shell.d/elsewhen-migration-test.sh passed all 14 checks, including real bar-helper dispatch, one timeout attempt, manual recovery, real migration completion marker, legacy entry handling, and idempotence. bash -n and git diff --check passed.
- Required ./test/all completed with exit 1 on both updated branches and untouched upstream 492b8837. CLI and shell suites failed on all three. ESP branch: 56/398 shell test files failed; Elsewhen branch: 54/398 failed; upstream: 55/398 failed. All three had skipped checks in 44 test files (45 individual skip markers). These suites did not pass.
- Every failing test file on Elsewhen also failed on baseline (baseline additionally failed menu-images worker cleanup). ESP had the baseline's failure set plus hermes-remove-test.sh; the extra process-timing assertion passed when rerun in isolation, and the test/removal command are byte-identical to upstream. No remaining branch-specific failure was identified. Missing tools include lua, mise, socat, updatedb, pacman-conf, gawk, tmux, and gio; additional unchanged baseline assertions also fail.
- Logs: /workspace/13602-test-all.log, /workspace/13608-test-all.log, /workspace/upstream-test-all.log. These paths belong to this run's ephemeral workspace; persist relevant results here.
- No real Omarchy desktop, graphical session, Bluetooth hardware, ESP mount, boot-image build, or actual system package transaction was exercised. Fixtures verify script behavior, not live desktop/boot behavior.

### New issue screening and duplication

- #15287 (SUPER+J scrolling layout): inspected timeline and open PR search. Existing #6924 and #11863 implement fixes for togglesplit on scrolling workspaces. Skip new implementation.
- #15264 (FALLBACK output counted as external): timeline had no links, but separate open PR search found #15291, #10586, and #13749. Skip; this illustrates why an empty timeline alone is insufficient.
- #13986 (custom default browser silently replaced): read timeline and review. Multiple related PRs; honoring arbitrary wrappers needs a maintainer behavior decision. Skip pending clarification.
- #13754 (Synaptics 06cb:009a false positive): timeline identifies #15185 and #15080. Skip duplicate implementation.
- #13301: reviewed issue timeline and maintainer discussion; overlaps #12777, #12797 and own #13468. Update #13608 only; do not create another PR.
- #13355: reviewed issue timeline and maintainer discussion; related #11821 and own #13462. Update #13602 only; maintainer chooses the approach.
- Many existing PRs have overlap or product decisions. Do not close or merge them automatically; retain coordination findings.

### Next run

Prioritize unresolved feedback before new fixes. Check current heads and newer discussion before acting. Potential next review: #13908 validates resume-offset/device data in the hibernation setup; #13667 addresses Bluetooth restore/rfkill persistence but requires real hardware verification. #11574 has reported fetcher/security issues and deserves a dedicated review rather than a small daily change. #14022 overlaps other CLI/packaging fixes and awaits approach selection. Avoid the duplicate menu, monitor, browser, and scrolling fixes noted above.

### Access / runtime

Cloud environment ran with enforced restricted network policy. GitHub connector reads and Git fetch succeeded. Git push dry-run to the fork succeeded. gh auth status reported its GH_TOKEN invalid; use working Git transport and connected GitHub tools rather than replacing injected credentials. Scheduler run-now action returned 404 Action not found; this run was executed directly in the chat. Scheduled task remains configured for 19:00 Europe/Berlin.

### Submission result and exact blocker

- Pushed 5763db06 to cursor/fix-update-esp-free-space-e0d3: upstream PR #13602 now includes the permission fix, tests, documentation, and latest upstream merge.
- Pushed 5e97b018 to cursor/fix-migration-bar-put-best-effort-e0d3: upstream PR #13608 now includes the latest upstream merge. Existing scoped fix was reverified; no new timeout retry change was needed.
- No new PR opened; both existing upstream PRs were attached to the run. No merge, protected-branch push, release, or force-push performed.
- Updating either upstream PR description through github_update_pull_request failed with GitHub API 403: Resource not accessible by integration. The normal CLI fallback for #13602 failed with Post https://api.github.com/graphql: Forbidden. The original PR bodies therefore remain stale; do not claim these descriptions were published.
- Prepared complete problem/fix/verification/limitation/AI-disclosure descriptions are preserved in reports/2026-10-13-pr-13602.md and reports/2026-10-13-pr-13608.md on this log branch. Publish them when upstream PR metadata write access is available; do not redo the implementation. Code submission succeeded; PR-description updates remain blocked by integration permissions and CLI/API access.

### Review coverage

Open PR discussions reviewed: #15108, #14691, #14688, #14416, #14324, #14298, #14297, #14270, #14268, #14266, #14264, #14263, #14262, #14210, #14211, #14128, #14116, #14115, #14114, #14023, #14022, #13925, #13924, #13910, #13909, #13908, #13685, #13681, #13679, #13680, #13676, #13675, #13672, #13670, #13669, #13668, #13667, #13666, #13665, #13663, #13664, #13662, #13660, #13659, #13658, #13657, #13656, #13654, #13653, #13652, #13651, #13649, #13648, #13646, #13644, #13642, #13638, #13637, #13636, #13634, #13633, #13632, #13631, #13629, #13630, #13628, #13625, #13624, #13623, #13622, #13620, #13619, #13616, #13615, #13614, #13613, #13612, #13610, #13609, #13608, #13607, #13606, #13605, #13604, #13603, #13602, #13601, #13600, #13598, #13482, #13480, #13479, #13476, #13475, #13474, #13473, #13472, #13471, #13470, #13469, #13468, #13467, #13466, #13462, #13460, #13459, #11581, #11578, #11574

Issues screened by title/body: #14833, #10193, #14972, #12530, #11005, #13394, #12080, #15287, #11812, #15286, #14890, #6475, #14731, #11977, #15276, #15270, #8718, #15264, #11961, #13988, #13987, #13986, #13973, #13959, #13958, #13956, #13944, #13954, #13953, #13922, #13912, #13904, #12221, #13900, #13882, #13896, #13890, #13877, #15260, #13866, #13855, #12304, #15258, #13849, #13827, #13822, #13821, #12523, #13814, #10037, #13812, #13794, #13795, #13752, #13798, #13779, #13760, #13758, #13748, #13754

## 2026-10-13 — additional request: ten easy fixes with no PR

Requested ten additional easy issues without an existing PR or active implementation. The quality and duplication requirements remain binding. Outcome: **0 qualifying new fixes submitted**, shortfall 10. No eligible issue was established from this screening; this does not claim every possible fix was exhaustively reproduced.

Upstream rechecked: quattro remains 492b8837deea69663c7a5418871f07ed075a9686. Original checkout and all previous branches preserved. Reused cloud runtime/network instructions and the previously read contribution guides. Persistent log from the first run was reviewed first.

### Discovery coverage

- GitHub search returned 1,127 open issues matching `is:issue is:open -linked:pr`.
- Retrieved 1127 distinct results using pages 1–10 plus a date-partitioned older query to avoid GitHub's 1,000-result ceiling. Screened titles/bodies for plausible low-effort command, installer, migration, configuration, and documentation defects. Hardware-dependent and large architectural reports were excluded from the easy-fix shortlist.
- Inspected reports and issue timelines for 69 promising candidates, followed references, and searched open PRs by issue number and implementation keywords. The `-linked:pr` qualifier is not proof of no work: many reports link active fixes only in ordinary comments.
- No code changes, fix branches, commits, tests, or new PRs were manufactured to reach ten. This run was discovery/source validation, not implementation verification.

### Representative ranked screening (estimated effort before eligibility checks)

| Rank | Issue | Difficulty | Eligibility result |
| --- | --- | --- | --- |
| 1 | #5406 — manual typo | Trivial | Already fixed in current manual source and released tags. |
| 2 | #14574 — Ghostty background-color | Trivial | Shipped file has no offending key; maintainer asks about local modification. |
| 3 | #14724 — Brave Origin native messaging | Easy | Current upstream registers Brave-Origin in both host installers. |
| 4 | #14956 — numpad search input | Easy | Open fixes #8023 and #14662. |
| 5 | #14838 — Lua stdin assertions | Easy | Open PR #7460 fixes the same REPL/error-status problem; reporter also offered follow-up work. |
| 6 | #11283 — disabling unknown plugin | Easy | Open PR #11134; earlier report #11119 already has an implementation. |
| 7 | #14075 — duplicate keyboard layouts | Easy | Open PR #14076. |
| 8 | #11448 — DNS bridge/bond profile abort | Easy | Open PR #11476; live reproduction and verification already in that discussion. |
| 9 | #14887 — AUR updatedb scan | Easy–medium | Open PR #15178 addresses remote mounts; further behavior change needs scope judgment. |
| 10 | #14467 — OWE/LockFeed package conflict | Uncertain | Current package sources contradict the proposed simple removal; artifact/promotion investigation is necessary. Do not remove a required module speculatively. |

### Important source findings / remaining blockers

- #14467: current `omacom/omarchy-pkgs/pkgbuilds/owe/PKGBUILD` builds owe 0.2.10-4 through Meson. Tagged `omacom/owe/v0.2.10/meson.build` builds C render/daemon/CLI/test subdirectories, not qml-plugin. Separate `pkgbuilds/owe-lockfeed/PKGBUILD` builds 0.2.10-2 through CMake from qml-plugin and installs it separately. The current Omarchy base package list and migration asking for both are consistent with these sources. The issue's claim that the owe artifact owns the same QML files still needs artifact-level verification; no package artifact or real pacman transaction was tested. Removing owe-lockfeed without that evidence can remove the required QML module.
- #14849: accepted diagnosis of qmllint binary/import-path documentation, but the reported guide is plugins.omarchy.org/develop.html and was not found in this repository. Fix must target the guide's source, which has not been resolved here; no new helper/interface was invented.
- #11995: Inkscape chooser tiling is a plausible narrow rule fix with no PR found, but the reporter explicitly leaves the direction open and essential running-UI verification is unavailable in this cloud environment. Do not submit as ready.
- #15084: ISO passphrase/history-expansion diagnosis is hypothetical. Current target-side luks-rekey code sends secrets through key files/process substitution; installation orchestration belongs to the ISO. Needs exact invocation and a real disposable install reproduction, not a blind set +H patch.
- #11316: package corruption after interrupted extraction is a larger recovery/verification design problem, not an easy patch.
- #10405: plugin ID migration needs an accepted identity/state migration contract, not a small opportunistic change.
- #11757: Docker/resolved address collision is reproduced, but alternate-subnet/stub/removal/warning approaches await maintainer choice and overlap #11032.
- #7153: Spotify wrapper lives in omarchy-pkgs; whitespace splitting is a format decision and breaks values with spaces. Blank/comment handling could be a separate packaging fix after scope is accepted.
- #11233: theme backgrounds are deliberately read from staged snapshots; reading live directories or changing documentation awaits a maintainer decision.
- #9305: usage text has open PR #13976; direct-binary help behavior is an unresolved CLI design choice.
- #14623, #10117, #11399, #13179, #12821 and #12515 await clarification or fail to reproduce against upstream sources; do not claim these are ready bugs.
- #14787, #14414, #13994, #11004, #11916, #14205, #14463, #8184 and #6992 are already fixed on upstream or the reported mechanism does not hold there.
- #15198, #14429, #14086, #13122, #14069, #11628, #12029, #11992, #14833, #14197, #6053 and #8936 have existing related fixes/backports. Skip new implementation.

Submission access remains as recorded in the prior run: Git transport can push to the fork, but upstream PR metadata writes through the connected integration returned 403, and CLI GraphQL returned Forbidden. No new PR creation was attempted because no verified qualifying patch existed.

Next run: finish the previously blocked PR-description updates when permissions permit; revisit the Inkscape issue only with an accepted scope and graphical verification, and resolve the plugin-guide source if documentation work is desired. Do not repeat the skipped easy candidates above without checking for changed maintainer guidance.

Deep-reviewed issue IDs: #14838, #14849, #14887, #14787, #14733, #14724, #14574, #14467, #14459, #15306, #14956, #15084, #14908, #14623, #15198, #14124, #13994, #14414, #14375, #14075, #14086, #14197, #13122, #12846, #5406, #13179, #14429, #14339, #14069, #12515, #14119, #11283, #9305, #7153, #6992, #8184, #11757, #10940, #11448, #12029, #11628, #11995, #11474, #11004, #11231, #11257, #10117, #8936, #9385, #9532, #11175, #11607, #11916, #11233, #8711, #6053, #5546, #5879, #4921, #14604, #14205, #12381, #10405, #11316, #11399, #11992, #14833, #14463, #12821.
