#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-common.sh"
. "$script_dir/lib/lifecycle-contract.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/gendev-doctor.sh

Reports repository-level GenDev health for an agent or practitioner before
starting methodology work.
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -ne 0 ]; then
  usage >&2
  exit 2
fi

repo_root="$(cd "$script_dir/.." && pwd)"
manifest="$repo_root/docs/project/project.yaml"
gate_log="$repo_root/docs/project/approvals/gate-log.md"

printf 'GenDev doctor\n'
printf 'Repository: %s\n' "$repo_root"

prereq_missing=0
gendev_report_prereqs || prereq_missing=$?

integrity_failed=0
if gendev_is_installed_context "$repo_root"; then
  printf 'Context: installed\n'
  record="$(gendev_installation_record_path "$repo_root")"
  python3 - "$repo_root" "$record" <<'PYINT' || integrity_failed=1
import hashlib, json, os, sys
root, record_path = sys.argv[1], sys.argv[2]
rec = json.load(open(record_path))
print(f"Installed methodology version: {rec.get('methodology_version','unknown')}")
print(f"Installed from: {rec.get('source_remote','unknown')} (tag {rec.get('source_tag','unknown')}, commit {str(rec.get('source_commit','unknown'))[:12]})")
print(f"Installed on: {rec.get('installed_on','unknown')}")
bad = []
for rel, want in rec.get('files', {}).items():
    full = os.path.join(root, rel)
    if not os.path.exists(full):
        bad.append((rel, 'missing'))
        continue
    h = hashlib.sha256()
    with open(full, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    if h.hexdigest() != want:
        bad.append((rel, 'modified'))
if bad:
    print(f"Integrity: FAILED ({len(bad)} file(s))")
    for rel, why in bad[:20]:
        print(f"  {why}: {rel}")
    raise SystemExit(1)
print(f"Integrity: verified ({len(rec.get('files', {}))} files)")
PYINT
else
  printf 'Context: authority\n'
fi
printf 'Lifecycle target: %s\n' "$GENDEV_LIFECYCLE_TARGET_VERSION"
printf 'Lifecycle status: %s\n' "$GENDEV_LIFECYCLE_REGISTRY_STATUS"

if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  head_rev="$(git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)"
  branch="$(git -C "$repo_root" branch --show-current 2>/dev/null || printf unknown)"
  tags="$(git -C "$repo_root" tag --points-at HEAD 2>/dev/null | tr '\n' ' ')"
  printf 'Git branch: %s\n' "${branch:-detached}"
  printf 'Git HEAD: %s\n' "$head_rev"
  printf 'Tags at HEAD: %s\n' "${tags:-none}"
else
  printf 'Git branch: unavailable\n'
  printf 'Git HEAD: unavailable\n'
  printf 'Tags at HEAD: unavailable\n'
fi

if [ -f "$manifest" ]; then
  project_name="$(gendev_manifest_section_value "$manifest" project name)"
  project_slug="$(gendev_manifest_section_value "$manifest" project slug)"
  project_version="$(gendev_manifest_section_value "$manifest" project methodology_version)"
  current_gate="$(gendev_manifest_nested_value "$manifest" approvals current_gate gate)"
  gate_status="$(gendev_manifest_nested_value "$manifest" approvals current_gate status)"
  next_artifact="$(gendev_manifest_nested_value "$manifest" approvals current_gate next_artifact)"
  printf 'Project initialized: yes\n'
  printf 'Project name: %s\n' "${project_name:-unknown}"
  printf 'Project slug: %s\n' "${project_slug:-unknown}"
  printf 'Project methodology version: %s\n' "${project_version:-unknown}"
  printf 'Current gate: %s\n' "${current_gate:-unknown}"
  printf 'Current gate status: %s\n' "${gate_status:-unknown}"
  printf 'Next artifact: %s\n' "${next_artifact:-unknown}"
else
  printf 'Project initialized: no\n'
  printf 'Next action: ./scripts/init-project.sh "Project Name"\n'
fi

if [ -f "$gate_log" ]; then
  printf 'Gate log: present\n'
else
  printf 'Gate log: missing\n'
fi

printf 'Recommended validation: ./scripts/check-methodology.sh\n'

if [ "$integrity_failed" -gt 0 ]; then
  printf 'Doctor result: installed file integrity check failed; see list above.\n' >&2
fi
if [ "$prereq_missing" -gt 0 ]; then
  printf 'Doctor result: %s missing prerequisite(s); install before methodology work.\n' "$prereq_missing" >&2
  exit 3
fi
if [ "$integrity_failed" -gt 0 ]; then
  exit 5
fi
