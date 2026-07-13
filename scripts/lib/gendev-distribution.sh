#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

# Shared distribution helpers for methodology install/backfill commands.

GENDEV_DISTRIBUTION_REPORT_INSTALLED=""
GENDEV_DISTRIBUTION_REPORT_UPGRADED=""
GENDEV_DISTRIBUTION_REPORT_PRESERVED=""
GENDEV_DISTRIBUTION_REPORT_SKIPPED=""
GENDEV_DISTRIBUTION_REPORT_BLOCKED=""
GENDEV_DISTRIBUTION_REPORT_BACKUPS=""
GENDEV_DISTRIBUTION_WRITE_COUNT=0

_gendev_dist_add_report() {
  bucket="$1"
  value="$2"
  case "$bucket" in
    installed) GENDEV_DISTRIBUTION_REPORT_INSTALLED="${GENDEV_DISTRIBUTION_REPORT_INSTALLED}${value}
" ;;
    upgraded) GENDEV_DISTRIBUTION_REPORT_UPGRADED="${GENDEV_DISTRIBUTION_REPORT_UPGRADED}${value}
" ;;
    preserved) GENDEV_DISTRIBUTION_REPORT_PRESERVED="${GENDEV_DISTRIBUTION_REPORT_PRESERVED}${value}
" ;;
    skipped) GENDEV_DISTRIBUTION_REPORT_SKIPPED="${GENDEV_DISTRIBUTION_REPORT_SKIPPED}${value}
" ;;
    blocked) GENDEV_DISTRIBUTION_REPORT_BLOCKED="${GENDEV_DISTRIBUTION_REPORT_BLOCKED}${value}
" ;;
  esac
}

gendev_dist_manifest() {
  repo_root="$1"
  printf '%s\n' "$repo_root/scripts/lib/distribution-manifest.txt"
}

gendev_dist_require_repo_root() {
  repo_root="$1"
  if [ ! -f "$repo_root/docs/methodology/constitution/gendev.md" ]; then
    printf 'This does not look like the methodology repo (missing docs/methodology/constitution/gendev.md).\n' >&2
    return 1
  fi
  if [ ! -f "$(gendev_dist_manifest "$repo_root")" ]; then
    printf 'Distribution manifest missing: %s\n' "$(gendev_dist_manifest "$repo_root")" >&2
    return 1
  fi
}

gendev_dist_target_abs() {
  target="$1"
  [ -d "$target" ] || return 1
  (cd "$target" && pwd)
}

gendev_dist_detect_branch() {
  target_repo="$1"
  requested="$2"
  if [ -n "$requested" ]; then
    printf '%s\n' "$requested"
    return 0
  fi
  branch="$(git -C "$target_repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  if [ -n "$branch" ]; then
    printf '%s\n' "$branch"
    return 0
  fi
  printf 'main\n'
}

gendev_dist_validate_manifest_sources() {
  repo_root="$1"
  include_resources="$2"
  manifest="$(gendev_dist_manifest "$repo_root")"

  while IFS='|' read -r kind source target mode class; do
    case "$kind" in ''|'#'*) continue ;; esac
    [ "$class" = "optional_resources" ] && [ "$include_resources" -ne 1 ] && continue
    if [ ! -e "$repo_root/$source" ]; then
      printf 'Distribution source missing: %s\n' "$source" >&2
      return 1
    fi
  done < "$manifest"
}

gendev_dist_preflight_target() {
  repo_root="$1"
  target_repo="$2"
  include_resources="$3"
  force="$4"
  integrate_agents="$5"
  manifest="$(gendev_dist_manifest "$repo_root")"
  blocked=0

  while IFS='|' read -r kind source target mode class; do
    case "$kind" in ''|'#'*) continue ;; esac
    [ "$class" = "optional_resources" ] && [ "$include_resources" -ne 1 ] && continue

    dest="$target_repo/$target"
    case "$class" in
      agents)
        if [ -e "$dest" ]; then
          if [ "$integrate_agents" -eq 1 ]; then
            _gendev_dist_add_report preserved "$target (existing AGENTS.md will receive managed GenDev include block)"
          else
            _gendev_dist_add_report preserved "$target (target-owned; no integration requested)"
          fi
          continue
        fi
        ;;
      *)
        if [ -e "$dest" ] && [ "$force" -ne 1 ]; then
          _gendev_dist_add_report blocked "$target (exists; use --force only for GenDev-owned paths)"
          blocked=1
        fi
        ;;
    esac
  done < "$manifest"

  return "$blocked"
}

gendev_dist_backup_path() {
  tmp_dir="$1"
  target="$2"
  printf '%s/%s.bak\n' "$tmp_dir" "$(printf '%s' "$target" | sed 's#[/.]#_#g')"
}

