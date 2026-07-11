#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -u

script_dir="$(cd "$(dirname "$0")" && pwd)"
. "$script_dir/lib/gendev-common.sh"

usage() {
  cat <<'USAGE'
Usage:
  scripts/new-artifact.sh --kind KIND

Creates a canonical late-lifecycle project artifact from its methodology
template. The command refuses to overwrite existing artifacts.

Kinds:
  implementation-summary
  final-code-review
  aggregate-remediation
  final-test-uat
  deployment-readiness
  production-runbook
  deployment-record
  project-value-review
  project-as-built
USAGE
}

kind=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    --kind)
      if [ "$#" -lt 2 ]; then
        usage >&2
        exit 2
      fi
      kind="$2"
      shift 2
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$kind" ]; then
  usage >&2
  exit 2
fi

repo_root="$(cd "$script_dir/.." && pwd)"
manifest="$repo_root/docs/project/project.yaml"
template_root="$repo_root/docs/methodology/templates"

if [ ! -f "$manifest" ]; then
  printf '%s\n' 'docs/project/project.yaml is missing. Initialize the project first.' >&2
  exit 1
fi

case "$kind" in
  implementation-summary)
    template="$template_root/implementation-summary-template.md"
    dest="$repo_root/docs/project/build-plan/implementation-summary.md"
    ;;
  final-code-review)
    template="$template_root/final-code-review-report-template.md"
    dest="$repo_root/docs/project/review/code-review.md"
    ;;
  aggregate-remediation)
    template="$template_root/aggregate-remediation-template.md"
    dest="$repo_root/docs/project/review/remediation.md"
    ;;
  final-test-uat)
    template="$template_root/final-test-uat-report-template.md"
    dest="$repo_root/docs/project/testing/final-test-uat-report.md"
    ;;
  deployment-readiness)
    template="$template_root/deployment-readiness-template.md"
    dest="$repo_root/docs/project/deployment/deployment-readiness.md"
    ;;
  production-runbook)
    template="$template_root/production-runbook-template.md"
    dest="$repo_root/docs/project/deployment/production-runbook.md"
    ;;
  deployment-record)
    template="$template_root/deployment-record-template.md"
    dest="$repo_root/docs/project/deployment/deployment-record.md"
    ;;
  project-value-review)
    template="$template_root/project-value-review-template.md"
    dest="$repo_root/docs/project/as-built/value-review.md"
    ;;
  project-as-built)
    template="$template_root/project-as-built-closeout-template.md"
    dest="$repo_root/docs/project/as-built/as-built-closeout.md"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if [ -e "$dest" ]; then
  printf 'Artifact already exists: %s\n' "${dest#$repo_root/}" >&2
  exit 1
fi

project_name="$(gendev_manifest_section_value "$manifest" project name)"
project_slug="$(gendev_manifest_section_value "$manifest" project slug)"
today="$(gendev_utc_date)"

mkdir -p "$(dirname "$dest")"
project_name_sed="$(printf '%s' "${project_name:-TBD}" | sed 's/[\/&]/\\&/g')"
project_slug_sed="$(printf '%s' "${project_slug:-TBD}" | sed 's/[\/&]/\\&/g')"
today_sed="$(printf '%s' "$today" | sed 's/[\/&]/\\&/g')"

sed \
  -e "s/\[Project Name\]/$project_name_sed/g" \
  -e "s/\[project-slug\]/$project_slug_sed/g" \
  -e "s/\[YYYY-MM-DD\]/$today_sed/g" \
  -e "s/^Date:$/Date: $today_sed/g" \
  -e "s/^Owner:$/Owner: TBD/g" \
  "$template" > "$dest"

printf 'Created %s\n' "${dest#$repo_root/}"
