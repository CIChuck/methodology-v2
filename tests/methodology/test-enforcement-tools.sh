#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
helpers="$script_dir/lib/test-helpers.sh"

. "$helpers"

th_set_suite "enforcement-tools"
th_set_keep_on_failure "${TH_KEEP_ON_FAILURE:-0}"
th_require_compatible_bash
th_init_suite
trap th_cleanup EXIT

base_repo="$TH_WORKDIR/base"
th_temp_copy "$repo_root" "$base_repo"
(
  cd "$base_repo"
  git init -q
  git config user.name "Methodology Test"
  git config user.email "methodology-test@example.com"
  git add -A >/dev/null
  git commit --allow-empty -qm "enforcement fixture base"
)

th_run_case "EN-001" 0 "check-methodology reports uninitialized state" \
  "cd '$base_repo' && ./scripts/check-methodology.sh" \
  'project is not initialized'

th_run_case "EN-002" 0 "check-methodology detects placeholder placeholders from checker" \
  "cd '$base_repo' && ./scripts/test-checker.sh" \
  '[0-9]+ passed, 0 failed'

th_run_case "EN-003" 0 "methodology-guard accepts --help" \
  "cd '$base_repo' && ./scripts/methodology-guard.sh --help" \
  'Usage:'

init_target="$TH_WORKDIR/init_target"
mkdir -p "$init_target"
cp -R "$base_repo/." "$init_target"
cd "$init_target"
./scripts/init-project.sh "Enforcement Fixtures" > /dev/null
mkdir -p src
perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml
git add -f docs/project src >/dev/null 2>&1 || true

th_run_case "EN-004" 0 "methodology-guard runs in staged mode" \
  "cd '$init_target' && git add -f docs/project/vision/vision.md >/dev/null 2>&1 || true; ./scripts/methodology-guard.sh --staged" \
  'Methodology check passed:'

th_run_case "EN-004A" 0 "methodology-guard --staged ignores unstaged worktree drift" \
  "fixture='$TH_WORKDIR/staged-leak'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G2/m; s/^    gate: G1$/    gate: G2/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G2' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G2' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Methodology-guard staged snapshot fixture' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  perl -0pi -e 's/^  current_gate: G2$/  current_gate: G1/m; s/^    gate: G2$/    gate: G1/m' docs/project/project.yaml; \
  ./scripts/methodology-guard.sh --staged" \
  'Methodology check passed:'

th_run_case "EN-014" 0 "install-hooks installs wrapper in repository path with spaces" \
  "fixture='$TH_WORKDIR/hook path with spaces'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  ./scripts/install-hooks.sh >/dev/null; \
  test -x \"\$(git rev-parse --git-path hooks/pre-commit)\"" \
  ''

th_run_case "EN-015" 0 "install-hooks preserves existing hook and runs it once" \
  "fixture='$TH_WORKDIR/hook-preserve'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  hook=\"\$(git rev-parse --git-path hooks/pre-commit)\"; \
  mkdir -p \"\$(dirname \"\$hook\")\"; \
  printf '%s\n' '#!/usr/bin/env bash' 'printf x >> preserved-count' > \"\$hook\"; \
  chmod +x \"\$hook\"; \
  ./scripts/install-hooks.sh >/dev/null; \
  \"\$hook\" >/dev/null; \
  test \"\$(cat preserved-count)\" = x" \
  ''

th_run_case "EN-016" 7 "install-hooks propagates preserved hook failure" \
  "fixture='$TH_WORKDIR/hook-preserved-fails'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  hook=\"\$(git rev-parse --git-path hooks/pre-commit)\"; \
  mkdir -p \"\$(dirname \"\$hook\")\"; \
  printf '%s\n' '#!/usr/bin/env bash' 'exit 7' > \"\$hook\"; \
  chmod +x \"\$hook\"; \
  ./scripts/install-hooks.sh >/dev/null; \
  \"\$hook\"" \
  ''

th_run_case "EN-017" 6 "install-hooks propagates GenDev guard failure" \
  "fixture='$TH_WORKDIR/hook-guard-fails'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  ./scripts/install-hooks.sh >/dev/null; \
  printf '%s\n' '#!/usr/bin/env bash' 'exit 6' > scripts/methodology-guard.sh; \
  chmod +x scripts/methodology-guard.sh; \
  \"\$(git rev-parse --git-path hooks/pre-commit)\"" \
  ''

