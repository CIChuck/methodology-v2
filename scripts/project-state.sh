#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-common.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/project-state.sh

Prints the initialized project's current gate, next artifact, and approval
state for human-agent handoff.
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

if [ ! -f "$manifest" ]; then
  printf '%s\n' 'Project state unavailable: docs/project/project.yaml is missing.' >&2
  printf '%s\n' 'Run: ./scripts/init-project.sh "Project Name"' >&2
  exit 1
fi

project_name="$(gendev_manifest_section_value "$manifest" project name)"
project_slug="$(gendev_manifest_section_value "$manifest" project slug)"
project_status="$(gendev_manifest_section_value "$manifest" project status)"
methodology_version="$(gendev_manifest_section_value "$manifest" project methodology_version)"
current_gate="$(gendev_manifest_nested_value "$manifest" approvals current_gate gate)"
gate_status="$(gendev_manifest_nested_value "$manifest" approvals current_gate status)"
required_approver="$(gendev_manifest_nested_value "$manifest" approvals current_gate required_approver)"
next_gate="$(gendev_manifest_nested_value "$manifest" approvals current_gate next_gate)"
next_role="$(gendev_manifest_nested_value "$manifest" approvals current_gate next_role)"
next_artifact="$(gendev_manifest_nested_value "$manifest" approvals current_gate next_artifact)"

printf 'Project: %s\n' "${project_name:-unknown}"
printf 'Slug: %s\n' "${project_slug:-unknown}"
printf 'Status: %s\n' "${project_status:-unknown}"
printf 'Methodology version: %s\n' "${methodology_version:-unknown}"
printf 'Current gate: %s\n' "${current_gate:-unknown}"
printf 'Current gate status: %s\n' "${gate_status:-unknown}"
printf 'Required approver: %s\n' "${required_approver:-unknown}"
printf 'Next gate: %s\n' "${next_gate:-unknown}"
printf 'Next role: %s\n' "${next_role:-unknown}"
printf 'Next artifact: %s\n' "${next_artifact:-unknown}"
printf 'Validation: ./scripts/check-methodology.sh\n'