gendev_dist_backup_existing() {
  tmp_dir="$1"
  dest="$2"
  rel="$3"
  if [ -e "$dest" ]; then
    backup="$(gendev_dist_backup_path "$tmp_dir" "$rel")"
    mkdir -p "$(dirname "$backup")"
    cp -R "$dest" "$backup"
    GENDEV_DISTRIBUTION_REPORT_BACKUPS="${GENDEV_DISTRIBUTION_REPORT_BACKUPS}${dest}|${backup}
"
  fi
}

gendev_dist_rollback() {
  if [ -n "$GENDEV_DISTRIBUTION_REPORT_BACKUPS" ]; then
    printf '%s' "$GENDEV_DISTRIBUTION_REPORT_BACKUPS" | while IFS='|' read -r dest backup; do
      [ -n "$dest" ] || continue
      rm -rf "$dest"
      if [ -e "$backup" ]; then
        cp -R "$backup" "$dest"
      fi
    done
  fi
}

gendev_dist_copy_entry() {
  repo_root="$1"
  target_repo="$2"
  tmp_dir="$3"
  kind="$4"
  source="$5"
  target="$6"
  mode="$7"
  branch="$8"

  src="$repo_root/$source"
  dest="$target_repo/$target"
  parent="$(dirname "$dest")"
  mkdir -p "$parent"
  gendev_dist_backup_existing "$tmp_dir" "$dest" "$target"

  if [ "$kind" = "tree" ]; then
    rm -rf "$dest"
    cp -R "$src" "$dest"
  else
    if [ "$target" = ".github/workflows/methodology.yml" ]; then
      sed "s/^      - master$/      - ${branch}/" "$src" > "$dest"
    else
      cp "$src" "$dest"
    fi
    if [ "$mode" = "executable" ]; then
      chmod +x "$dest"
    fi
  fi

  GENDEV_DISTRIBUTION_WRITE_COUNT=$((GENDEV_DISTRIBUTION_WRITE_COUNT + 1))
  if [ -n "${GENDEV_INSTALL_FAIL_AFTER:-}" ] && [ "$GENDEV_DISTRIBUTION_WRITE_COUNT" -ge "$GENDEV_INSTALL_FAIL_AFTER" ]; then
    printf 'Simulated install failure after %s writes.\n' "$GENDEV_DISTRIBUTION_WRITE_COUNT" >&2
    return 1
  fi
}

gendev_dist_integrate_agents() {
  repo_root="$1"
  target_repo="$2"
  dry_run="$3"
  agents="$target_repo/AGENTS.md"
  include="$target_repo/AGENTS.gendev.md"
  marker_begin="# BEGIN MANAGED GENDEV INSTRUCTIONS"
  marker_end="# END MANAGED GENDEV INSTRUCTIONS"

  [ -f "$agents" ] || return 0
  if grep -q "$marker_begin" "$agents"; then
    _gendev_dist_add_report preserved "AGENTS.md (managed GenDev block already present)"
    return 0
  fi
  if [ "$dry_run" -eq 1 ]; then
    _gendev_dist_add_report skipped "AGENTS.md managed integration (dry-run)"
    return 0
  fi

  cp "$repo_root/AGENTS.md" "$include"
  {
    printf '\n%s\n' "$marker_begin"
    printf 'GenDev methodology instructions are available in AGENTS.gendev.md. Preserve local instructions above unless explicitly amended.\n'
    printf '%s\n' "$marker_end"
  } >> "$agents"
  _gendev_dist_add_report upgraded "AGENTS.md (managed GenDev include block added)"
}


gendev_dist_write_installation_record() {
  repo_root="$1"
  target_repo="$2"
  include_resources="$3"
  installer_options="$4"

  version="unknown"
  if [ -f "$repo_root/scripts/lib/lifecycle-contract.sh" ]; then
    version="$(GENDEV_LIFECYCLE_TARGET_VERSION='' bash -c ". '$repo_root/scripts/lib/lifecycle-contract.sh' >/dev/null 2>&1; printf %s \"\$GENDEV_LIFECYCLE_TARGET_VERSION\"")"
  fi
  source_commit="$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || printf unknown)"
  source_tag="$(git -C "$repo_root" describe --tags --exact-match 2>/dev/null || printf none)"
  source_remote="$(git -C "$repo_root" remote get-url origin 2>/dev/null || printf "$repo_root")"

  GENDEV_INSTALL_VERSION="$version" \
  GENDEV_INSTALL_COMMIT="$source_commit" \
  GENDEV_INSTALL_TAG="$source_tag" \
  GENDEV_INSTALL_REMOTE="$source_remote" \
  GENDEV_INSTALL_OPTS="$installer_options" \
  GENDEV_INSTALL_RESOURCES="$include_resources" \
  python3 - "$repo_root" "$target_repo" <<'PYREC'
import hashlib, json, os, sys, datetime