th_run_case "EN-018" 0 "install-hooks reinstall is idempotent and uninstall restores original" \
  "fixture='$TH_WORKDIR/hook-uninstall'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  hook=\"\$(git rev-parse --git-path hooks/pre-commit)\"; \
  mkdir -p \"\$(dirname \"\$hook\")\"; \
  printf '%s\n' '#!/usr/bin/env bash' 'echo original-hook' > \"\$hook\"; \
  chmod 755 \"\$hook\"; \
  cp \"\$hook\" original.expected; \
  ./scripts/install-hooks.sh >/dev/null; \
  ./scripts/install-hooks.sh >/dev/null; \
  ./scripts/install-hooks.sh --uninstall >/dev/null; \
  cmp -s \"\$hook\" original.expected && test -x \"\$hook\"" \
  ''

th_run_case "EN-019" 0 "install-hooks resolves custom core.hooksPath" \
  "fixture='$TH_WORKDIR/hook-custom-path'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  git config core.hooksPath .githooks; \
  ./scripts/install-hooks.sh >/dev/null; \
  test -x .githooks/pre-commit" \
  ''

th_run_case "EN-020" 1 "install-hooks fails closed when guard is missing" \
  "fixture='$TH_WORKDIR/hook-no-guard'; \
  rm -rf \"\$fixture\"; \
  cp -R '$init_target/.' \"\$fixture\"; \
  cd \"\$fixture\"; \
  rm -f scripts/methodology-guard.sh; \
  ./scripts/install-hooks.sh" \
  'Required executable missing'

th_run_case "EN-005" 0 "methodology-guard --range passes when a new exact gate transition is appended" \
  "fixture='$TH_WORKDIR/range-pass'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 Range Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T006: base without gate movement'; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G2/m; s/^    gate: G1$/    gate: G2/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G2' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G2' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Test fixture recorded matching transition for range enforcement.' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T006: add matching transition'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'Methodology check passed:'

th_run_case "EN-006" 1 "methodology-guard --range fails when gate movement lacks exact new transition" \
  "fixture='$TH_WORKDIR/range-fail'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 Range Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T006: base without gate movement'; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G2/m; s/^    gate: G1$/    gate: G2/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G3' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G3' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Unrelated transition added intentionally for enforcement negative case.' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T006: add unrelated transition'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'without a matching gate transition \(G1 -> G2\)'

th_run_case "EN-007" 1 "methodology-guard --range fails when prior gate-log event records are edited" \
  "fixture='$TH_WORKDIR/range-edit'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 History Edit Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G0 -> G1' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G0' \
    'to_gate: G1' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/project.yaml' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Historical event fixture' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T007: base with gate history'; \
  perl -0pi -e 's/(## Gate Event: G0 -> G1.*?decided_by: )Methodology Test/\\1Other Test/s' docs/project/approvals/gate-log.md; \
  git add -f docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T007: edit historical gate event'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'prior log content was edited or inserted before append position'

th_run_case "EN-008" 1 "methodology-guard --range fails when prior gate-log event records are removed" \
  "fixture='$TH_WORKDIR/range-delete'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 History Delete Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G0 -> G1' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G0' \
    'to_gate: G1' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/project.yaml' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Historical event fixture' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T007: base with gate history'; \
  tmp_log_file=gate-log.tmp; \
  perl -0pi -e 's/\\n## Gate Event: G0 -> G1\\n\\n\\x60\\x60\\x60yaml\\n.*?\\n\\x60\\x60\\x60\\n//s' docs/project/approvals/gate-log.md; \
  git add -f docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T007: remove historical gate event'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'existing historical entries were deleted'

th_run_case "EN-009" 0 "methodology-guard --range accepts declared non-adjacent C1/C2 combined transition with required combined event fields" \
  "fixture='$TH_WORKDIR/range-combined-pass'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 Range Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T008: base without gate movement'; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G3/m; s/^    gate: G1$/    gate: G3/m' docs/project/project.yaml; \
  perl -0pi -e 's/^([[:space:]]*combined_gates:)\s*\[[^\]]*\]/\1\n    - gates: G1-G3\n      mode: c2\n      justification: Combined transition required for synchronized phase closure.\n      approver: Methodology Test\n      approved_on: 2026-07-10/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G3' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G3' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'combined_gates: G1-G3' \
    'combined_gate_justification: Combined milestone movement requires both checkpoints.' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Combined transition fixture' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T008: add declared combined transition'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'Methodology check passed:'

