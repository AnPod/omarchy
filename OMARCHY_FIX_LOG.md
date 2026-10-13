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

Issues screened by title/body: #14833, #10193, #14972, #12530, #11005, #13394, #12080, #15287, #11812, #15286, #14890, #6475, #14731, #15276, #8718, #15270, #11977, #15264, #11961, #13988, #13987, #13986, #13973, #13959, #13958, #13956, #13944, #13954, #13953, #13922, #13912, #13904, #12221, #13900, #13882, #13896, #13890, #13877, #15260, #13866, #13855, #12304, #15258, #13849, #13827, #13822, #13821, #12523, #13814, #10037, #13812, #13794, #13795, #13752, #13798, #13779, #13760, #13758, #13748, #13754

