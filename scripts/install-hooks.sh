#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

set -eu

usage() {
  cat <<'USAGE'
Usage:
  scripts/install-hooks.sh [--uninstall] [--force]

Installs an idempotent GenDev pre-commit wrapper at the active Git hook path.
The wrapper runs a preserved pre-existing hook first, then runs
scripts/methodology-guard.sh --staged.

Options:
  --uninstall   Restore the preserved hook, or remove the GenDev wrapper if no hook was preserved.
  --force       Replace ambiguous GenDev backup state.
  -h, --help    Show this help.
USAGE
}

uninstall=0
force=0
while [ "$#" -gt 0 ]; do
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --uninstall) uninstall=1; shift ;;
    --force) force=1; shift ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *) break ;;
  esac
done
[ "$#" -eq 0 ] || { usage >&2; exit 2; }

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [ ! -x scripts/methodology-guard.sh ]; then
  echo "Required executable missing: scripts/methodology-guard.sh" >&2
  exit 1
fi

hook_path="$(git rev-parse --git-path hooks/pre-commit)"
case "$hook_path" in
  /*) ;;
  *) hook_path="$repo_root/$hook_path" ;;
esac
hook_dir="$(dirname "$hook_path")"
mkdir -p "$hook_dir"
backup_path="$hook_dir/pre-commit.gendev-preserved"
mode_path="$hook_dir/pre-commit.gendev-mode"
marker='GENDEV PRE-COMMIT WRAPPER'

file_mode() {
  if mode="$(stat -f '%Lp' "$1" 2>/dev/null)"; then
    printf '%s\n' "$mode"
  else
    stat -c '%a' "$1"
  fi
}

is_gendev_wrapper() {
  [ -f "$1" ] && grep -q "$marker" "$1"
}

restore_mode() {
  file="$1"
  mode_file="$2"
  if [ -f "$mode_file" ]; then
    mode="$(cat "$mode_file")"
    chmod "$mode" "$file" 2>/dev/null || chmod +x "$file"
  fi
}

if [ "$uninstall" -eq 1 ]; then
  if [ -f "$backup_path" ]; then
    cp "$backup_path" "$hook_path"
    restore_mode "$hook_path" "$mode_path"
    rm -f "$backup_path" "$mode_path"
    echo "Restored preserved pre-commit hook: $hook_path"
    exit 0
  fi
  if is_gendev_wrapper "$hook_path"; then
    rm -f "$hook_path"
    echo "Removed GenDev pre-commit hook: $hook_path"
    exit 0
  fi
  echo "No GenDev hook installation found at: $hook_path" >&2
  exit 1
fi

if [ -f "$backup_path" ] && ! is_gendev_wrapper "$hook_path" ] && [ "$force" -ne 1 ]; then
  echo "Ambiguous hook backup state at $hook_dir; use --force only after manual recovery." >&2
  exit 1
fi

if is_gendev_wrapper "$hook_path"; then
  echo "GenDev pre-commit hook already installed: $hook_path"
  exit 0
fi

if [ -e "$hook_path" ]; then
  if [ -e "$backup_path" ] && [ "$force" -ne 1 ]; then
    echo "Preserved hook backup already exists: $backup_path" >&2
    exit 1
  fi
  cp "$hook_path" "$backup_path"
  file_mode "$hook_path" > "$mode_path"
fi

cat > "$hook_path" <<'HOOK'
#!/usr/bin/env bash
# GENDEV PRE-COMMIT WRAPPER
set -eu

repo_root="$(git rev-parse --show-toplevel)"
hook_path="$(git rev-parse --git-path hooks/pre-commit)"
case "$hook_path" in
  /*) ;;
  *) hook_path="$repo_root/$hook_path" ;;
esac
hook_dir="$(dirname "$hook_path")"
preserved="$hook_dir/pre-commit.gendev-preserved"

if [ -x "$preserved" ]; then
  "$preserved"
fi

cd "$repo_root"
exec scripts/methodology-guard.sh --staged
HOOK

chmod +x "$hook_path"
echo "Installed GenDev pre-commit hook: $hook_path"