th_run_case "EN-010" 1 "methodology-guard --range rejects non-adjacent transition lacking combined_gates declaration" \
  "fixture='$TH_WORKDIR/range-combined-decl-fail'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 Range Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T008: base without gate movement'; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G3/m; s/^    gate: G1$/    gate: G3/m' docs/project/project.yaml; \
  perl -0pi -e 's/^([[:space:]]*combined_gates:)\s*\[[^\]]*\]/\1 []/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G3' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G3' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Combined transition without declaration fixture' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T008: add undeclared combined transition'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'without a matching manifest scaling.combined_gates declaration for span G1-G3'

th_run_case "EN-013" 0 "methodology-guard --range ignores unstaged drift from the working tree" \
  "fixture='$TH_WORKDIR/range-leak'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 Range Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T006: base without gate movement'; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G2/m; s/^    gate: G1$/    gate: G2/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G2' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G2' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Range snapshot must read HEAD tree' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T009: add exact transition at head'; \
  perl -0pi -e 's/^  current_gate: G2$/  current_gate: G1/m; s/^    gate: G2$/    gate: G1/m' docs/project/project.yaml; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'Methodology check passed:'

th_run_case "EN-011" 1 "methodology-guard --range rejects combined movement declared for C3 projects" \
  "fixture='$TH_WORKDIR/range-combined-c3-fail'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 Range Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T008: base without gate movement'; \
  perl -0pi -e 's/^  blast_radius_class: C2$/  blast_radius_class: C3/m' docs/project/project.yaml; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G3/m; s/^    gate: G1$/    gate: G3/m' docs/project/project.yaml; \
  perl -0pi -e 's/^([[:space:]]*combined_gates:)\s*\[[^\]]*\]/\1\n    - gates: G1-G3\n      mode: c2\n      justification: C3 projects should fail this path.\n      approver: Methodology Test\n      approved_on: 2026-07-10/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G3' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G3' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'combined_gates: G1-G3' \
    'combined_gate_justification: Combined transition with C3 class.' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: C3 combined transition fixture' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T008: add C3 combined transition'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'blast_radius_class C3 does not allow combined transitions'

th_run_case "EN-012" 1 "methodology-guard --range rejects combined movement when combined transition event fields are missing" \
  "fixture='$TH_WORKDIR/range-combined-event-fail'; \
  rm -rf "\$fixture"; \
  cp -R '$base_repo/.' "\$fixture"; \
  cd "\$fixture"; \
  git config user.name 'Methodology Test' >/dev/null; \
  git config user.email 'methodology-test@example.com' >/dev/null; \
  ./scripts/init-project.sh --force 'WP05 Range Base' >/dev/null; \
  mkdir -p src; \
  perl -0pi -e 's/  implementation_paths:\n    - TBD/  implementation_paths:\n    - src/m; s/^    required_attester: TBD/    required_attester: Methodology Test/m' docs/project/project.yaml; \
  git add -A >/dev/null; git add -f docs/project >/dev/null 2>&1 || true; \
  git commit --allow-empty -qm 'WP05-T008: base without gate movement'; \
  perl -0pi -e 's/^  current_gate: G1$/  current_gate: G3/m; s/^    gate: G1$/    gate: G3/m' docs/project/project.yaml; \
  perl -0pi -e 's/^([[:space:]]*combined_gates:)\s*\[[^\]]*\]/\1\n    - gates: G1-G3\n      mode: c2\n      justification: Combined transition requires event fields.\n      approver: Methodology Test\n      approved_on: 2026-07-10/m' docs/project/project.yaml; \
  printf '%s\n' \
    '' \
    '## Gate Event: G1 -> G3' \
    '' \
    '\`\`\`yaml' \
    'event_id: EVT-HIST-001' \
    'schema_version: 2' \
    'event_type: gate_transition' \
    'from_gate: G1' \
    'to_gate: G3' \
    'decision: approved' \
    'decided_by: Methodology Test' \
    'status: approved' \
    'evidence:' \
    '  - path: docs/project/vision/vision.md' \
    '    revision: TBD' \
    '    status: Accepted' \
    'checked: Combined transition with missing combined fields' \
    '\`\`\`' \
    >> docs/project/approvals/gate-log.md; \
  git add -f docs/project/project.yaml docs/project/approvals/gate-log.md >/dev/null; \
  git commit --allow-empty -qm 'WP05-T008: add incomplete combined transition event'; \
  ./scripts/methodology-guard.sh --range HEAD~1 HEAD" \
  'without a matching gate transition \(G1 -> G3\) with combined_gates: G1-G3'

th_summary

exit $(( TH_CASE_FAIL > 0 ))