repo_root, target_repo = sys.argv[1], sys.argv[2]
manifest = os.path.join(repo_root, "scripts", "lib", "distribution-manifest.txt")
include_resources = os.environ["GENDEV_INSTALL_RESOURCES"] == "1"

files = {}
def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

with open(manifest) as m:
    for line in m:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        kind, source, target, mode, klass = line.split("|")
        if klass == "optional_resources" and not include_resources:
            continue
        dest = os.path.join(target_repo, target)
        if not os.path.exists(dest):
            continue
        if kind == "tree":
            for root, _dirs, names in os.walk(dest):
                for name in names:
                    full = os.path.join(root, name)
                    rel = os.path.relpath(full, target_repo)
                    files[rel] = digest(full)
        else:
            files[target] = digest(dest)

record = {
    "record": "gendev-installation",
    "schema": 1,
    "methodology_version": os.environ["GENDEV_INSTALL_VERSION"],
    "source_remote": os.environ["GENDEV_INSTALL_REMOTE"],
    "source_tag": os.environ["GENDEV_INSTALL_TAG"],
    "source_commit": os.environ["GENDEV_INSTALL_COMMIT"],
    "installed_on": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "installer_options": os.environ["GENDEV_INSTALL_OPTS"],
    "files": dict(sorted(files.items())),
}
out = os.path.join(target_repo, "docs", "methodology", "schema", "installation.json")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:
    json.dump(record, f, indent=2)
    f.write("\n")
PYREC
  _gendev_dist_add_report installed "docs/methodology/schema/installation.json (installation record)"
}

gendev_dist_install() {
  repo_root="$1"
  target_repo="$2"
  force="$3"
  include_resources="$4"
  dry_run="$5"
  integrate_agents="$6"
  protected_branch="$7"

  gendev_dist_require_repo_root "$repo_root" || return 1
  gendev_dist_validate_manifest_sources "$repo_root" "$include_resources" || return 1
  branch="$(gendev_dist_detect_branch "$target_repo" "$protected_branch")"

  if ! gendev_dist_preflight_target "$repo_root" "$target_repo" "$include_resources" "$force" "$integrate_agents"; then
    return 1
  fi

  if [ "$dry_run" -eq 1 ]; then
    _gendev_dist_add_report skipped "all writes (dry-run)"
    return 0
  fi

  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gendev-install.XXXXXX")"
  trap 'gendev_dist_rollback; rm -rf "$tmp_dir"' INT TERM HUP

  manifest="$(gendev_dist_manifest "$repo_root")"
  while IFS='|' read -r kind source target mode class; do
    case "$kind" in ''|'#'*) continue ;; esac
    [ "$class" = "optional_resources" ] && [ "$include_resources" -ne 1 ] && { _gendev_dist_add_report skipped "$target (optional resources not requested)"; continue; }
    if [ "$class" = "agents" ] && [ -e "$target_repo/$target" ]; then
      [ "$integrate_agents" -eq 1 ] && gendev_dist_integrate_agents "$repo_root" "$target_repo" "$dry_run"
      continue
    fi
    existed=0
    [ -e "$target_repo/$target" ] && existed=1
    if ! gendev_dist_copy_entry "$repo_root" "$target_repo" "$tmp_dir" "$kind" "$source" "$target" "$mode" "$branch"; then
      gendev_dist_rollback
      rm -rf "$tmp_dir"
      return 1
    fi
    if [ "$existed" -eq 1 ]; then
      _gendev_dist_add_report upgraded "$target"
    else
      _gendev_dist_add_report installed "$target"
    fi
  done < "$manifest"

  gendev_dist_write_installation_record "$repo_root" "$target_repo" "$include_resources" "force=$force resources=$include_resources agents=$integrate_agents branch=$branch"

  if [ ! -f "$target_repo/.gitignore" ] || ! grep -q '^\.tmp/$' "$target_repo/.gitignore"; then
    printf '.tmp/\n' >> "$target_repo/.gitignore"
    _gendev_dist_add_report installed ".gitignore (.tmp/ suite scratch rule appended)"
  fi

  trap - INT TERM HUP
  rm -rf "$tmp_dir"
}

gendev_dist_print_report() {
  printf 'Distribution report:\n'
  for label in installed upgraded preserved skipped blocked; do
    case "$label" in
      installed) items="$GENDEV_DISTRIBUTION_REPORT_INSTALLED" ;;
      upgraded) items="$GENDEV_DISTRIBUTION_REPORT_UPGRADED" ;;
      preserved) items="$GENDEV_DISTRIBUTION_REPORT_PRESERVED" ;;
      skipped) items="$GENDEV_DISTRIBUTION_REPORT_SKIPPED" ;;
      blocked) items="$GENDEV_DISTRIBUTION_REPORT_BLOCKED" ;;
    esac
    if [ -n "$items" ]; then
      printf '%s:\n' "$label"
      printf '%s' "$items" | sed '/^$/d; s/^/  - /'
    fi
  done
}
